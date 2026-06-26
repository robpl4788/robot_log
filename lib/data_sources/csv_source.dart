
import 'package:silvanus/data_sources/data_source.dart';
import 'package:silvanus/types/time_stamped_value.dart';
import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:csv/csv.dart';

class CSVSource extends DataSource {
  final String filePath;

  final StreamController<HashMap<String, List<TimeStampedDouble>>> _controller = StreamController<HashMap<String, List<TimeStampedDouble>>>.broadcast();

  @override
  Stream<HashMap<String, List<TimeStampedDouble>>> get newDataStream => _controller.stream;

  @override
  void start() {
    final File file = File(filePath);

    final decodedCSV = csv.decodeWithHeaders(file.readAsStringSync());

    HashMap<String, List<TimeStampedDouble>> newData = HashMap();

    for (var row in decodedCSV) {
      Map rowMap = row.toMap();
      double time = double.parse(rowMap["time"]);

      for (var key in rowMap.keys) {
        if (key != "time") {
          double value = double.parse(rowMap[key]);
          TimeStampedDouble newValue = TimeStampedValue(value, time);
          (newData[key] ??= []).add(newValue);
        }
      }
    }

    _controller.add(newData);
  }

  @override
  void dispose() {
    _controller.close();
  }

  CSVSource(this.filePath);
}
