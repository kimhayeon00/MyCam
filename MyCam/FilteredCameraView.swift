//
//  FilteredCameraView.swift
//  MyCam
//
//  Created by yeonny on 7/1/24.
//
import SwiftUI
import AVFoundation
import CoreImage
import CoreImage.CIFilterBuiltins
import Photos

struct FilteredCameraView: UIViewControllerRepresentable {
    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate {
        var parent: FilteredCameraView
        var context = CIContext()
        var currentFrame: CVPixelBuffer?

        init(parent: FilteredCameraView) {
            self.parent = parent
        }

        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            self.currentFrame = pixelBuffer
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

            self.parent.currentFilter.setValue(ciImage, forKey: kCIInputImageKey)
            
            guard let outputImage = self.parent.currentFilter.outputImage,
                  let cgimg = context.createCGImage(outputImage, from: outputImage.extent) else { return }
            
            DispatchQueue.main.async {
                self.parent.processedImage = UIImage(cgImage: cgimg)
            }
        }

        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            guard let photoData = photo.fileDataRepresentation(),
                  let ciImage = CIImage(data: photoData) else { return }

            self.parent.currentFilter.setValue(ciImage, forKey: kCIInputImageKey)

            guard let outputImage = self.parent.currentFilter.outputImage,
                  let cgimg = context.createCGImage(outputImage, from: outputImage.extent) else { return }

            let uiImage = UIImage(cgImage: cgimg)

            // Save the filtered image to the photo library
            UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
        }
    }

    @Binding var currentFilter: CIFilter
    @Binding var processedImage: UIImage?
    @State private var session = AVCaptureSession()
    @State private var previewLayer = AVCaptureVideoPreviewLayer()
    @State private var output = AVCaptureVideoDataOutput()
    @State private var videoQueue = DispatchQueue(label: "videoQueue")
    @State private var photoOutput = AVCapturePhotoOutput()

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        
        setupSession(context: context)

        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.session = session
        viewController.view.layer.addSublayer(previewLayer)
        
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        previewLayer.frame = uiViewController.view.bounds
    }

    private func setupSession(context: Context) {
        session.sessionPreset = .high
        
        guard let camera = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: camera) else { return }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.setSampleBufferDelegate(context.coordinator, queue: videoQueue)
        
        if session.canAddOutput(output) {
            session.addOutput(output)
        }

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
    }

    func applyProcessing() {
        guard let currentFrame = makeCoordinator().currentFrame else {
            print("No current frame available")
            return
        }
        let ciImage = CIImage(cvPixelBuffer: currentFrame)
        currentFilter.setValue(ciImage, forKey: kCIInputImageKey)
        
        guard let outputImage = currentFilter.outputImage,
              let cgimg = CIContext().createCGImage(outputImage, from: outputImage.extent) else {
            print("Failed to create CGImage from output image")
            return
        }
        
        DispatchQueue.main.async {
            print("Applying filter with current settings.")
            self.processedImage = UIImage(cgImage: cgimg)
        }
    }

    func takePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self.makeCoordinator())
    }
}
