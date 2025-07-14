// lib/models/wled_state.dart

// No direct 'dart:convert' import needed here unless you plan to
// jsonEncode/decode WledState directly outside of WledDevice.

class WledState {
  final bool on;
  final int bri;
  final int transition;
  final int ps;
  final int pl;
  final int? ledmap;
  final WledAudioReactive? AudioReactive;
  final WledNightlight nl;
  final WledUdpn udpn;
  final int? lor;
  final int? mainseg;
  final List<WledSegment> seg;
  final int fx; // FIX: Added fx property for the currently active effect ID

  WledState({
    required this.on,
    required this.bri,
    required this.transition,
    required this.ps,
    required this.pl,
    this.ledmap,
    this.AudioReactive,
    required this.nl,
    required this.udpn,
    this.lor,
    this.mainseg,
    required this.seg,
    required this.fx, // FIX: Added fx to constructor
  });

  factory WledState.fromJson(Map<String, dynamic> json) {
    return WledState(
      on: json['on'] as bool? ?? false,
      bri: json['bri'] as int? ?? 0,
      transition: json['transition'] as int? ?? 0,
      ps: json['ps'] as int? ?? -1,
      pl: json['pl'] as int? ?? -1,
      ledmap: json['ledmap'] as int?,
      AudioReactive: json['AudioReactive'] != null
          ? WledAudioReactive.fromJson(
              json['AudioReactive'] as Map<String, dynamic>)
          : null,
      nl: WledNightlight.fromJson(
          json['nl'] as Map<String, dynamic>? ?? {}), // Handle null nl object
      udpn: WledUdpn.fromJson(json['udpn'] as Map<String, dynamic>? ??
          {}), // Handle null udpn object
      lor: json['lor'] as int?,
      mainseg: json['mainseg'] as int?,
      seg: (json['seg'] as List? ?? [])
          .map((e) => WledSegment.fromJson(
              e as Map<String, dynamic>? ?? {})) // Handle null segment map
          .toList(),
      fx: json['fx'] as int? ?? 0, // FIX: Parse fx from JSON
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'on': on,
      'bri': bri,
      'transition': transition,
      'ps': ps,
      'pl': pl,
      'ledmap': ledmap,
      'AudioReactive': AudioReactive?.toJson(),
      'nl': nl.toJson(),
      'udpn': udpn.toJson(),
      'lor': lor,
      'mainseg': mainseg,
      'seg': seg.map((s) => s.toJson()).toList(),
      'fx': fx, // FIX: Add fx to toJson
    };
  }

  WledState copyWith({
    bool? on,
    int? bri,
    int? transition,
    int? ps,
    int? pl,
    int? ledmap,
    WledAudioReactive? AudioReactive,
    WledNightlight? nl,
    WledUdpn? udpn,
    int? lor,
    int? mainseg,
    List<WledSegment>? seg,
    int? fx, // FIX: Added fx to copyWith
  }) {
    return WledState(
      on: on ?? this.on,
      bri: bri ?? this.bri,
      transition: transition ?? this.transition,
      ps: ps ?? this.ps,
      pl: pl ?? this.pl,
      ledmap: ledmap ?? this.ledmap,
      AudioReactive: AudioReactive ?? this.AudioReactive,
      nl: nl ?? this.nl,
      udpn: udpn ?? this.udpn,
      lor: lor ?? this.lor,
      mainseg: mainseg ?? this.mainseg,
      seg: seg ?? this.seg,
      fx: fx ?? this.fx, // FIX: Use fx in copyWith
    );
  }
}

class WledAudioReactive {
  final bool on;

  WledAudioReactive({required this.on});

  factory WledAudioReactive.fromJson(Map<String, dynamic> json) {
    return WledAudioReactive(
      on: json['on'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'on': on};
  }

  WledAudioReactive copyWith({bool? on}) {
    return WledAudioReactive(on: on ?? this.on);
  }
}

class WledNightlight {
  final bool on;
  final int dur;
  final int? mode;
  final bool fade;
  final int tbri;
  final int? rem;

  WledNightlight({
    required this.on,
    required this.dur,
    this.mode,
    required this.fade,
    required this.tbri,
    this.rem,
  });

  factory WledNightlight.fromJson(Map<String, dynamic> json) {
    return WledNightlight(
      on: json['on'] as bool? ?? false,
      dur: json['dur'] as int? ?? 0,
      mode: json['mode'] as int?,
      fade: json['fade'] as bool? ?? false,
      tbri: json['tbri'] as int? ?? 0,
      rem: json['rem'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'on': on,
      'dur': dur,
      'mode': mode,
      'fade': fade,
      'tbri': tbri,
      'rem': rem,
    };
  }

  WledNightlight copyWith({
    bool? on,
    int? dur,
    int? mode,
    bool? fade,
    int? tbri,
    int? rem,
  }) {
    return WledNightlight(
      on: on ?? this.on,
      dur: dur ?? this.dur,
      mode: mode ?? this.mode,
      fade: fade ?? this.fade,
      tbri: tbri ?? this.tbri,
      rem: rem ?? this.rem,
    );
  }
}

class WledUdpn {
  final bool send;
  final bool recv;
  final int? sgrp;
  final int? rgrp;

