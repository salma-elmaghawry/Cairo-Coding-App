import 'package:cairo_coding_app/admin/shell/admin_sidebar.dart';
import 'package:cairo_coding_app/core/helpers/breakpoints.dart';
import 'package:cairo_coding_app/core/widgets/wordmark.dart';
import 'package:flutter/material.dart';

class AdminScaffold extends StatelessWidget {
  const AdminScaffold({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (context.isWideScreen) {
      return Scaffold(
        body: Row(
          children: [
            SizedBox(width: 248, child: AdminSidebar(location: location)),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Wordmark(fontSize: 12)),
      drawer: Drawer(child: AdminSidebar(location: location, inDrawer: true)),
      body: child,
    );
  }
}
