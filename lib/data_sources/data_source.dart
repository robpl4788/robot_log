import 'dart:collection';
import 'package:silvanus/types/time_stamped_value.dart';
import 'dart:async';

abstract class DataSource {
  Stream<HashMap<String, List<TimeStampedDouble>>> get newDataStream;

  void start();

  void dispose();
}