  WledUdpn({
    required this.send,
    required this.recv,
    this.sgrp,
    this.rgrp,
  });

  factory WledUdpn.fromJson(Map<String, dynamic> json) {
    return WledUdpn(
      send: json['send'] as bool? ?? false,
      recv: json['recv'] as bool? ?? false,
      sgrp: json['sgrp'] as int?,
      rgrp: json['rgrp'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'send': send,
      'recv': recv,
      'sgrp': sgrp,
      'rgrp': rgrp,
    };
  }

  WledUdpn copyWith({
    bool? send,
    bool? recv,
    int? sgrp,
    int? rgrp,
  }) {
    return WledUdpn(
      send: send ?? this.send,
      recv: recv ?? this.recv,
      sgrp: sgrp ?? this.sgrp,
      rgrp: rgrp ?? this.rgrp,
    );
  }
}

class WledSegment {
  final int id;
  final int start;
  final int stop;
  final int len;
  final int? grp;
  final int? spc;
  final int? of;
  final bool on;
  final bool frz;
  final int bri;
  final int? cct;
  final int? set;
  final List<List<int>> col;
  final int fx;
  final int sx;
  final int ix;
  final int pal;
  final bool sel;
  final bool rev;
  final int cln;

  WledSegment({
    required this.id,
    required this.start,
    required this.stop,
    required this.len,
    this.grp,
    this.spc,
    this.of,
    required this.on,
    required this.frz,
    required this.bri,
    this.cct,
    this.set,
    required this.col,
    required this.fx,
    required this.sx,
    required this.ix,
    required this.pal,
    required this.sel,
    required this.rev,
    required this.cln,
  });

  factory WledSegment.fromJson(Map<String, dynamic> json) {
    return WledSegment(
      id: json['id'] as int? ?? 0,
      start: json['start'] as int? ?? 0,
      stop: json['stop'] as int? ?? 0,
      len: json['len'] as int? ?? 0,
      grp: json['grp'] as int?,
      spc: json['spc'] as int?,
      of: json['of'] as int?,
      on: json['on'] as bool? ?? false,
      frz: json['frz'] as bool? ?? false,
      bri: json['bri'] as int? ?? 0,
      cct: json['cct'] as int?,
      set: json['set'] as int?,
      col: (json['col'] as List? ?? [])
          .map((e) => List<int>.from(e as List? ?? []))
          .toList(),
      fx: json['fx'] as int? ?? 0,
      sx: json['sx'] as int? ?? 0,
      ix: json['ix'] as int? ?? 0,
      pal: json['pal'] as int? ?? 0,
      sel: json['sel'] as bool? ?? false,
      rev: json['rev'] as bool? ?? false,
      cln: json['cln'] as int? ?? -1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start': start,
      'stop': stop,
      'len': len,
      'grp': grp,
      'spc': spc,
      'of': of,
      'on': on,
      'frz': frz,
      'bri': bri,
      'cct': cct,
      'set': set,
      'col': col,
      'fx': fx,
      'sx': sx,
      'ix': ix,
      'pal': pal,
      'sel': sel,
      'rev': rev,
      'cln': cln,
    };
  }

  WledSegment copyWith({
    int? id,
    int? start,
    int? stop,
    int? len,
    int? grp,
    int? spc,
    int? of,
    bool? on,
    bool? frz,
    int? bri,
    int? cct,
    int? set,
    List<List<int>>? col,
    int? fx,
    int? sx,
    int? ix,
    int? pal,
    bool? sel,
    bool? rev,
    int? cln,
  }) {
    return WledSegment(
      id: id ?? this.id,
      start: start ?? this.start,
      stop: stop ?? this.stop,
      len: len ?? this.len,
      grp: grp ?? this.grp,
      spc: spc ?? this.spc,
      of: of ?? this.of,
      on: on ?? this.on,
      frz: frz ?? this.frz,
      bri: bri ?? this.bri,
      cct: cct ?? this.cct,
      set: set ?? this.set,
      col: col ?? this.col,
      fx: fx ?? this.fx,
      sx: sx ?? this.sx,
      ix: ix ?? this.ix,
      pal: pal ?? this.pal,
      sel: sel ?? this.sel,
      rev: rev ?? this.rev,
      cln: cln ?? this.cln,
    );
  }
}
