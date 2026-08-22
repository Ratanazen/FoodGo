#!/bin/bash
mkdir -p lib/features/splash/presentation
mkdir -p lib/features/onboarding/presentation
mkdir -p lib/features/explore/presentation
mkdir -p lib/features/addresses/presentation
mkdir -p lib/features/payments/presentation
mkdir -p lib/features/settings/presentation

cat << 'INNER_EOF' > lib/features/splash/presentation/splash_screen.dart
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Splash Screen')));
  }
}
INNER_EOF

cat << 'INNER_EOF' > lib/features/onboarding/presentation/onboarding_screen.dart
import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Onboarding Screen')));
  }
}
INNER_EOF

cat << 'INNER_EOF' > lib/features/explore/presentation/explore_screen.dart
import 'package:flutter/material.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Explore Screen')));
  }
}
INNER_EOF

cat << 'INNER_EOF' > lib/features/addresses/presentation/addresses_screen.dart
import 'package:flutter/material.dart';

class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Addresses Screen')));
  }
}
INNER_EOF

cat << 'INNER_EOF' > lib/features/payments/presentation/payments_screen.dart
import 'package:flutter/material.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Payments Screen')));
  }
}
INNER_EOF

cat << 'INNER_EOF' > lib/features/settings/presentation/settings_screen.dart
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Settings Screen')));
  }
}
INNER_EOF
