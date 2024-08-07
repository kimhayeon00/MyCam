import AVFoundation
import UIKit
import SwiftUI
import CoreImage

class CameraService: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var filteredImage: UIImage?
    var session: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var photoOutput: AVCapturePhotoOutput?
    private var currentCamera: AVCaptureDevice?
    private var ciContext = CIContext()
    private var currentCIImage: CIImage?
    
    // UserDefaults를 사용하여 값 초기화
    @Published var exposureValue: Double {
        didSet {
             applyFilter()
             UserDefaults.standard.exposureValue = exposureValue
        }
    }
    
    @Published var brillianceValue: Double {
        didSet {
             applyFilter()
             UserDefaults.standard.brillianceValue = brillianceValue
        }
    }
    
    @Published var highlightValue: Double {
        didSet {
             applyFilter()
             UserDefaults.standard.highlightValue = highlightValue
        }
    }
    
    @Published var shadowValue: Double {
        didSet {
             applyFilter()
             UserDefaults.standard.shadowValue = shadowValue
        }
    }
    
    @Published var contrastValue: Double {
        didSet {
             applyFilter()
             UserDefaults.standard.contrastValue = contrastValue
        }
    }
    
    @Published var brightnessValue: Double {
        didSet {
             applyFilter()
             UserDefaults.standard.brightnessValue = brightnessValue
        }
    }
    
    @Published var vibranceValue: Double {
        didSet {
             applyFilter()
             UserDefaults.standard.vibranceValue = vibranceValue
        }
    }
    
    @Published var warmthValue: Double {
        didSet {
             applyFilter()
             UserDefaults.standard.warmthValue = warmthValue
        }
    }
    
    @Published var showOriginal: Bool = false {
        didSet { applyFilter() }
    }
    
    private var isTakingPhoto = false

    override init() {
        // 필터 값 UserDefaults에서 로드
        self.exposureValue = UserDefaults.standard.exposureValue
        self.brillianceValue = UserDefaults.standard.brillianceValue
        self.highlightValue = UserDefaults.standard.highlightValue
        self.shadowValue = UserDefaults.standard.shadowValue
        self.contrastValue = UserDefaults.standard.contrastValue
        self.brightnessValue = UserDefaults.standard.brightnessValue
        self.vibranceValue = UserDefaults.standard.vibranceValue
        self.warmthValue = UserDefaults.standard.warmthValue
        
        super.init()
        setupSession()
    }

    private func setupSession() {
        session = AVCaptureSession()
        session?.beginConfiguration()
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else { return }
        session?.addInput(input)
        currentCamera = camera
        
        session?.sessionPreset = .photo
        
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput?.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        session?.addOutput(videoOutput!)
        
        photoOutput = AVCapturePhotoOutput()
        session?.addOutput(photoOutput!)
        
        // 비디오 회전 설정
        if let connection = videoOutput?.connection(with: .video) {
            connection.videoOrientation = .portrait
        }
        
        session?.commitConfiguration()
        session?.startRunning()
    }
    
    func switchCamera() {
        guard let session = session else { return }
        
        session.beginConfiguration()
        
        guard let currentInput = session.inputs.first as? AVCaptureDeviceInput else { return }
        session.removeInput(currentInput)
        
        let newCameraPosition: AVCaptureDevice.Position = currentCamera?.position == .back ? .front : .back
        guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newCameraPosition),
              let newInput = try? AVCaptureDeviceInput(device: newCamera) else { return }
        
        if session.canAddInput(newInput) {
            session.addInput(newInput)
            currentCamera = newCamera
            
            if let connection = videoOutput?.connection(with: .video) {
                connection.videoOrientation = .portrait
            }
        } else {
            session.addInput(currentInput)
        }
        
        session.commitConfiguration()
    }

    func takePhoto() {
        isTakingPhoto = true
    }

    func applyBrillianceEffect(to ciImage: CIImage, intensity: Double) -> CIImage {
        let normalizedIntensity = intensity / 1000
        let exposureAdjust = CIFilter(name: "CIExposureAdjust")
        exposureAdjust?.setValue(ciImage, forKey: kCIInputImageKey)
        exposureAdjust?.setValue(normalizedIntensity, forKey: kCIInputEVKey)
        
        guard let exposureAdjustedImage = exposureAdjust?.outputImage else {
            return ciImage
        }
        
        let colorControls = CIFilter(name: "CIColorControls")
        colorControls?.setValue(exposureAdjustedImage, forKey: kCIInputImageKey)
        colorControls?.setValue(normalizedIntensity, forKey: kCIInputBrightnessKey)
        colorControls?.setValue(1.05, forKey: kCIInputContrastKey)
        
        guard let brillianceAdjustedImage = colorControls?.outputImage else {
            return exposureAdjustedImage
        }
        
        return brillianceAdjustedImage
    }

    func applyHighlightsEffect(to ciImage: CIImage, intensity: Double) -> CIImage {
        let highlightShadowFilter = CIFilter(name: "CIHighlightShadowAdjust")
        highlightShadowFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        
        let highlightIntensity = (intensity / 100) + 1
        let shadowIntensity = intensity / 100
        
        if highlightIntensity > 1 {
            highlightShadowFilter?.setValue(shadowIntensity, forKey: "inputShadowAmount")
        } else {
            highlightShadowFilter?.setValue(highlightIntensity, forKey: "inputHighlightAmount")
        }
        
        guard let outputImage = highlightShadowFilter?.outputImage else {
            return ciImage
        }

        return outputImage
    }
    
    func applyShadowEffect(to ciImage: CIImage, intensity: Double) -> CIImage {
        let highlightShadowFilter = CIFilter(name: "CIHighlightShadowAdjust")
        highlightShadowFilter?.setValue(ciImage, forKey: kCIInputImageKey)

        let shadowIntensity = intensity / 100

        if shadowIntensity != 0 {
            highlightShadowFilter?.setValue(shadowIntensity, forKey: "inputShadowAmount")
        }
        
        guard let outputImage = highlightShadowFilter?.outputImage else {
            return ciImage
        }

        return outputImage
    }

    func applyContrastEffect(to ciImage: CIImage, intensity: Double) -> CIImage {
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)

        let adjustedIntensity = 1.0 + (intensity / 100.0)
        filter?.setValue(adjustedIntensity, forKey: kCIInputContrastKey)

        guard let outputImage = filter?.outputImage else {
            return ciImage
        }
        return outputImage
    }

    func applyBrightnessEffect(to ciImage: CIImage, intensity: Double) -> CIImage {
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(intensity / 100, forKey: kCIInputBrightnessKey)

        guard let outputImage = filter?.outputImage else {
            return ciImage
        }
        return outputImage
    }

    func applyVibranceEffect(to ciImage: CIImage, intensity: Double) -> CIImage {
        let filter = CIFilter(name: "CIVibrance")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(intensity / 100, forKey: "inputAmount")

        guard let outputImage = filter?.outputImage else {
            return ciImage
        }
        return outputImage
    }

    func applyWarmthEffect(to ciImage: CIImage, intensity: Double) -> CIImage {
        guard let filter = CIFilter(name: "CITemperatureAndTint") else {
            return ciImage
        }

        let neutralVector = CIVector(x: 6500, y: 0)
        
        let targetNeutralVector = intensity > 0 ? CIVector(x: 6500 - intensity * 20 , y: 0) : CIVector(x: 6500 - intensity * 100, y: 0)

        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(neutralVector, forKey: "inputNeutral")
        filter.setValue(targetNeutralVector, forKey: "inputTargetNeutral")

        guard let outputImage = filter.outputImage else {
            return ciImage
        }

        return outputImage
    }

    
    func filterImage(_ ciImage: CIImage) -> CIImage {
        if showOriginal {
                    return ciImage
                }
        var filteredImage = ciImage

        if exposureValue != 0 {
            let filter = CIFilter(name: "CIExposureAdjust")
            filter?.setValue(filteredImage, forKey: kCIInputImageKey)
            filter?.setValue(exposureValue / 100, forKey: kCIInputEVKey)
            if let outputImage = filter?.outputImage {
                filteredImage = outputImage
            }
        }
        
        if brillianceValue != 0 {
            filteredImage = applyBrillianceEffect(to: filteredImage, intensity: brillianceValue)
        }

        if highlightValue != 0 {
            filteredImage = applyHighlightsEffect(to: filteredImage, intensity: highlightValue)
        }
        if shadowValue != 0 {
            filteredImage = applyShadowEffect(to: filteredImage, intensity: shadowValue)
        }
        if contrastValue != 0 {
            filteredImage = applyContrastEffect(to: filteredImage, intensity: contrastValue)
        }
        if brightnessValue != 0 {
            filteredImage = applyBrightnessEffect(to: filteredImage, intensity: brightnessValue)
        }
        if vibranceValue != 0 {
            filteredImage = applyVibranceEffect(to: filteredImage, intensity: vibranceValue)
        }
        if warmthValue != 0 {
            filteredImage = applyWarmthEffect(to: filteredImage, intensity: warmthValue)
        }
        
        return filteredImage
    }

    func applyFilter() {
        guard let currentCIImage = currentCIImage else { return }
        let filteredImageCI = filterImage(currentCIImage)
        
        guard let cgImage = ciContext.createCGImage(filteredImageCI, from: filteredImageCI.extent) else { return }
        
        DispatchQueue.main.async {
            self.filteredImage = UIImage(cgImage: cgImage)
            
            if self.isTakingPhoto {
                self.savePhoto(correctedCIImage: filteredImageCI)
                self.isTakingPhoto = false
            }
        }
    }

    func savePhoto(correctedCIImage: CIImage) {
        let uiImage = UIImage(ciImage: correctedCIImage, scale: 1.0, orientation: .right)
        
        if let rotatedImage = uiImage.rotated(by: -90) {
            UIImageWriteToSavedPhotosAlbum(rotatedImage, nil, nil, nil)
        } else {
            UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        var ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        if currentCamera?.position == .front {
            ciImage = ciImage.oriented(.upMirrored)
        }
        
        self.currentCIImage = ciImage
        applyFilter()
    }


    func setExposure(_ value: Double) {
        exposureValue = value
    }

    func setBrilliance(_ value: Double) {
        brillianceValue = value
    }

    func setHighlight(_ value: Double) {
        highlightValue = value
    }
    
    func setShadow(_ value: Double) {
        shadowValue = value
    }
    func setContrast(_ value: Double) {
        contrastValue = value
    }

    func setBrightness(_ value: Double) {
        brightnessValue = value
    }

    func setVibrance(_ value: Double) {
        vibranceValue = value
    }

    func setWarmth(_ value: Double) {
        warmthValue = value
    }
}

