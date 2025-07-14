// lib/models/wled_info.dart

class WledInfo {
  final String ver;
  final int vid;
  final WledLeds leds;
  final String name;
  final int udpport;
  final bool live;
  final int fxcount;
  final int palcount;
  final String arch;
  final String core;
  final int freeheap;
  final int uptime;
  final int opt;
  final String brand;
  final String product;
  final String btype;
  final String mac;
  final String ip; // FIX: Added ip property

  WledInfo({
    required this.ver,
    required this.vid,
    required this.leds,
    required this.name,
    required this.udpport,
    required this.live,
    required this.fxcount,
    required this.palcount,
    required this.arch,
    required this.core,
    required this.freeheap,
    required this.uptime,
    required this.opt,
    required this.brand,
    required this.product,
    required this.btype,
    required this.mac,
    required this.ip, // FIX: Added ip to constructor
  });

  factory WledInfo.fromJson(Map<String, dynamic> json) {
    return WledInfo(
      ver: json['ver'] as String? ?? '',
      vid: json['vid'] as int? ?? 0,
      leds: WledLeds.fromJson(json['leds'] as Map<String, dynamic>? ?? {}),
      name: json['name'] as String? ?? '',
      udpport: json['udpport'] as int? ?? 0,
      live: json['live'] as bool? ?? false,
      fxcount: json['fxcount'] as int? ?? 0,
      palcount: json['palcount'] as int? ?? 0,
      arch: json['arch'] as String? ?? '',
      core: json['core'] as String? ?? '',
      freeheap: json['freeheap'] as int? ?? 0,
      uptime: json['uptime'] as int? ?? 0,
      opt: json['opt'] as int? ?? 0,
      brand: json['brand'] as String? ?? '',
      product: json['product'] as String? ?? '',
      btype: json['btype'] as String? ?? '',
      mac: json['mac'] as String? ?? '',
      ip: json['ip'] as String? ?? '0.0.0.0', // FIX: Parse ip from JSON, default to '0.0.0.0'
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ver': ver,
      'vid': vid,
      'leds': leds.toJson(),
      'name': name,
      'udpport': udpport,
      'live': live,
      'fxcount': fxcount,
      'palcount': palcount,
      'arch': arch,
      'core': core,
      'freeheap': freeheap,
      'uptime': uptime,
      'opt': opt,
      'brand': brand,
      'product': product,
      'btype': btype,
      'mac': mac,
      'ip': ip, // FIX: Add ip to toJson
    };
  }

  WledInfo copyWith({
    String? ver,
    int? vid,
    WledLeds? leds,
    String? name,
    int? udpport,
    bool? live,
    int? fxcount,
    int? palcount,
    String? arch,
    String? core,
    int? freeheap,
    int? uptime,
    int? opt,
    String? brand,
    String? product,
    String? btype,
    String? mac,
    String? ip, // FIX: Added ip to copyWith
  }) {
    return WledInfo(
      ver: ver ?? this.ver,
      vid: vid ?? this.vid,
      leds: leds ?? this.leds,
      name: name ?? this.name,
      udpport: udpport ?? this.udpport,
      live: live ?? this.live,
      fxcount: fxcount ?? this.fxcount,
      palcount: palcount ?? this.palcount,
      arch: arch ?? this.arch,
      core: core ?? this.core,
      freeheap: freeheap ?? this.freeheap,
      uptime: uptime ?? this.uptime,
      opt: opt ?? this.opt,
      brand: brand ?? this.brand,
      product: product ?? this.product,
      btype: btype ?? this.btype,
      mac: mac ?? this.mac,
      ip: ip ?? this.ip, // FIX: Use ip in copyWith
    );
  }
}

class WledLeds {
  final int count;
  final bool rgbw;
  final List<int> pin;
  final int pwr;
  final int maxpwr;
  final int maxseg;

  WledLeds({
    required this.count,
    required this.rgbw,
    required this.pin,
    required this.pwr,
    required this.maxpwr,
    required this.maxseg,
  });

  factory WledLeds.fromJson(Map<String, dynamic> json) {
    return WledLeds(
      count: json['count'] as int? ?? 0,
      rgbw: json['rgbw'] as bool? ?? false,
      pin: (json['pin'] as List?)?.map((e) => e as int).toList() ?? [],
      pwr: json['pwr'] as int? ?? 0,
      maxpwr: json['maxpwr'] as int? ?? 0,
      maxseg: json['maxseg'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'rgbw': rgbw,
      'pin': pin,
      'pwr': pwr,
      'maxpwr': maxpwr,
      'maxseg': maxseg,
    };
  }

  WledLeds copyWith({
    int? count,
    bool? rgbw,
    List<int>? pin,
    int? pwr,
    int? maxpwr,
    int? maxseg,
  }) {
    return WledLeds(
      count: count ?? this.count,
      rgbw: rgbw ?? this.rgbw,
      pin: pin ?? this.pin,
      pwr: pwr ?? this.pwr,
      maxpwr: maxpwr ?? this.maxpwr,
      maxseg: maxseg ?? this.maxseg,
    );
  }
}
