import Flutter
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private static let logoReferences = [
    (label: "Apple logo", asset: "LensAppleLogo"),
    (label: "NVIDIA logo", asset: "LensNvidiaLogo"),
    (label: "Google logo", asset: "LensGoogleLogo"),
    (label: "Meta logo", asset: "LensMetaLogo"),
    (label: "Microsoft logo", asset: "LensMicrosoftLogo"),
  ]

  private static let brandTerms = [
    "Apple", "MacBook", "iPhone", "iPad", "AirPods",
    "NVIDIA", "GeForce", "RTX", "CUDA",
    "Google", "Pixel", "Android", "YouTube",
    "Meta", "Instagram", "WhatsApp", "Quest",
    "Microsoft", "Windows", "Surface", "Xbox", "Azure", "Copilot",
  ]

  /// Center-weighted crops make a brand mark useful even when it occupies a
  /// small area on the back of a laptop, phone, package, or display.
  private static let logoRegions = [
    CGRect(x: 0, y: 0, width: 1, height: 1),
    CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8),
    CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6),
    CGRect(x: 0.3, y: 0.3, width: 0.4, height: 0.4),
  ]

  private lazy var logoFeaturePrints: [(label: String, print: VNFeaturePrintObservation)] = {
    Self.logoReferences.compactMap { reference in
      guard let image = UIImage(named: reference.asset)?.cgImage else { return nil }
      let request = VNGenerateImageFeaturePrintRequest()
      do {
        try VNImageRequestHandler(cgImage: image).perform([request])
        guard let featurePrint = request.results?.first as? VNFeaturePrintObservation else {
          return nil
        }
        return (reference.label, featurePrint)
      } catch {
        return nil
      }
    }
  }()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "TickerlessVision") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "com.tickerless/vision",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard (call.method == "recognizeText" || call.method == "analyzeImage"),
            let arguments = call.arguments as? [String: Any],
            let path = arguments["path"] as? String else {
        result(FlutterMethodNotImplemented)
        return
      }
      let textRequest = VNRecognizeTextRequest()
      textRequest.recognitionLevel = .accurate
      textRequest.usesLanguageCorrection = true
      textRequest.customWords = Self.brandTerms
      let classificationRequest = VNClassifyImageRequest()
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          var requests: [VNRequest] = [textRequest]
          let logoRequests = Self.logoRegions.map { region in
            let request = VNGenerateImageFeaturePrintRequest()
            request.regionOfInterest = region
            return request
          }
          if call.method == "analyzeImage" {
            requests.append(classificationRequest)
            requests.append(contentsOf: logoRequests)
          }
          try VNImageRequestHandler(url: URL(fileURLWithPath: path)).perform(requests)
          let text = textRequest.results?
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n") ?? ""
          if call.method == "recognizeText" {
            DispatchQueue.main.async { result(text) }
            return
          }
          var labels = classificationRequest.results?
            .filter { $0.confidence >= 0.03 }
            .prefix(32)
            .map(\.identifier) ?? []
          if let logo = self.bestLogoMatch(from: logoRequests), !labels.contains(logo) {
            labels.append(logo)
          }
          DispatchQueue.main.async { result(["text": text, "labels": labels]) }
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(code: "vision_error", message: error.localizedDescription, details: nil))
          }
        }
      }
    }
  }

  private func bestLogoMatch(
    from requests: [VNGenerateImageFeaturePrintRequest]
  ) -> String? {
    let observations = requests.compactMap {
      $0.results?.first as? VNFeaturePrintObservation
    }
    guard !observations.isEmpty else { return nil }

    let scores = logoFeaturePrints.compactMap { reference -> (String, Float)? in
      var closest = Float.greatestFiniteMagnitude
      for observation in observations {
        var distance: Float = 0
        do {
          try observation.computeDistance(&distance, to: reference.print)
          closest = min(closest, distance)
        } catch {
          continue
        }
      }
      return closest.isFinite ? (reference.label, closest) : nil
    }.sorted { $0.1 < $1.1 }

    guard let best = scores.first, best.1 <= 10.5 else { return nil }
    if scores.count > 1, scores[1].1 - best.1 < 0.75 { return nil }
    return best.0
  }
}
