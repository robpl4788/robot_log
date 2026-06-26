
import 'dart:collection';
import 'package:silvanus/types/time_stamped_value.dart';
import 'package:silvanus/data_sources/data_source.dart';
import 'dart:async';

class DataEngine {
  HashMap<String, List<TimeStampedDouble>> data = HashMap();
  DataSource source;
  StreamSubscription<HashMap<String, List<TimeStampedDouble>>>? dataSubscription;

  DataEngine({required this.source});
  final dataStreamController = StreamController<HashMap<String, List<TimeStampedDouble>>>.broadcast();
  final keyStreamController = StreamController<List<String>>.broadcast();

  Stream<HashMap<String, List<TimeStampedDouble>>> get dataStream => dataStreamController.stream;
  Stream<List<String>> get keyStream => keyStreamController.stream;


  void start() {
    dataSubscription = source.newDataStream.listen(addData);
    source.start();
  }

  void dispose() {
    dataSubscription?.cancel();
    source.dispose();
  }

  void addData(HashMap<String, List<TimeStampedDouble>> newData) {
    bool newKeys = false;
    for (var key in newData.keys) {
      // If the key doesn't exist in the current data, initialize it with an empty list
      if (!data.containsKey(key)) {
        data[key] = [];
        newKeys = true;
      }

      data[key]!.addAll(newData[key]!);
    }

    dataStreamController.add(data);

    if (newKeys) {
      keyStreamController.add(data.keys.toList());
    }
  }

  List<String> getAvailableKeys() {
    return data.keys.toList();
  }

  List<TimeStampedDouble> getSeries(String key) {
    return data[key] ?? [];
  }

}