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
    registerBackgroundRemovalChannel(engineBridge: engineBridge)
  }

  private func registerBackgroundRemovalChannel(engineBridge: FlutterImplicitEngineBridge) {
    guard let messenger = engineBridge.pluginRegistry
            .registrar(forPlugin: "BackgroundRemovalPlugin")?.messenger() else { return }

    let channel = FlutterMethodChannel(name: "closet/background_removal", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "removeBackground",
            let args = call.arguments as? [String: Any],
            let imagePath = args["imagePath"] as? String else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.removeBackground(imagePath: imagePath, result: result)
    }
  }

  private func removeBackground(imagePath: String, result: @escaping FlutterResult) {
    guard #available(iOS 17.0, *) else {
      // Fallback: return original path unchanged on older iOS
      result(imagePath)
      return
    }

    guard let inputImage = UIImage(contentsOfFile: imagePath),
          let cgImage = inputImage.cgImage else {
      result(imagePath)
      return
    }

    let request = VNGenerateForegroundInstanceMaskRequest()
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

    DispatchQueue.global(qos: .userInitiated).async {
      do {
        try handler.perform([request])
        guard let observation = request.results?.first else {
          DispatchQueue.main.async { result(imagePath) }
          return
        }

        let maskedBuffer = try observation.generateMaskedImage(
          ofInstances: observation.allInstances,
          from: handler,
          croppedToInstancesExtent: false
        )

        let ciImage = CIImage(cvPixelBuffer: maskedBuffer)
        let context = CIContext()
        guard let cgOut = context.createCGImage(ciImage, from: ciImage.extent) else {
          DispatchQueue.main.async { result(imagePath) }
          return
        }

        let outputImage = UIImage(cgImage: cgOut)
        let outputURL = URL(fileURLWithPath: imagePath).deletingPathExtension()
          .appendingPathExtension("bg_removed.png")
        guard let pngData = outputImage.pngData() else {
          DispatchQueue.main.async { result(imagePath) }
          return
        }
        try pngData.write(to: outputURL)
        DispatchQueue.main.async { result(outputURL.path) }
      } catch {
        DispatchQueue.main.async { result(imagePath) }
      }
    }
  }
}
