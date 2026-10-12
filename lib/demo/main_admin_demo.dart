import 'package:cairo_coding_app/admin/admin_router.dart';
import 'package:cairo_coding_app/bootstrap.dart';
import 'package:cairo_coding_app/core/config/app_flavor.dart';
import 'package:cairo_coding_app/data/data_providers.dart';

Future<void> main() =>
    bootstrap(flavor: AppFlavor.admin, routerProvider: adminRouterProvider, overrides: fakeSourceOverrides);
