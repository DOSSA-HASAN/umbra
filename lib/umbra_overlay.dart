import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_floatwing/flutter_floatwing.dart";

@pragma("vm:entry-point")
void umbraOverlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(((_) => const UmbraOverlay()).floatwing(app: true).make());
}

class UmbraOverlay extends StatefulWidget {
  const UmbraOverlay({super.key});

  @override
  State<UmbraOverlay> createState() => _UmbraOverlayState();
}

class _UmbraOverlayState extends State<UmbraOverlay> {
  static const double _minSize = 40.0;
  static const double _maxWidth = 1200.0;
  static const double _maxHeight = 2000.0;
  static const double _edgeHitSize = 24.0;

  Window? _window;

  double _currentWidth = 400;
  double _currentHeight = 200;

  double _resizeStartWidth = 400;
  double _resizeStartHeight = 200;
  double _resizeStartPointerX = 0;
  double _resizeStartPointerY = 0;

  bool _isUpdatingWindow = false;
  WindowConfig? _pendingConfig;

  double get _pixelRatio =>
      _window?.pixelRadio ?? MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;

  // Keep resize handles usable even when the overlay is very small.
  double get _horizontalEdgeSize =>
      (_currentWidth / 4).clamp(6.0, _edgeHitSize).toDouble();

  double get _verticalEdgeSize =>
      (_currentHeight / 4).clamp(6.0, _edgeHitSize).toDouble();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final win = Window.of(context);

      setState(() {
        _window = win;

        final cfg = win?.config;

        if (cfg != null) {
          if (cfg.width != null && cfg.width! > 0) {
            _currentWidth = cfg.width! / _pixelRatio;
          }

          if (cfg.height != null && cfg.height! > 0) {
            _currentHeight = cfg.height! / _pixelRatio;
          }
        }
      });

      // Let the native side move the window. This is what makes dragging
      // follow the finger smoothly.
      _scheduleWindowUpdate(WindowConfig(draggable: true));
    });
  }

  // Queue window updates instead of allowing them to pile up.
  Future<void> _scheduleWindowUpdate(WindowConfig config) async {
    final win = _window ?? Window.of(context);
    if (win == null) return;

    _pendingConfig = config;

    if (_isUpdatingWindow) return;

    _isUpdatingWindow = true;

    try {
      while (_pendingConfig != null) {
        final next = _pendingConfig!;
        _pendingConfig = null;

        await win.update(next);
      }
    } finally {
      _isUpdatingWindow = false;
    }
  }

  void _syncWindowSize() {
    _scheduleWindowUpdate(
      WindowConfig(
        width: (_currentWidth * _pixelRatio).round(),
        height: (_currentHeight * _pixelRatio).round(),
      ),
    );
  }

  // ---------------- RESIZE ----------------

  void _onHorizontalResizeStart(DragStartDetails details) {
    _resizeStartWidth = _currentWidth;
    _resizeStartPointerX = details.globalPosition.dx;
    // Stop native dragging so it doesn't fight the resize.
    _scheduleWindowUpdate(WindowConfig(draggable: false));
  }

  void _onVerticalResizeStart(DragStartDetails details) {
    _resizeStartHeight = _currentHeight;
    _resizeStartPointerY = details.globalPosition.dy;
    _scheduleWindowUpdate(WindowConfig(draggable: false));
  }

  void _onRightResizeUpdate(DragUpdateDetails details) {
    final dx = details.globalPosition.dx - _resizeStartPointerX;

    setState(() {
      _currentWidth = (_resizeStartWidth + dx).clamp(_minSize, _maxWidth);
    });

    _syncWindowSize();
  }

  void _onLeftResizeUpdate(DragUpdateDetails details) {
    final dx = details.globalPosition.dx - _resizeStartPointerX;

    setState(() {
      _currentWidth = (_resizeStartWidth - dx).clamp(_minSize, _maxWidth);
    });

    _syncWindowSize();
  }

  void _onTopResizeUpdate(DragUpdateDetails details) {
    final dy = details.globalPosition.dy - _resizeStartPointerY;

    setState(() {
      _currentHeight = (_resizeStartHeight - dy).clamp(_minSize, _maxHeight);
    });

    _syncWindowSize();
  }

  void _onBottomResizeUpdate(DragUpdateDetails details) {
    final dy = details.globalPosition.dy - _resizeStartPointerY;

    setState(() {
      _currentHeight = (_resizeStartHeight + dy).clamp(_minSize, _maxHeight);
    });

    _syncWindowSize();
  }

  void _onResizeEnd(DragEndDetails _) {
    _syncWindowSize();
    // Turn native dragging back on.
    _scheduleWindowUpdate(WindowConfig(draggable: true));
  }

  @override
  Widget build(BuildContext context) {
    final horizontalEdge = _horizontalEdgeSize;
    final verticalEdge = _verticalEdgeSize;

    return Material(
      color: Colors.black,
      child: SizedBox(
        width: _currentWidth,
        height: _currentHeight,
        child: Stack(
          children: [
            // Right resize handle
            Positioned(
              right: 0,
              top: verticalEdge,
              bottom: verticalEdge,
              width: horizontalEdge,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: _onHorizontalResizeStart,
                onHorizontalDragUpdate: _onRightResizeUpdate,
                onHorizontalDragEnd: _onResizeEnd,
              ),
            ),

            // Left resize handle
            Positioned(
              left: 0,
              top: verticalEdge,
              bottom: verticalEdge,
              width: horizontalEdge,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: _onHorizontalResizeStart,
                onHorizontalDragUpdate: _onLeftResizeUpdate,
                onHorizontalDragEnd: _onResizeEnd,
              ),
            ),

            // Top resize handle
            Positioned(
              top: 0,
              left: horizontalEdge,
              right: horizontalEdge,
              height: verticalEdge,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragStart: _onVerticalResizeStart,
                onVerticalDragUpdate: _onTopResizeUpdate,
                onVerticalDragEnd: _onResizeEnd,
              ),
            ),

            // Bottom resize handle
            Positioned(
              bottom: 0,
              left: horizontalEdge,
              right: horizontalEdge,
              height: verticalEdge,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragStart: _onVerticalResizeStart,
                onVerticalDragUpdate: _onBottomResizeUpdate,
                onVerticalDragEnd: _onResizeEnd,
              ),
            ),
          ],
        ),
      ),
    );
  }
}