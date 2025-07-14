class Nightlight {
  final bool on;
  final int dur;
  final bool fade;
  final int tbri;

  Nightlight({
    required this.on,
    required this.dur,
    required this.fade,
    required this.tbri,
  });

  factory Nightlight.fromJson(Map<String, dynamic> json) {
    return Nightlight(
      on: json['on'],
      dur: json['dur'],
      fade: json['fade'],
      tbri: json['tbri'],
    );
  }
}
