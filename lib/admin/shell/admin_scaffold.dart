import 'package:cairo_coding_app/admin/shell/admin_alerts.dart';
import 'package:cairo_coding_app/admin/shell/admin_sidebar.dart';
import 'package:cairo_coding_app/admin/shell/admin_top_bar.dart';
import 'package:cairo_coding_app/core/helpers/breakpoints.dart';
import 'package:cairo_coding_app/core/widgets/wordmark.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdminScaffold extends StatefulWidget {
  const AdminScaffold({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  State<AdminScaffold> createState() => _AdminScaffoldState();
}

class _AdminScaffoldState extends State<AdminScaffold> {
  final _searchFocus = FocusNode(debugLabel: 'admin search');

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!context.isWideScreen) {
      return Scaffold(
        appBar: AppBar(
          title: const Wordmark(fontSize: 12),
          actions: const [AlertsButton(), SizedBox(width: 8), NewMenuButton(), SizedBox(width: 12)],
        ),
        drawer: Drawer(child: AdminSidebar(location: widget.location, inDrawer: true)),
        body: widget.child,
      );
    }

    void focusSearch() => _searchFocus.requestFocus();

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): focusSearch,
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): focusSearch,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Row(
            children: [
              SizedBox(width: 248, child: AdminSidebar(location: widget.location)),
              Expanded(
                child: Column(
                  children: [
                    AdminTopBar(searchFocus: _searchFocus),
                    Expanded(child: widget.child),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
