// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

abstract class _$AppRouter extends RootStackRouter {
  // ignore: unused_element
  _$AppRouter();

  @override
  final Map<String, PageFactory> pagesMap = {
    ColorRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const ColorPage(),
      );
    },
    DeviceDetailShellRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<DeviceDetailShellRouteArgs>(
          orElse: () => DeviceDetailShellRouteArgs(
                deviceName: pathParams.getString('deviceName'),
                deviceIp: pathParams.getString('deviceIp'),
              ));
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: DeviceDetailShellPage(
          key: args.key,
          deviceName: args.deviceName,
          deviceIp: args.deviceIp,
        ),
      );
    },
    DeviceOverviewRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<DeviceOverviewRouteArgs>(
          orElse: () => DeviceOverviewRouteArgs(
              ipAddress: pathParams.getString('ipAddress')));
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: DeviceOverviewPage(
          key: args.key,
          ipAddress: args.ipAddress,
        ),
      );
    },
    DeviceSettingsRoute.name: (routeData) {
      final args = routeData.argsAs<DeviceSettingsRouteArgs>();
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: DeviceSettingsPage(
          key: args.key,
          deviceId: args.deviceId,
          currentName: args.currentName,
        ),
      );
    },
    DevicesRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const DevicesPage(),
      );
    },
    EffectsGalleryRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const EffectsGalleryPage(),
      );
    },
    EffectsRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const EffectsPage(),
      );
    },
    InstanceRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const InstancePage(),
      );
    },
    MainShellRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const MainShellPage(),
      );
    },
    NetworkScanRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const NetworkScanPage(),
      );
    },
    NewDeviceSetupRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const NewDeviceSetupPage(),
      );
    },
    PaletteRoute.name: (routeData) {
      final args = routeData.argsAs<PaletteRouteArgs>();
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: PalettePage(
          key: args.key,
          ipAddress: args.ipAddress,
        ),
      );
    },
    SetupLandingRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const SetupLandingPage(),
      );
    },
  };
}

/// generated route for
/// [ColorPage]
class ColorRoute extends PageRouteInfo<void> {
  const ColorRoute({List<PageRouteInfo>? children})
      : super(
          ColorRoute.name,
          initialChildren: children,
        );

  static const String name = 'ColorRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [DeviceDetailShellPage]
class DeviceDetailShellRoute extends PageRouteInfo<DeviceDetailShellRouteArgs> {
  DeviceDetailShellRoute({
    Key? key,
    required String deviceName,
    required String deviceIp,
    List<PageRouteInfo>? children,
  }) : super(
          DeviceDetailShellRoute.name,
          args: DeviceDetailShellRouteArgs(
            key: key,
            deviceName: deviceName,
            deviceIp: deviceIp,
          ),
          rawPathParams: {
            'deviceName': deviceName,
            'deviceIp': deviceIp,
          },
          initialChildren: children,
        );

  static const String name = 'DeviceDetailShellRoute';

  static const PageInfo<DeviceDetailShellRouteArgs> page =
      PageInfo<DeviceDetailShellRouteArgs>(name);
}

class DeviceDetailShellRouteArgs {
  const DeviceDetailShellRouteArgs({
    this.key,
    required this.deviceName,
    required this.deviceIp,
  });

  final Key? key;

  final String deviceName;

  final String deviceIp;

  @override
  String toString() {
    return 'DeviceDetailShellRouteArgs{key: $key, deviceName: $deviceName, deviceIp: $deviceIp}';
  }
}

/// generated route for
/// [DeviceOverviewPage]
class DeviceOverviewRoute extends PageRouteInfo<DeviceOverviewRouteArgs> {
  DeviceOverviewRoute({
    Key? key,
    required String ipAddress,
    List<PageRouteInfo>? children,
  }) : super(
          DeviceOverviewRoute.name,
          args: DeviceOverviewRouteArgs(
            key: key,
            ipAddress: ipAddress,
          ),
          rawPathParams: {'ipAddress': ipAddress},
          initialChildren: children,
        );

  static const String name = 'DeviceOverviewRoute';

  static const PageInfo<DeviceOverviewRouteArgs> page =
      PageInfo<DeviceOverviewRouteArgs>(name);
}

class DeviceOverviewRouteArgs {
  const DeviceOverviewRouteArgs({
    this.key,
    required this.ipAddress,
  });

  final Key? key;

