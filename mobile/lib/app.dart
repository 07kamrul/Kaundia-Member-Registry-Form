import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/auth/auth_repository.dart';
import 'core/di/injector.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/settings/settings_bloc.dart';
import 'l10n/app_localizations.dart';

class KaundiaApp extends StatefulWidget {
  const KaundiaApp({super.key});

  @override
  State<KaundiaApp> createState() => _KaundiaAppState();
}

class _KaundiaAppState extends State<KaundiaApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = buildRouter();
    routerNotifier.addListener(_refreshRouter);
  }

  void _refreshRouter() {
    if (mounted) _router.refresh();
  }

  @override
  void dispose() {
    routerNotifier.removeListener(_refreshRouter);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsBloc>(create: (_) => SettingsBloc()),
        BlocProvider<AuthBloc>(create: (_) => AuthBloc(repository: sl<AuthRepository>())),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settings) {
          return MaterialApp.router(
            onGenerateTitle: (context) => AppLocalizations.of(context).brandOrgName,
            routerConfig: _router,
            themeMode: settings.materialThemeMode,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            locale: settings.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
