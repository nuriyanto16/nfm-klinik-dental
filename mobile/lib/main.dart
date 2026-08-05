import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/update/app_update_notifier.dart';
import 'core/update/update_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  runApp(const ProviderScope(child: NinaDentalCareApp()));
}

class NinaDentalCareApp extends StatelessWidget {
  const NinaDentalCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Nina Dental Care',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Wrap the entire app in the update checker overlay
      builder: (context, child) => _UpdateCheckerWrapper(child: child!),
    );
  }
}

/// Transparent overlay widget that sits above the entire app.
/// On first frame, triggers a version check then shows dialog if needed.
class _UpdateCheckerWrapper extends ConsumerStatefulWidget {
  const _UpdateCheckerWrapper({required this.child});
  final Widget child;

  @override
  ConsumerState<_UpdateCheckerWrapper> createState() =>
      _UpdateCheckerWrapperState();
}

class _UpdateCheckerWrapperState extends ConsumerState<_UpdateCheckerWrapper> {
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    // Wait for the first frame to render before triggering the update check
    // so the UI is visible when the dialog appears.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appUpdateNotifierProvider.notifier).checkForUpdate();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen for update state changes and show dialog when an update is found.
    ref.listen<UpdateState>(appUpdateNotifierProvider, (previous, next) {
      if (!mounted) return;

      if (next is UpdateAvailable && !_dialogShown) {
        _dialogShown = true;
        UpdateDialog.show(
          context,
          info: next.info,
          isMandatory: next.isMandatory,
        ).then((_) {
          // Allow re-showing dialog on next check after dismiss
          _dialogShown = false;
        });
      }
    });

    return widget.child;
  }
}
