import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tickerless/core/router/app_router.dart';
import 'package:tickerless/core/router/route_args.dart';
import 'package:tickerless/core/theme/app_theme.dart';
import 'package:tickerless/features/discovery/domain/entities/discovery_source.dart';
import 'package:tickerless/features/discovery/presentation/bloc/lens_bloc.dart';
import 'package:tickerless/features/discovery/presentation/bloc/lens_event.dart';
import 'package:tickerless/features/discovery/presentation/bloc/lens_state.dart';
import 'package:tickerless/features/discovery/presentation/widgets/discovery_mode_switch.dart';
import 'package:tickerless/features/discovery/presentation/widgets/lens_focus_frame.dart';

/// Point the camera at a thing; find out who makes it.
///
/// The camera controller is a platform resource tied to this widget's
/// lifecycle, so it stays here — everything downstream of the shutter (frame
/// analysis, resolving, the result) belongs to [LensBloc].
class LensScreen extends StatefulWidget {
  const LensScreen({super.key});

  @override
  State<LensScreen> createState() => _LensScreenState();
}

class _LensScreenState extends State<LensScreen> {
  CameraController? _camera;
  bool _flashOn = false;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _camera?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final devices = await availableCameras();
      if (devices.isEmpty) return;

      final controller = CameraController(
        devices.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _camera = controller);
    } catch (_) {
      // No camera here — the simulator, or permission refused. The demo path
      // below takes over, and says so.
    }
  }

  Future<void> _scan() async {
    final camera = _camera;
    if (_capturing) return;

    if (camera == null || !camera.value.isInitialized) {
      // The preview asset is an iPhone, so this is a deterministic demo input
      // rather than a fallback pretending recognition happened.
      context.read<LensBloc>().add(const LensDemoScanRequested('iPhone Apple'));
      return;
    }

    setState(() => _capturing = true);
    try {
      final capture = await camera.takePicture();
      if (mounted) {
        context.read<LensBloc>().add(LensFrameCaptured(capture.path));
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _toggleFlash() async {
    final camera = _camera;
    if (camera == null) return;

    _flashOn = !_flashOn;
    await camera.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: BlocBuilder<LensBloc, LensState>(
      builder: (context, state) => Stack(
        fit: StackFit.expand,
        children: [
          if (_camera?.value.isInitialized ?? false)
            CameraPreview(_camera!)
          else
            Image.asset('assets/images/lens-phone.png', fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xAA000000),
                  Colors.transparent,
                  Color(0xDD000000),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                const Positioned(left: 8, top: 4, child: BackButton()),
                Positioned(
                  right: 12,
                  top: 4,
                  child: IconButton(
                    onPressed: _toggleFlash,
                    icon: Icon(_flashOn ? Icons.flash_on : Icons.flash_off),
                  ),
                ),
                const Center(child: LensFocusFrame()),
                Positioned(
                  left: 22,
                  right: 22,
                  bottom: 28,
                  child: _LensReadout(
                    state: state,
                    busy: _capturing || state is LensScanning,
                    onScan: _scan,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _LensReadout extends StatelessWidget {
  const _LensReadout({
    required this.state,
    required this.busy,
    required this.onScan,
  });

  final LensState state;
  final bool busy;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final match = state is LensMatched ? (state as LensMatched).match : null;

    return Column(
      children: [
        Text(
          match?.company.name ?? _headline,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        ),
        Text(
          match == null
              ? _subhead
              : '${(match.confidence * 100).round()}% match · ${match.company.symbol}',
          style: const TextStyle(color: Colors.white70),
        ),
        if (state is LensFailed)
          Text(
            (state as LensFailed).message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        const SizedBox(height: 18),
        if (match == null)
          _ShutterButton(busy: busy, retry: state is! LensIdle, onTap: onScan)
        else
          FilledButton(
            onPressed: () => context.push(
              AppRoutes.passport,
              extra: PassportArgs(
                company: match.company,
                source: DiscoverySource.lens.describe('Camera scan'),
              ),
            ),
            child: Text('Explore ${match.company.name}'),
          ),
        const SizedBox(height: 16),
        DiscoveryModeSwitch(
          selected: 'Lens',
          onSelected: (mode) => switch (mode) {
            'Link' => context.pushReplacement(AppRoutes.link),
            'Search' => context.pushReplacement(AppRoutes.search),
            _ => null,
          },
        ),
      ],
    );
  }

  String get _headline => switch (state) {
    LensUnmatched() || LensFailed() => 'Nothing matched',
    _ => 'Point at something',
  };

  String get _subhead => switch (state) {
    LensUnmatched() => 'Try AAPL, GOOGL, META or NVDA products',
    LensFailed() => 'The resolver could not be reached',
    _ => 'Products, packaging, screens',
  };
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({
    required this.busy,
    required this.retry,
    required this.onTap,
  });

  final bool busy;
  final bool retry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: busy ? null : onTap,
    child: Container(
      width: 74,
      height: 74,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 5),
      ),
      child: busy
          ? const CircularProgressIndicator(
              color: Colors.black,
              strokeWidth: 2,
            )
          : retry
          ? const Icon(Icons.refresh, color: Colors.black)
          : null,
    ),
  );
}
