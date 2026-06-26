import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:silvanus/types/series_request.dart';
import 'package:silvanus/types/time_stamped_value.dart';
import 'package:silvanus/data_sources/data_engine.dart';


class Line extends StatefulWidget {
  final SeriesGroupRequest seriesToShow;

  final DataEngine engine;

  // Map of keys to series
  final Map<String, Series> seriesMap = {};

  // Constructor
  Line({super.key, required this.seriesToShow, required this.engine});

 

  @override
  State<Line> createState() => _LineState();
  
}

class _LineState extends State<Line> {
  // Range of displayed values
  double minTimeToShow = 0;
  double maxTimeToShow = 0;

  // Controls the range of displayed values
  late final ZoomManager zoomManager;

  // Update the range of displayed values, should only be called by the zoom manager
  void setTimeToShow(({double newMin, double newMax}) newTime) {
    setState(() {
      minTimeToShow = newTime.newMin;
      maxTimeToShow = newTime.newMax;
    });
  }

  @override
  initState() {
    super.initState();
    zoomManager = ZoomManager(setTimeToShow);
    for (final seriesRequest in widget.seriesToShow.getAllRequests()) {
      _subscribeToSeries(seriesRequest);

    }

  }
  

  // Carry the series over from the old widget and fix any changes
  @override
  void didUpdateWidget(covariant Line oldWidget) {
    
    super.didUpdateWidget(oldWidget);
    widget.seriesMap.addEntries(oldWidget.seriesMap.entries);


    // If key currently in the set and shouldnt be remove it
    for (final key in widget.seriesMap.keys.toList()) {
      if (widget.seriesToShow.containsKey(key) == false) {
        widget.seriesMap[key]?.destroy();
        widget.seriesMap.remove(key);
      }
    }

    // If the key isn't in the set and should be add it
    for (final request in widget.seriesToShow.getAllRequests())   {
      if (widget.seriesMap.containsKey(request.getKey()) == false) {
        _subscribeToSeries(request);
      }
    }
  }

  // Subscripe to series
  void _subscribeToSeries(SeriesRequest seriesRequested) {
    // Points to plot
    List<TimeStampedDouble> startingData = widget.engine.getSeries(seriesRequested.name);
    List<FlSpot> newSpots = startingData.map((p) => FlSpot(p.timestamp, p.value)).toList();

    widget.seriesMap[seriesRequested.getKey()]?.setSpots(newSpots);
    zoomManager.addTimeMeasurement(startingData);
    

    
    // Subscription to stream
    final sub = widget.engine.dataStream.listen((newData) {
        // when new points are available
        setState(() {
          // Update the graph with the new points
          newSpots =  newData[seriesRequested.name]
              ?.map((p) => FlSpot(p.timestamp, p.value))
              .toList() ?? [];
          widget.seriesMap[seriesRequested.getKey()]?.setSpots(newSpots);
        });

        // Add the new time options into the zoom manager
        zoomManager.addTimeMeasurement(newData[seriesRequested.name] ?? []);


      });
    
    // Record the new series
    Series newSeries = Series(sub, newSpots, seriesRequested);
    widget.seriesMap[seriesRequested.getKey()] = newSeries;

  }

  // Cancel all subscriptions
  @override
  void dispose() {
    
    for (final currentSeries in widget.seriesMap.values) {
      currentSeries.destroy();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listener for mouse scrolling
    return Listener(
      onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            if (event.scrollDelta.dy.abs() > event.scrollDelta.dx.abs()) {
              zoomManager.updateZoom(-event.scrollDelta.dy / 50);

            } else {
              zoomManager.startZoom(event.localPosition.dx, context.size!.width);
              zoomManager.updatePan(-event.scrollDelta.dx / 1000);
            }
          }
        },
      // Gesture Detector for track pad
      child: GestureDetector(
      onVerticalDragStart: (details) => zoomManager.startZoom(details.localPosition.dx, context.size!.width),
      onVerticalDragUpdate: (details) => zoomManager.updateZoom((details.primaryDelta ?? 0) / 50),
      onHorizontalDragUpdate: (details) => zoomManager.updatePan((details.primaryDelta ?? 0) / 50),

      child:  LineChart(
      LineChartData(
        minX: minTimeToShow,
        maxX: maxTimeToShow,
        clipData: FlClipData.horizontal(), // Don't show data outside the chart bounds

        // Add the data to display
        lineBarsData: [
          for (final currentSeries in widget.seriesMap.values)
            LineChartBarData(
              spots: currentSeries.getSpots(),
              isCurved: false,
              color: currentSeries.getRequest().getColor(),
              barWidth: 2,
              dotData: FlDotData(show: false),
            ),
        ],
      ),
    )));
  }
}

// Object to hold everything about a series
class Series {
  // Subscription to get new points
  final StreamSubscription subscription;

  // Data points
  List<FlSpot> spots;

  // Information from when it was requested to be displayed
  SeriesRequest request;

  Series(this.subscription, this.spots, this.request);

  void setSpots( List<FlSpot> newSpots) {
    spots = newSpots;
  }

  List<FlSpot> getSpots() {
    return spots;
  }

  double getMinTime() {
    return spots.first.x;
  }

  double getMaxTime() {
    return spots.last.x;
  }
  

  void destroy() {
    subscription.cancel();
  }

  SeriesRequest getRequest() {
    return request;
  }
  

}

// Object to manage the range of the chart when scrolling or zooming
class ZoomManager {
  ZoomManager(this.onShowTimeChanged);
  
  // Wether it's tracking the min and max as new data comes in
  bool pinnedToMax = true;
  bool pinnedToMin = true;