  final String ipAddress;

  @override
  String toString() {
    return 'DeviceOverviewRouteArgs{key: $key, ipAddress: $ipAddress}';
  }
}

/// generated route for
/// [DeviceSettingsPage]
class DeviceSettingsRoute extends PageRouteInfo<DeviceSettingsRouteArgs> {
  DeviceSettingsRoute({
    Key? key,
    required String deviceId,
    required String currentName,
    List<PageRouteInfo>? children,
  }) : super(
          DeviceSettingsRoute.name,
          args: DeviceSettingsRouteArgs(
            key: key,
            deviceId: deviceId,
            currentName: currentName,
          ),
          rawPathParams: {'deviceIp': deviceId},
          initialChildren: children,
        );

  static const String name = 'DeviceSettingsRoute';

  static const PageInfo<DeviceSettingsRouteArgs> page =
      PageInfo<DeviceSettingsRouteArgs>(name);
}

class DeviceSettingsRouteArgs {
  const DeviceSettingsRouteArgs({
    this.key,
    required this.deviceId,
    required this.currentName,
  });

  final Key? key;

  final String deviceId;

  final String currentName;

  @override
  String toString() {
    return 'DeviceSettingsRouteArgs{key: $key, deviceId: $deviceId, currentName: $currentName}';
  }
}

/// generated route for
/// [DevicesPage]
class DevicesRoute extends PageRouteInfo<void> {
  const DevicesRoute({List<PageRouteInfo>? children})
      : super(
          DevicesRoute.name,
          initialChildren: children,
        );

  static const String name = 'DevicesRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [EffectsGalleryPage]
class EffectsGalleryRoute extends PageRouteInfo<void> {
  const EffectsGalleryRoute({List<PageRouteInfo>? children})
      : super(
          EffectsGalleryRoute.name,
          initialChildren: children,
        );

  static const String name = 'EffectsGalleryRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [EffectsPage]
class EffectsRoute extends PageRouteInfo<void> {
  const EffectsRoute({List<PageRouteInfo>? children})
      : super(
          EffectsRoute.name,
          initialChildren: children,
        );

  static const String name = 'EffectsRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [InstancePage]
class InstanceRoute extends PageRouteInfo<void> {
  const InstanceRoute({List<PageRouteInfo>? children})
      : super(
          InstanceRoute.name,
          initialChildren: children,
        );

  static const String name = 'InstanceRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [MainShellPage]
class MainShellRoute extends PageRouteInfo<void> {
  const MainShellRoute({List<PageRouteInfo>? children})
      : super(
          MainShellRoute.name,
          initialChildren: children,
        );

  static const String name = 'MainShellRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [NetworkScanPage]
class NetworkScanRoute extends PageRouteInfo<void> {
  const NetworkScanRoute({List<PageRouteInfo>? children})
      : super(
          NetworkScanRoute.name,
          initialChildren: children,
        );

  static const String name = 'NetworkScanRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [NewDeviceSetupPage]
class NewDeviceSetupRoute extends PageRouteInfo<void> {
  const NewDeviceSetupRoute({List<PageRouteInfo>? children})
      : super(
          NewDeviceSetupRoute.name,
          initialChildren: children,
        );

  static const String name = 'NewDeviceSetupRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [PalettePage]
class PaletteRoute extends PageRouteInfo<PaletteRouteArgs> {
  PaletteRoute({
    Key? key,
    required String ipAddress,
    List<PageRouteInfo>? children,
  }) : super(
          PaletteRoute.name,
          args: PaletteRouteArgs(
            key: key,
            ipAddress: ipAddress,
          ),
          initialChildren: children,
        );

  static const String name = 'PaletteRoute';

  static const PageInfo<PaletteRouteArgs> page =
      PageInfo<PaletteRouteArgs>(name);
}

class PaletteRouteArgs {
  const PaletteRouteArgs({
    this.key,
    required this.ipAddress,
  });

  final Key? key;

  final String ipAddress;

  @override
  String toString() {
    return 'PaletteRouteArgs{key: $key, ipAddress: $ipAddress}';
  }
}

/// generated route for
/// [SetupLandingPage]
class SetupLandingRoute extends PageRouteInfo<void> {
  const SetupLandingRoute({List<PageRouteInfo>? children})
      : super(
          SetupLandingRoute.name,
          initialChildren: children,
        );

  static const String name = 'SetupLandingRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}
