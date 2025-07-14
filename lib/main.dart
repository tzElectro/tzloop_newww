import 'package:flutter/material.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/feedback_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/Main_Shell/domain/models/device_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox('device_cache');
  await Hive.openBox<String>('effects_cache');
  await Hive.openBox<Map>('device_mappings');

  // Set up error widget for better debugging
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Container(
        color: Colors.red,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 60),
            const SizedBox(height: 16),
            Text(
              'Error:\n${details.exception}',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  };

  // Run the app with a ProviderScope and error logging
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  MyApp({super.key});

  final _appRouter = AppRouter();

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Start device discovery when the app starts
    Future.delayed(Duration.zero, () {
      final deviceNotifier = ref.read(deviceProvider.notifier);
      deviceNotifier.discoverDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TZLoop ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routerDelegate: widget._appRouter.delegate(
        navigatorObservers: () => [NavigatorObserver()],
      ),
      routeInformationParser: widget._appRouter.defaultRouteParser(),
      builder: (context, child) {
        return Material(
          type: MaterialType.transparency,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
            child: FeedbackProvider(
              child: child ?? const SizedBox(),
            ),
          ),
        );
      },
    );
  }
}
