//
//  FilterControlView.swift
//  MyCam
//
//  Created by yeonny on 7/1/24.
//

import SwiftUI
import CoreImage

struct FilterControlView: View {
    @Binding var currentFilter: CIFilter
    var applyProcessing: () -> Void

    @State private var brightness: Double = 0 {
        didSet {
            print("Brightness changed to \(brightness)")
        }
    }
    @State private var contrast: Double = 1 {
        didSet {
            print("Contrast changed to \(contrast)")
        }
    }
    @State private var saturation: Double = 1 {
        didSet {
            print("Saturation changed to \(saturation)")
        }
    }

    var body: some View {
        VStack {
            Text("Brightness")
            Slider(value: $brightness, in: -1...1, step: 0.1)
                .padding()
                .onChange(of: brightness) { newValue in
                    print("Brightness slider changed to \(newValue)")
                    currentFilter.setValue(newValue, forKey: kCIInputBrightnessKey)
                    applyProcessing()
                }

            Text("Contrast")
            Slider(value: $contrast, in: 0...2, step: 0.1)
                .padding()
                .onChange(of: contrast) { newValue in
                    print("Contrast slider changed to \(newValue)")
                    currentFilter.setValue(newValue, forKey: kCIInputContrastKey)
                    applyProcessing()
                }

            Text("Saturation")
            Slider(value: $saturation, in: 0...2, step: 0.1)
                .padding()
                .onChange(of: saturation) { newValue in
                    print("Saturation slider changed to \(newValue)")
                    currentFilter.setValue(newValue, forKey: kCIInputSaturationKey)
                    applyProcessing()
                }
        }
        .background(Color.black.opacity(0.7))
        .cornerRadius(10)
        .padding()
    }
}
