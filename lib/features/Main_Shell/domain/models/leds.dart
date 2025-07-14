class Leds {
  final int count;
  final bool rgbw;
  final List<int> pin;
  final int pwr;
  final int maxpwr;
  final int maxseg;

  Leds({
    required this.count,
    required this.rgbw,
    required this.pin,
    required this.pwr,
    required this.maxpwr,
    required this.maxseg,
  });

  factory Leds.fromJson(Map<String, dynamic> json) {
    return Leds(
      count: json['count'],
      rgbw: json['rgbw'],
      pin: List<int>.from(json['pin']),
      pwr: json['pwr'],
      maxpwr: json['maxpwr'],
      maxseg: json['maxseg'],
    );
  }
}
