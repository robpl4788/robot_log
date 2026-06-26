
import 'package:silvanus/data_sources/data_source.dart';
import 'package:silvanus/types/time_stamped_value.dart';
import 'dart:async';
import 'dart:collection';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'dart:core';
import 'dart:convert';

class SerialJsonSource extends DataSource {
  final SerialPort serialPort;

  final StreamController<HashMap<String, List<TimeStampedDouble>>> _newDataStreamController = StreamController<HashMap<String, List<TimeStampedDouble>>>.broadcast();

  Timer? _reconnectTimer;

  bool _disposed = false;


  int startTime = 0;

  @override
  Stream<HashMap<String, List<TimeStampedDouble>>> get newDataStream => _newDataStreamController.stream;

  @override
  void start() {
    // print(serialPort.manufacturer);
    // print(serialPort.description);
    // print(serialPort.productName);
    // print(serialPort.productId);
    // print(serialPort.vendorId);
    // print("ready to read");
    if (!serialPort.openReadWrite()) {
      print(SerialPort.lastError);
      print("Serial port = :(");
    }



    // print("open");
    if (startTime == 0) {
      startTime = DateTime.now().millisecondsSinceEpoch;
    } else {

    }


    final reader = SerialPortReader(serialPort);
    reader.stream.listen((data) {

      final cleanData = data.where((byte) => byte !=  0).toList();

      String jsonString = String.fromCharCodes(cleanData).trim();

      if (jsonString.startsWith("{") && jsonString.endsWith("}")) {

        int timeInt = DateTime.now().millisecondsSinceEpoch - startTime;

        double time = timeInt.toDouble() / 1000.0;

        HashMap<String, List<TimeStampedDouble>> newData = HashMap();

        Map<String, double> stats = parseSeriesStats(jsonString);


        for (MapEntry<String, double> entry in stats.entries) {
          TimeStampedDouble value = TimeStampedValue(entry.value, time);
          (newData[entry.key] ??= []).add(value);
        }

        if (_newDataStreamController.isClosed == false) {
          _newDataStreamController.add(newData);
        }
      } 


      // print(jsonString);
    }, 
    onError: (error) {
    // This intercepts the SerialPortError when the cable is pulled!
    // print('Serial connection lost!');
    serialPort.close();
    _autoReconnect();
  },);
  }

  void _autoReconnect() {
    _reconnectTimer?.cancel();

    _reconnectTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }
      
      final availablePorts = SerialPort.availablePorts;
      // print(availablePorts);
      for (String portName in availablePorts) {
        if (portName == serialPort.name) {
          timer.cancel();
          start();
          
        }
      }

    });
  }

  Map<String, double> parseSeriesStats(String jsonString) {
    try {
      final decoded = json.decode(jsonString);

      final List<dynamic> seriesList = decoded['all_series'];
      final Map<String, double> stats = {};

      for (final item in seriesList) {
        final series = SeriesInfo.fromJson(item);

        stats['${series.key}_min'] = series.min;
        stats['${series.key}_max'] = series.max;
        stats['${series.key}_mean'] = series.mean;
        stats['${series.key}_value_count'] = series.valueCount.toDouble();
      }

      return stats;
    } catch (e) {
      // print('JSON parse error: $e');
      // print("bad string");
      // print(jsonString);
      // print("bad string end");
      // print(jsonString.codeUnits);
      rethrow;
    }
  }

  @override
  void dispose() {
    _disposed = true;


    _reconnectTimer?.cancel();
    _newDataStreamController.close();
    serialPort.close();
    serialPort.dispose();
    print("delete serial port");
  }

  SerialJsonSource(this.serialPort);
}


class SeriesInfo {
  final String key;
  final double min;
  final double max;
  final double mean;
  final int valueCount;

  SeriesInfo({
    required this.key,
    required this.min,
    required this.max,
    required this.mean,
    required this.valueCount,
  });

  factory SeriesInfo.fromJson(Map<String, dynamic> json) {
    return SeriesInfo(
      key: json['key'] as String,
      min: (json['min'] as num).toDouble(),
      max: (json['max'] as num).toDouble(),
      mean: (json['mean'] as num).toDouble(),
      valueCount: json['value_count'] as int,
    );
  }
}