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
      guard call.method == "recognizeText",
            let arguments = call.arguments as? [String: Any],
            let path = arguments["path"] as? String else {
        result(FlutterMethodNotImplemented)
        return
      }
      let request = VNRecognizeTextRequest { request, error in
        if let error {
          result(FlutterError(code: "vision_error", message: error.localizedDescription, details: nil))
          return
        }
        let text = (request.results as? [VNRecognizedTextObservation])?
          .compactMap { $0.topCandidates(1).first?.string }
          .joined(separator: "\n") ?? ""
        result(text)
      }
      request.recognitionLevel = .accurate
      request.usesLanguageCorrection = true
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          try VNImageRequestHandler(url: URL(fileURLWithPath: path)).perform([request])
        } catch {
          result(FlutterError(code: "vision_error", message: error.localizedDescription, details: nil))
        }
      }
    }
  }
}
