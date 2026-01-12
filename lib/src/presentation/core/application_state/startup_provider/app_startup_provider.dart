import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../firebase_options.dart';
import '../../../../core/di/dependency_injection.dart';
import '../localization_provider/localization_provider.dart';

part 'app_startup_provider.g.dart';

@Riverpod(keepAlive: true)
Future<void> appStartup(Ref ref) async {
  ref.onDispose(() {
    ref.invalidate(sharedPreferencesProvider);
  });

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await ref.watch(sharedPreferencesProvider.future);

  await ref.read(localizationProvider.notifier).setCurrentLocal();

  await ref.watch(initializaNotificationUseCaseProvider).call();
}
