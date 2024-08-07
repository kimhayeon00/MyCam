import SwiftUI

struct ControlView: View {
    @ObservedObject var cameraService: CameraService
   
    var body: some View {
        VStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(controls, id: \.title) { control in
                        Button(action: {
                            if picked == control.title {
                                picked = ""
                                applyFilter(picked: control.title, value: 0.0)
                            } else {
                                // 필터를 선택
                                picked = control.title
                            }
                        }) {
                            Card(title: control.title, imageName: control.imageName, value: getValueForControl(control.title), picked: picked == control.title)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
            
            if picked != "" {
                SliderView(picked: $picked, value: getValueForControl(picked), range: getRangeForControl(picked), onChange: applyFilter)
            }
        }
    }
    
    @State private var picked: String = ""

    private func getValueForControl(_ control: String) -> Binding<Double> {
        switch control {
        case "EXPOSURE":
            return $cameraService.exposureValue
        case "BRILLIANCE":
            return $cameraService.brillianceValue
        case "HIGHLIGHTS":
            return $cameraService.highlightValue
        case "SHADOWS":
            return $cameraService.shadowValue
        case "CONTRAST":
            return $cameraService.contrastValue
        case "BRIGHTNESS":
            return $cameraService.brightnessValue
        case "VIBRANCE":
            return $cameraService.vibranceValue
        case "WARMTH":
            return $cameraService.warmthValue
        default:
            return .constant(0.0)
        }
    }

    private func getRangeForControl(_ control: String) -> ClosedRange<Double> {
        return -100...100
    }
    
    private func applyFilter(picked: String, value: Double) {
        switch picked {
        case "EXPOSURE":
            cameraService.setExposure(value)
        case "BRILLIANCE":
            cameraService.setBrilliance(value)
        case "HIGHLIGHTS":
            cameraService.setHighlight(value)
        case "SHADOWS":
            cameraService.setShadow(value)
        case "CONTRAST":
            cameraService.setContrast(value)
        case "BRIGHTNESS":
            cameraService.setBrightness(value)
        case "VIBRANCE":
            cameraService.setVibrance(value)
        case "WARMTH":
            cameraService.setWarmth(value)
        default:
            break
        }
    }
}

struct SliderView: View {
    @Binding var picked: String
    @Binding var value: Double
    var range: ClosedRange<Double>
    var onChange: (String, Double) -> Void

    var body: some View {
        VStack {
            Text("\(picked)")
                .font(.system(size: 14))
            Slider(value: $value, in: range, onEditingChanged: { _ in
                onChange(picked, value)
            })
            .padding(.horizontal)
        }
    }
}

struct Card: View {
    var title: String
    var imageName: String
    @Binding var value: Double
    var picked: Bool

    var body: some View {
        VStack {
            if picked {
                Circle()
                    .frame(width: 20, height: 20)
                    .padding()
                    .opacity(0)
                    .overlay(
                        Text("\(value, specifier: "%.0f")")
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                    )
            } else {
                Image(systemName: imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .opacity(0.5)
                    .padding()
                    .overlay(
                        Group {
                            if value != 0 {
                                CircularProgressView(progress: value)
                                    .stroke(value > 0 ? Color.blue : Color.black, lineWidth: 2)
                                    .frame(width: 40, height: 40)
                            }
                        }
                    )
            }
        }
        .background(Color.gray.opacity(picked ? 0.2 : 0.0))
        .cornerRadius(60)
    }
}


struct CircularProgressView: Shape {
    var progress: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let startAngle: Angle = .degrees(-90)
        let endAngle: Angle = .degrees(-90 + (progress * 360 / 100.0))

        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY),
                    radius: rect.width / 2,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: progress < 0)

        return path
    }
}

struct Control {
    var title: String
    var imageName: String
}

let controls = [
    Control(title: "EXPOSURE", imageName: "plusminus.circle"),
    Control(title: "BRILLIANCE", imageName: "swirl.circle.righthalf.filled"),
    Control(title: "HIGHLIGHTS", imageName: "circle.lefthalf.striped.horizontal"),
    Control(title: "SHADOWS", imageName: "circle.lefthalf.filled.righthalf.striped.horizontal"),
    Control(title: "CONTRAST", imageName: "circle.lefthalf.filled.inverse"),
    Control(title: "BRIGHTNESS", imageName: "sun.min"),
    Control(title: "VIBRANCE", imageName: "lightspectrum.horizontal"),
    Control(title: "WARMTH", imageName: "thermometer"),
]

struct ControlView_Previews: PreviewProvider {
    static var previews: some View {
        ControlView(cameraService: CameraService())
    }
}
