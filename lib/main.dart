import 'package:flutter/material.dart';
import "package:flutter/services.dart";

import "package:flutter_floatwing/flutter_floatwing.dart";
import "package:umbra/app_theme.dart";
import "package:umbra/widgets/permission_banner.dart";
import "package:umbra/widgets/primary_action_button.dart";
import "package:umbra/widgets/protection_card.dart";
import "package:umbra/widgets/secondary_action_button.dart";
import "package:umbra/widgets/umbra_header.dart";

import "./umbra_overlay.dart";
export "./umbra_overlay.dart";

const MethodChannel floatwingWindowChannel =
MethodChannel('im.zoe.labs/flutter_floatwing/window');

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   final initialised = await FloatwingPlugin().initialize();
//
//   debugPrint("Floatwing initialized: $initialised");
//
//   runApp(MyApp());
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final plugin = FloatwingPlugin();

  final initialised = await plugin.initialize();
  debugPrint("Floatwing initialized: $initialised");

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool isLoading = false;
  bool _autoPermissionPromptShown = false;
  bool _startupTaskRunning = false;
  bool _resumeCheckPending = false;

  bool permissionGranted = false;
  bool serviceRunning = false;

  int _nextOverlayNumber = 1;
  final Set<String> _activeOverlayIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    checkOverlayPermissions();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      runStartupFlow(autoOpenSettings: true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<bool> promoteUmbraService() async {
    const channel = MethodChannel(
      'im.zoe.labs/flutter_floatwing/window',
    );

    final result = await channel.invokeMethod<bool>(
      'service.promote',
      {
        'title': 'Umbra is active',
        'description': 'Your screen protection overlays are running',
        'showWhen': false,
        'ticker': 'Umbra is protecting your screen',
        'subText': 'Umbra',
      },
    );

    return result ?? false;
  }

  Future<void> runStartupFlow({bool autoOpenSettings = false}) async {
    if (_startupTaskRunning) return;

    _startupTaskRunning = true;

    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final plugin = FloatwingPlugin();

      final granted = await plugin.checkPermission();

      if (!mounted) return;

      setState(() {
        permissionGranted = granted;
      });

      if (!granted) {
        if (autoOpenSettings && !_autoPermissionPromptShown) {
          _autoPermissionPromptShown = true;
          await plugin.openPermissionSetting();
        }
        return;
      }

      final alreadyRunning = await plugin.isServiceRunning();
      if (!alreadyRunning) {
        final started = await plugin.startService();
        debugPrint("Service start accepted: $started");
      }

      // await plugin.syncWindows();
      debugPrint("Before sync: ${plugin.windows.keys}");

      final synced = await plugin.syncWindows();

      debugPrint("Sync successful: $synced");
      debugPrint("After sync: ${plugin.windows.keys}");
      if (!mounted) return;
      setState(() {
        _activeOverlayIds
          ..clear()
          ..addAll(plugin.windows.keys);
      });

      final running = await plugin.isServiceRunning();
      if (!mounted) return;
      setState(() {
        serviceRunning = running;
      });

      debugPrint("Service running: $running");
    } catch (e, stackTrace) {
      debugPrint("Startup error: $e");
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _startupTaskRunning = false;
      setState(() {
        isLoading = false;
      });
      if (_resumeCheckPending && mounted) {
        _resumeCheckPending = false;
        runStartupFlow();
      }
    }
  }

  Future<void> checkOverlayPermissions() async {
    final granted = await FloatwingPlugin().checkPermission();

    if (!mounted) return;

    setState(() {
      permissionGranted = granted;
    });

    debugPrint("Overlay permission granted: $granted");
  }

  Future<void> requestOverlayPermission() async {
    await FloatwingPlugin().openPermissionSetting();
  }

  Future<void> startOverlayService() async {
    final plugin = FloatwingPlugin();
    try {
      final permission = await plugin.checkPermission();

      if (!permission) return;

      final started = await plugin.startService();
      debugPrint("Start service request accepted: $started");

      final running = await plugin.isServiceRunning();
      debugPrint("Actual service running: $running");

      if (!mounted) return;

      setState(() {
        serviceRunning = running;
      });
    } catch (e, stackTrace) {
      debugPrint("Service error: $e");
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> createNewOverlay() async {
    final id = "umbra-${DateTime.now().microsecondsSinceEpoch}";

    final created = await createOverlay(
      id: id,
      x: 500,
      y: 500,
      width: 400,
      height: 200,
    );

    if (created) {
      setState(() {
        _activeOverlayIds.add(id);
        _nextOverlayNumber++;
      });

      debugPrint("Active overlay ids: $_activeOverlayIds");
    }
  }

  Future<bool> createOverlay({
    required String id,
    required int x,
    required int y,
    required int width,
    required int height,
  }) async {
    try {
      final window = await WindowConfig(
        id: id,
        width: width,
        height: height,
        x: x,
        y: y,
        clickable: true,
        draggable: false,
        autosize: false,
        entry: 'umbraOverlayMain',
      ).to().create(start: true);

      final created = window != null;

      debugPrint('Overlay $id created: $created');

      return created;
    } catch (e, stackTrace) {
      debugPrint('Overlay creation error: $e');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> hideAllOverlays() async {
    final plugin = FloatwingPlugin();
    await plugin.syncWindows();

    for (final id in _activeOverlayIds.toList()) {
      final window = plugin.windows[id];
      if (window == null) continue;

      final hidden = await window.hide();
      debugPrint("Overlays $id hidden $hidden");
    }
  }

  Future<void> showAllOverlays() async {
    final plugin = FloatwingPlugin();
    await plugin.syncWindows();

    for (final id in _activeOverlayIds.toList()) {
      final window = plugin.windows[id];
      if (window == null) continue;
      await window.show();
      debugPrint("Overlay $id visible $window");
    }
  }

  Future<void> deleteAllOverlays() async {
    final plugin = FloatwingPlugin();
    await plugin.syncWindows();

    for (final id in _activeOverlayIds.toList()) {
      final window = plugin.windows[id];
      if (window == null) continue;
      await window.close();
      setState(() {
        _activeOverlayIds.remove(id);
      });
      debugPrint("Overlay $id removed & closed $window");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_startupTaskRunning) {
        _resumeCheckPending = true;
        return;
      }
      runStartupFlow();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  UmbraHeader(),
                  const SizedBox(height: 34),
                  PermissionBanner(
                    permissionGranted: permissionGranted,
                    onTap: () async {
                      await FloatwingPlugin().openPermissionSetting();
                    },
                  ),

                  const SizedBox(height: 20),

                  ProtectionCard(
                    activeOverlayCount: _activeOverlayIds.length,
                    serviceRunning: serviceRunning,
                  ),

                  const SizedBox(height: 20),

                  PrimaryActionButton(
                    onPressed: permissionGranted && serviceRunning
                        ? createNewOverlay
                        : null,
                    label: "Create new overlay",
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: SecondaryActionButton(
                          label: "Hide all",
                          onPressed: hideAllOverlays,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SecondaryActionButton(
                          label: "Show all",
                          onPressed: showAllOverlays,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  DestructiveActionButton(
                    label: "Delete all",
                    onPressed: deleteAllOverlays,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