  // Range of values currently being shown
  double showTimeMin = 0;
  double showTimeMax = 0;

  // Does any data actually exist?
  bool hasAnyTime = false;

  // Min and max time that there is data for
  double minTime = 0;
  double maxTime = 0;

  // Info for controlling zooming around the right sport
  double focalTime = 0; // The value to be zoomed around
  double t = 0;         // How far through the graph the focal point should be (0 = left axis, 1 = right axis)

  
  final void Function(({double newMin, double newMax})) onShowTimeChanged;


  double getMinTime() {
    return minTime;
  }

  double getMaxTime() {
    return maxTime;
  }

  // Add a set of new time measurements to update total range
  void addTimeMeasurement(List<TimeStampedDouble> newTimes) {
    // For each specific value
    for (TimeStampedValue value in newTimes) {
      // If this is the first value ever it's the min and max
      if (hasAnyTime == false) {
        minTime = value.timestamp;
        maxTime = value.timestamp;
        hasAnyTime = true;
      }

      // If it's a new min value
      else if (value.timestamp < minTime) {
        
        minTime = value.timestamp;
        
      
      // If it's a new max value
      } else if (value.timestamp > maxTime) {
        maxTime = value.timestamp;
      }
    }

    // Update the shown range based on the pinned options

    // Pinned to start and end
    if (pinnedToMax && pinnedToMin) {
      showTimeMax = maxTime;
      showTimeMin = minTime;

    // Pinned to start and not end
    } else if (pinnedToMin) {
      // Create new values based on the min and the expected width
      double width = showTimeMax - showTimeMin;
      showTimeMin = minTime;
      showTimeMax = minTime + width;

      // If the expected width is too wide, limit the max value
      if (showTimeMax > maxTime) {
        showTimeMax = maxTime;
      }
    
    // Pinned to end and not start
    } else if (pinnedToMax) {
      // Create new values based on the max and the expected width
      double width = showTimeMax - showTimeMin;
      showTimeMax = maxTime;
      showTimeMin = maxTime - width;

      // If the expected width is too wide, limit the min value
      if (showTimeMin < minTime) {
        showTimeMin = minTime;
      }
    }

    // Update the time range, since the pins could have caused the range to change
    onShowTimeChanged((newMax: showTimeMax, newMin: showTimeMin));
  }

  // Initialise a zoom
  void startZoom(double localX, double chartWidth) {
    t = localX / chartWidth; // 0 → left, 1 → right
    double width = showTimeMax - showTimeMin;

    focalTime = showTimeMin + width * t;

  }
  
  // Execute a zoom
  void updateZoom(double distance) {
    // Only allowed to make changes if any amount of data actually exists
    if (hasAnyTime) {

      // Calculate how wide the range currently is
      double width = showTimeMax - showTimeMin;

      double scaleFactor = -distance;

      // Adjust the width, exponenting means that negative distance (scrolling down) results in a value between 0 and 1
      double newWidth = width *  pow(2, scaleFactor);

      // Propose a new max value based on the new width and the point that should stay still
      showTimeMax = focalTime + newWidth * t;

      // Calculate the new min value
      showTimeMin = showTimeMax - newWidth;


      // If the max time is too big, should be pinned to max
      if (showTimeMax > maxTime) {
        pinnedToMax = true;
        // Clamp the max value and propose a new min value based on the width
        showTimeMax = maxTime;
        showTimeMin = showTimeMax - newWidth;

        // Check if the new min value is valid, if it is pin the min as well
        if (showTimeMin < minTime) {
          showTimeMin = minTime;
          pinnedToMin = true;
        } else {
          pinnedToMin = false;
        }
      }

      // If the min time is too small, should be pinned to min
      else if (showTimeMin < minTime) {
        pinnedToMin = true;
      
        // Clamp the min value and propose a new max value based on the width
        showTimeMin = minTime;
        showTimeMax = showTimeMin + newWidth;

        // Check if the new min value is valid, if it is pin the min as well
        if (showTimeMax > maxTime) {
          showTimeMax = maxTime;
          pinnedToMax = true;
        } else {
          pinnedToMax = false;
        }

      // If the min and max values are valid then it shouldn't be pinned
      } else {
        pinnedToMax = false;
        pinnedToMin = false;
      }

      // Update that the time that should be shown has changed
      onShowTimeChanged(( newMin: showTimeMin, newMax:  showTimeMax));

      assert(showTimeMin < showTimeMax);
    }
  }

  // Execute a pan
  void updatePan(double distance) {
    // Only allowed to make changes if any amount of data actually exists
    if (hasAnyTime) {

      // Calculate the width that should be maintained
      double width = showTimeMax - showTimeMin;

      // Scale the move based on the current graph width
      double proposedMove = distance * width;

      // Propose new min and max values
      double proposedMin = showTimeMin - proposedMove;
      double proposedMax = showTimeMax - proposedMove;

      // If new max is too big
      if (proposedMax > maxTime) {
        showTimeMax = maxTime;

        // Calculate a new min, assume the old width is still ok
        showTimeMin = maxTime - width;
        pinnedToMax = true;
      
      // If new min is too small
      } else if (proposedMin < minTime) {
        showTimeMin = minTime;

        // Calculate a new max, assume the old width is still ok
        showTimeMax = minTime + width;
        pinnedToMin = true;
      
      // If proposed values are good then use them, but the chart isn't pinned
      } else {
        showTimeMax = proposedMax;
        showTimeMin = proposedMin;
        pinnedToMax = false;
        pinnedToMin = false;
      }

      // Update the shown time
      onShowTimeChanged(( newMin: showTimeMin, newMax:  showTimeMax));
    }
  }  
}


