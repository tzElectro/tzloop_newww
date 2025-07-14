import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../features/Main_Shell/presentation/pages/device_page.dart';
import '../../features/Main_Shell/presentation/pages/Device_overview.dart';
import '../../features/Main_Shell/presentation/pages/effects_page.dart';
import '../../features/Main_Shell/presentation/pages/color_picker_page.dart';
import '../../features/Main_Shell/presentation/pages/effects_gallery_page.dart';
import '../../features/Main_Shell/presentation/pages/instance_page.dart';
import '../../features/Main_Shell/presentation/pages/network_scan_page.dart';
import '../../features/setup/presentation/pages/new_device_setup_page.dart';
import '../../features/setup/presentation/pages/setup_landing_page.dart';
import '../../features/palette/presentation/pages/palette_page.dart';
import '../../features/Main_Shell/device_detail_shell_page.dart';
import '../../features/Main_Shell/main_shell_page.dart';
import '../../features/device_management/presentation/pages/device_settings_page.dart';

part 'app_router.gr.dart';

// lib/core/router/app_router.dart
@AutoRouterConfig()
class AppRouter extends _$AppRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          path: '/',
          page: MainShellRoute.page,
          initial: true,
          children: [
            AutoRoute(
              path: '',
              page: DevicesRoute.page,
              initial: true,
            ),
          ],
        ),
        AutoRoute(
          path: '/device/:deviceName/:deviceIp',
          page: DeviceDetailShellRoute.page,
          children: [
            AutoRoute(
              path: 'color',
              page: ColorRoute.page,
              initial: true,
            ),
            AutoRoute(
              path: 'settings',
              page: DeviceSettingsRoute.page,
            ),
            AutoRoute(
              path: 'instance',
              page: InstanceRoute.page,
            ),
            AutoRoute(
              path: 'palette',
              page: PaletteRoute.page,
            ),
          ],
        ),
        AutoRoute(path: '/setup', page: SetupLandingRoute.page),
        AutoRoute(path: '/setup/new-device', page: NewDeviceSetupRoute.page),
        AutoRoute(path: '/network-scan', page: NetworkScanRoute.page),
        AutoRoute(path: '/effects-gallery', page: EffectsGalleryRoute.page),
      ];
}
