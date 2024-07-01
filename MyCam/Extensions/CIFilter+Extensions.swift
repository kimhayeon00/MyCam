//
//  CIFilter+Extensions.swift
//  MyCam
//
//  Created by yeonny on 7/1/24.
//
import CoreImage

extension CIFilter {
    var brightness: Double {
        get {
            return self.value(forKey: kCIInputBrightnessKey) as? Double ?? 0.0
        }
        set {
            self.setValue(newValue, forKey: kCIInputBrightnessKey)
        }
    }

    var contrast: Double {
        get {
            return self.value(forKey: kCIInputContrastKey) as? Double ?? 1.0
        }
        set {
            self.setValue(newValue, forKey: kCIInputContrastKey)
        }
    }

    var saturation: Double {
        get {
            return self.value(forKey: kCIInputSaturationKey) as? Double ?? 1.0
        }
        set {
            self.setValue(newValue, forKey: kCIInputSaturationKey)
        }
    }
}