extension UIImage {
    func rotated(by degrees: CGFloat) -> UIImage? {
        let radians = degrees * .pi / 180
        var newSize = CGRect(origin: CGPoint.zero, size: self.size)
            .applying(CGAffineTransform(rotationAngle: radians))
            .size
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        defer { UIGraphicsEndImageContext() }
        let context = UIGraphicsGetCurrentContext()!
        
        // Rotate around the center.
        context.translateBy(x: newSize.width / 2, y: newSize.height / 2)
        context.rotate(by: radians)
        
        // Draw the image in the rotated position.
        self.draw(in: CGRect(x: -self.size.width / 2, y: -self.size.height / 2, width: self.size.width, height: self.size.height))

        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

extension UserDefaults {
    private enum Keys {
        static let exposureValue = "exposureValue"
        static let brillianceValue = "brillianceValue"
        static let highlightValue = "highlightValue"
        static let shadowValue = "shadowValue"
        static let contrastValue = "contrastValue"
        static let brightnessValue = "brightnessValue"
        static let vibranceValue = "vibranceValue"
        static let warmthValue = "warmthValue"
    }
    
    var exposureValue: Double {
        get { return double(forKey: Keys.exposureValue) }
        set { set(newValue, forKey: Keys.exposureValue) }
    }

    var brillianceValue: Double {
        get { return double(forKey: Keys.brillianceValue) }
        set { set(newValue, forKey: Keys.brillianceValue) }
    }

    var highlightValue: Double {
        get { return double(forKey: Keys.highlightValue) }
        set { set(newValue, forKey: Keys.highlightValue) }
    }

    var shadowValue: Double {
        get { return double(forKey: Keys.shadowValue) }
        set { set(newValue, forKey: Keys.shadowValue) }
    }

    var contrastValue: Double {
        get { return double(forKey: Keys.contrastValue) }
        set { set(newValue, forKey: Keys.contrastValue) }
    }

    var brightnessValue: Double {
        get { return double(forKey: Keys.brightnessValue) }
        set { set(newValue, forKey: Keys.brightnessValue) }
    }

    var vibranceValue: Double {
        get { return double(forKey: Keys.vibranceValue) }
        set { set(newValue, forKey: Keys.vibranceValue) }
    }

    var warmthValue: Double {
        get { return double(forKey: Keys.warmthValue) }
        set { set(newValue, forKey: Keys.warmthValue) }
    }
}
