import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_client.dart';
import '../theme/app_theme.dart';
import 'experience_screens.dart';

class FunctionalLensScreen extends StatefulWidget {
  const FunctionalLensScreen({super.key});
  @override
  State<FunctionalLensScreen> createState() => _FunctionalLensScreenState();
}

class _FunctionalLensScreenState extends State<FunctionalLensScreen> {
  CameraController? camera;
  static const ocr = MethodChannel('com.tickerless/vision');
  final api = TickerlessApi();
  CompanyMatch? match;
  String? note;
  bool scanned = false;
  bool busy = false;
  bool flash = false;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    try {
      final devices = await availableCameras();
      if (devices.isEmpty) {
        return;
      }
      final next = CameraController(
        devices.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await next.initialize();
      if (!mounted) {
        await next.dispose();
        return;
      }
      setState(() => camera = next);
    } catch (_) {
      if (mounted) {
        setState(() => note = 'Demo image · point and scan on a device');
      }
    }
  }

  Future<void> scan() async {
    if (busy) return;
    setState(() {
      busy = true;
      note = null;
    });
    String? text;
    var labels = <String>[];
    try {
      if (camera case final active? when active.value.isInitialized) {
        final capture = await active.takePicture();
        final analysis = await ocr.invokeMapMethod<String, dynamic>(
          'analyzeImage',
          {'path': capture.path},
        );
        final recognized = analysis?['text']?.toString();
        if (recognized != null && recognized.trim().isNotEmpty) {
          text = recognized;
        }
        labels = (analysis?['labels'] as List<dynamic>? ?? const [])
            .map((value) => value.toString())
            .toList();
      } else {
        // The preview asset is an iPhone, so this is an explicit deterministic
        // demo input rather than a fallback for failed recognition.
        text = 'iPhone Apple';
      }
      if (text == null && labels.isEmpty) {
        if (mounted) {
          setState(() {
            scanned = true;
            match = null;
            note = 'No supported company detected. Try visible product or brand text.';
          });
        }
        return;
      }
      final matches = await api.lens(text ?? '', labels: labels);
      if (mounted) {
        setState(() {
          scanned = true;
          match = matches.firstOrNull;
          note = matches.isEmpty ? 'No supported company detected.' : null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          scanned = true;
          match = null;
          note = 'Lens could not reach the resolver. Try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> toggleFlash() async {
    if (camera == null) return;
    flash = !flash;
    await camera!.setFlashMode(flash ? FlashMode.torch : FlashMode.off);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    camera?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Stack(
      fit: StackFit.expand,
      children: [
        if (camera?.value.isInitialized ?? false)
          CameraPreview(camera!)
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
                  onPressed: toggleFlash,
                  icon: Icon(flash ? Icons.flash_on : Icons.flash_off),
                ),
              ),
              Center(child: const _FocusFrame(width: 285, height: 330)),
              Positioned(
                left: 22,
                right: 22,
                bottom: 28,
                child: Column(
                  children: [
                    Text(
                      match?.company.name ??
                          (scanned ? 'Nothing matched' : 'Point at something'),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      match == null
                          ? (scanned
                                ? 'Try AAPL, GOOGL, META or NVDA products'
                                : 'Products, packaging, screens')
                          : '${(match!.confidence * 100).round()}% match · ${match!.company.symbol}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    if (note != null)
                      Text(
                        note!,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    const SizedBox(height: 18),
                    if (match == null)
                      GestureDetector(
                        onTap: scan,
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
                              : scanned
                              ? const Icon(Icons.refresh, color: Colors.black)
                              : null,
                        ),
                      )
                    else
                      FilledButton(
                        onPressed: () => openScreen(
                          context,
                          PassportScreen(
                            company: match!.company,
                            source: 'Camera scan · Lens',
                          ),
                        ),
                        child: Text('Explore ${match!.company.name}'),
                      ),
                    const SizedBox(height: 16),
                    const _LensModes(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _FocusFrame extends StatelessWidget {
  const _FocusFrame({required this.width, required this.height});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: CustomPaint(painter: _CornerPainter()),
  );
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const length = 28.0;
    final path = Path()
      ..moveTo(0, length)
      ..lineTo(0, 0)
      ..lineTo(length, 0)
      ..moveTo(size.width - length, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, length)
      ..moveTo(size.width, size.height - length)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width - length, size.height)
      ..moveTo(length, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, size.height - length);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LensModes extends StatelessWidget {
  const _LensModes();
  @override
  Widget build(BuildContext context) => Container(
    height: 46,
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0xDD061016),
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      children: [
        Expanded(
          child: Container(
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            child: const Text(
              'Lens',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const Expanded(
          child: Center(child: Text('Link', style: TextStyle(fontSize: 12))),
        ),
        const Expanded(
          child: Center(child: Text('Search', style: TextStyle(fontSize: 12))),
        ),
      ],
    ),
  );
}
