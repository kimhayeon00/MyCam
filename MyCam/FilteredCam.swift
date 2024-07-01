//
//  FilteredCam.swift
//  MyCam
//
//  Created by yeonny on 7/1/24.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct FilteredCameraView: View {
    @State private var currentFilter: CIFilter = CIFilter.sepiaTone()
    @State private var inputImage: UIImage?
    @State private var processedImage: UIImage?

    var body: some View {
        VStack {
            if let processedImage = processedImage {
                Image(uiImage: processedImage)
                    .resizable()
                    .scaledToFit()
            } else {
                CameraView()
                    .edgesIgnoringSafeArea(.all)
            }

            Slider(value: Binding(get: {
                return currentFilter.intensity
            }, set: { (newVal) in
                currentFilter.intensity = newVal
                applyProcessing()
            }), in: 0...1)
                .padding()
        }
        .onAppear(perform: loadImage)
    }

    func loadImage() {
        guard let inputImage = UIImage(named: "example") else { return }
        self.inputImage = inputImage
        let beginImage = CIImage(image: inputImage)
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
        applyProcessing()
    }

    func applyProcessing() {
        let context = CIContext()
        if let outputImage = currentFilter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                let uiImage = UIImage(cgImage: cgimg)
                self.processedImage = uiImage
            }
        }
    }
}

extension CIFilter {
    var intensity: Float {
        get {
            return self.value(forKey: kCIInputIntensityKey) as? Float ?? 0.5
        }
        set {
            self.setValue(newValue, forKey: kCIInputIntensityKey)
        }
    }
}
