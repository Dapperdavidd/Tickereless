import Flutter
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
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
      let classificationRequest = VNClassifyImageRequest()
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          try VNImageRequestHandler(url: URL(fileURLWithPath: path)).perform(
            call.method == "analyzeImage" ? [textRequest, classificationRequest] : [textRequest]
          )
          let text = textRequest.results?
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n") ?? ""
          if call.method == "recognizeText" {
            result(text)
            return
          }
          let labels = classificationRequest.results?
            .filter { $0.confidence >= 0.15 }
            .prefix(8)
            .map(\.identifier) ?? []
          result(["text": text, "labels": labels])
        } catch {
          result(FlutterError(code: "vision_error", message: error.localizedDescription, details: nil))
        }
      }
    }
  }
}
