import Flutter
import UIKit
import Vision

class SceneDelegate: FlutterSceneDelegate {

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)

    guard
      let windowScene = scene as? UIWindowScene,
      let window = windowScene.windows.first,
      let flutterVC = window.rootViewController as? FlutterViewController
    else { return }

    let channel = FlutterMethodChannel(
      name: "closet/background_removal",
      binaryMessenger: flutterVC.binaryMessenger
    )
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

        let outputURL = URL(fileURLWithPath: imagePath)
          .deletingPathExtension()
          .appendingPathExtension("bg_removed.png")
        guard let pngData = UIImage(cgImage: cgOut).pngData() else {
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
