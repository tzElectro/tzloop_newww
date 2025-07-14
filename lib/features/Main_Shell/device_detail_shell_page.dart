import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tzloop_newww/core/router/app_router.dart';
import 'package:tzloop_newww/features/Main_Shell/presentation/widgets/drawer.dart';
import 'package:tzloop_newww/features/Main_Shell/presentation/widgets/navbar.dart';
import 'package:tzloop_newww/features/Main_Shell/presentation/widgets/appbar.dart';
import 'package:tzloop_newww/features/Main_Shell/presentation/widgets/subtitile_banner.dart';
import 'package:tzloop_newww/features/Main_Shell/domain/models/device_provider.dart';

@RoutePage()
class DeviceDetailShellPage extends ConsumerWidget {
  final String deviceName;
  final String deviceIp;

  const DeviceDetailShellPage({
    super.key,
    @PathParam('deviceName') required this.deviceName,
    @PathParam('deviceIp') required this.deviceIp,
  });

  static const List<String> _device_titles = [
    'Color',
    'Settings',
    'Instance',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProviderScope(
      overrides: [
        scopedDeviceIpProvider.overrideWithValue(deviceIp),
      ],
      child: AutoTabsRouter.tabBar(
        routes: [
          const ColorRoute(),
          DeviceSettingsRoute(deviceId: deviceIp, currentName: deviceName),
          const InstanceRoute(),
        ],
        builder: (context, child, _) {
          final tabsRouter = AutoTabsRouter.of(context);
          return Scaffold(
            appBar: CustomAppBar(
              title: deviceName,
              rightIcon: Icons.wifi,
            ),
            drawer: const DrawerWidget(),
            body: Column(
              children: [
                SubtitleBanner(
                    subtitle: _device_titles[tabsRouter.activeIndex]),
                Expanded(child: child),
              ],
            ),
            bottomNavigationBar: CustomBottomNavBar(
              currentIndex: tabsRouter.activeIndex,
              onTap: tabsRouter.setActiveIndex,
              mainNav: false,
            ),
          );
        },
      ),
    );
  }

  String getMacFromIp(String ip, WidgetRef ref) {
    try {
      final devices = ref.read(deviceProvider);
      return devices.firstWhere((d) => d.info.ip == ip).info.mac;
    } catch (e) {
      throw Exception("Device with IP $ip not found");
    }
  }
}
