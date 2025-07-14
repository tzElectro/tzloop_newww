import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import '../../../../core/router/app_router.dart';

@RoutePage()
class SetupLandingPage extends StatelessWidget {
  const SetupLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup WLED Device'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lightbulb_outline,
              size: 100,
              color: Colors.blue,
            ),
            const SizedBox(height: 32),
            const Text(
              'Welcome to TZLOOP',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Let\'s set up your WLED device',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                AutoRouter.of(context).push(const NewDeviceSetupRoute());
              },
              child: const Text('Start Setup'),
            ),
          ],
        ),
      ),
    );
  }
}
