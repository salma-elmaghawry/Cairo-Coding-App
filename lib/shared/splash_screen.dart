import 'package:cairo_coding_app/core/animations/animations.dart';
import 'package:cairo_coding_app/core/widgets/app_logo.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: AppLogo(size: 180))).fadeInScale();
  }
}
