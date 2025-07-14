class Udpn {
  final bool send;
  final bool recv;

  Udpn({required this.send, required this.recv});

  factory Udpn.fromJson(Map<String, dynamic> json) {
    return Udpn(send: json['send'], recv: json['recv']);
  }
}
