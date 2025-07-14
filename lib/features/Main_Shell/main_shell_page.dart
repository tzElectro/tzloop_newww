import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:tzloop_newww/core/router/app_router.dart';
import 'package:tzloop_newww/features/Main_Shell/presentation/widgets/drawer.dart';
import 'package:tzloop_newww/features/Main_Shell/presentation/widgets/appbar.dart';
import 'package:tzloop_newww/features/Main_Shell/presentation/widgets/navbar.dart';
import 'package:tzloop_newww/features/Main_Shell/presentation/widgets/subtitile_banner.dart';

@RoutePage()
class MainShellPage extends StatelessWidget {
  const MainShellPage({super.key});

  static const List<String> _main_titles = [
    'Devices',
    'Scenes',
    'Sound Sync',
    'Schedule',
  ];

  @override
  Widget build(BuildContext context) {
    return AutoTabsRouter(
      routes: const [
        DevicesRoute(),
        // const ScenesRoute(),
        // const SoundSyncRoute(),
        // const ScheduleRoute(),
      ],
      builder: (context, child) {
        final tabsRouter = AutoTabsRouter.of(context);
        return Scaffold(
          appBar: const CustomAppBar(
            title: 'Tzloop',
            rightIcon: Icons.wifi,
          ),
          drawer: const DrawerWidget(),
          body: Column(
            children: [
              SubtitleBanner(
                subtitle: _main_titles[tabsRouter.activeIndex],
              ),
              Expanded(
                child: child,
              ),
            ],
          ),
          bottomNavigationBar: CustomBottomNavBar(
            currentIndex: tabsRouter.activeIndex,
            onTap: tabsRouter.setActiveIndex,
            mainNav: true,
          ),
        );
      },
    );
  }
}
