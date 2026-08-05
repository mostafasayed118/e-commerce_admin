import 'package:flutter/material.dart';

import 'core/di/injection.dart';
import 'data/database/seed_data.dart';
import 'presentation/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Formal bootstrap (Task 12): composition root first, then seed so the app
  // is demoable on launch, then the real shell.
  setupDependencies();
  try {
    await getIt<SeedData>().seedIfNeeded();
  } catch (error) {
    // Never let a seed failure kill startup silently; the app still opens
    // and the error is visible in the console (Section D.4: no silent
    // failures). Seeding retries on the next launch (version guard).
    debugPrint('Seeding failed: $error');
  }
  runApp(const ShopAdminApp());
}
