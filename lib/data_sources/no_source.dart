
import 'package:silvanus/data_sources/data_source.dart';
import 'package:silvanus/types/time_stamped_value.dart';
import 'dart:async';
import 'dart:collection';


class NoSource extends DataSource {

  final StreamController<HashMap<String, List<TimeStampedDouble>>> _controller = StreamController<HashMap<String, List<TimeStampedDouble>>>.broadcast();

  @override
  Stream<HashMap<String, List<TimeStampedDouble>>> get newDataStream => _controller.stream;

  @override
  void start() {}

  @override
  void dispose() {
    _controller.close();
  }

  NoSource();
  }
