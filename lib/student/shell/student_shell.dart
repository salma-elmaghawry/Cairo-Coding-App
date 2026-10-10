import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StudentShell extends StatelessWidget {
  const StudentShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline)),
        ),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (index) => shell.goBranch(index, initialLocation: index == shell.currentIndex),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: 'student.nav.home'.tr(),
            ),
            NavigationDestination(
              icon: const Icon(Icons.calendar_month_outlined),
              selectedIcon: const Icon(Icons.calendar_month_rounded),
              label: 'student.nav.schedule'.tr(),
            ),
            NavigationDestination(
              icon: const Icon(Icons.smart_display_outlined),
              selectedIcon: const Icon(Icons.smart_display_rounded),
              label: 'student.nav.recordings'.tr(),
            ),
            NavigationDestination(
              icon: const Icon(Icons.tune_outlined),
              selectedIcon: const Icon(Icons.tune_rounded),
              label: 'student.nav.settings'.tr(),
            ),
          ],
        ),
      ),
    );
  }
}
