
typedef TimeStampedDouble = TimeStampedValue<double>;


class TimeStampedValue<T> {
  final T value;
  final double timestamp;

  TimeStampedValue(this.value, this.timestamp);
}