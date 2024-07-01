//
//  CameraView.swift
//  MyCam
//
//  Created by yeonny on 7/1/24.
//

import SwiftUI
import AVFoundation
import Photos

struct CameraView: UIViewControllerRepresentable {
    class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {
        var parent: CameraView
        
        init(parent: CameraView) {
            self.parent = parent
        }
        
        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            guard let imageData = photo.fileDataRepresentation() else { return }
            guard let image = UIImage(data: imageData) else { return }
            
            // 사진 앨범에 저장
            savePhotoToAlbum(image)
        }
        
        func savePhotoToAlbum(_ image: UIImage) {
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAsset(from: image)
                    }) { success, error in
                        if let error = error {
                            print("Error saving photo to album: \(error)")
                        } else {
                            print("Photo saved successfully to album")
                        }
                    }
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    let session = AVCaptureSession()

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        
        session.sessionPreset = .photo
        
        guard let device = AVCaptureDevice.default(for: .video) else {
            return controller
        }
        
        guard let input = try? AVCaptureDeviceInput(device: device) else {
            return controller
        }
        
        session.addInput(input)
        
        let output = AVCapturePhotoOutput()
        session.addOutput(output)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = UIScreen.main.bounds
        previewLayer.videoGravity = .resizeAspect
        
        controller.view.layer.addSublayer(previewLayer)
        
        let captureButton = UIButton(frame: CGRect(x: UIScreen.main.bounds.midX - 35, y: UIScreen.main.bounds.height - 120, width: 70, height: 70))
        captureButton.backgroundColor = .white
        captureButton.layer.cornerRadius = 35
        captureButton.addTarget(context.coordinator, action: #selector(context.coordinator.takePhoto), for: .touchUpInside)
        
        controller.view.addSubview(captureButton)
        controller.view.backgroundColor = .black
        
        session.startRunning()
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

@objc extension CameraView.Coordinator {
    func takePhoto() {
        if let output = (self.parent.session.outputs.first as? AVCapturePhotoOutput) {
            let settings = AVCapturePhotoSettings()
            output.capturePhoto(with: settings, delegate: self)
        }
    }
}
