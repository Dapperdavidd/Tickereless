import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/company.dart';
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
        setState(() => note = 'Camera unavailable · demo scan ready');
      }
    }
  }

  Future<void> scan() async {
    if (busy) return;
    setState(() {
      busy = true;
      note = null;
    });
    var text = 'iPhone';
    try {
      if (camera case final active? when active.value.isInitialized) {
        final capture = await active.takePicture();
        final recognized = await ocr.invokeMethod<String>('recognizeText', {
          'path': capture.path,
        });
        if (recognized != null && recognized.trim().isNotEmpty) {
          text = recognized;
        }
      }
      final matches = await api.lens(text);
      if (mounted) {
        setState(() => match = matches.isEmpty ? fallback : matches.first);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          match = fallback;
          note = 'Offline demo result';
        });
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  CompanyMatch get fallback => const CompanyMatch(
    company: DemoCompanies.apple,
    reason: 'iPhone is an Apple product',
    confidence: .98,
  );

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
              Center(
                child: Container(
                  width: 285,
                  height: 330,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 1.3),
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
              Positioned(
                left: 22,
                right: 22,
                bottom: 28,
                child: Column(
                  children: [
                    Text(
                      match?.company.name ?? 'Point at something',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      match == null
                          ? 'Products, logos, receipts'
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
