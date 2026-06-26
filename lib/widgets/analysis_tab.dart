
import 'package:flutter/material.dart';
import 'package:silvanus/types/series_request.dart';
import 'package:silvanus/widgets/charts/line.dart';
import 'package:silvanus/widgets/key_selector.dart';
import 'package:silvanus/widgets/source_select.dart';

import 'package:silvanus/data_sources/data_engine.dart';

class AnalysisTab extends StatefulWidget{
  final DataEngine engine;
  const AnalysisTab({super.key, required this.engine});

  @override
  State<StatefulWidget> createState() => _AnalysisTabState();


}

class _AnalysisTabState extends State<AnalysisTab> {
  SeriesGroupRequest selectedSeries = SeriesGroupRequest.empty();

  @override
  Widget build(BuildContext context) {

    return Row(
      children: [
        // Left side: selector
        Expanded(
          flex: 1,
          child: KeySelector(
            onSelectionChanged: (newSelection) {
              setState(() {
                selectedSeries = newSelection;
              });
            },
            engine: widget.engine,
            key: ValueKey(widget.engine.hashCode),

          ),
        ),

      //   // Right side: graph
        Expanded(
          flex: 2,
          child: Line(
            seriesToShow: selectedSeries,
            key: ValueKey(widget.engine.hashCode),
            engine: widget.engine,

          ),
        ),
      ],
    );
  }
}