//
//  CameraView.swift
//  MyCam
//
//  Created by yeonny on 7/1/24.
//
import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject private var cameraService = CameraService()
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                ZStack {
                    if let filteredImage = cameraService.filteredImage {
                        Image(uiImage: filteredImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    } else {
                        Rectangle()
                            .aspectRatio(4.0 / 3.0, contentMode: .fit)
                            .frame(width: geometry.size.width, height: geometry.size.width * 4 / 3)
                            .background(Color.black)
                    }
                }
            }
            ControlView(cameraService: cameraService)
                .padding(.bottom, 10)
            ZStack{
                Button(action: {
                    cameraService.takePhoto()
                }) {
                    Circle()
                        .stroke(Color.black)
                        .frame(width: 70, height: 70)
                }
                .padding(.top, 10) 
                HStack{
                    Spacer()
                    Button(action: {}, label: {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundColor(.black)
                            .font(.system(size: 20))
                            .padding()
                    })
                    .onLongPressGesture(minimumDuration: 0.1, pressing: { isPressing in
                        cameraService.showOriginal = isPressing
                    }, perform: {})
                }
            }
        }
        .overlay(
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        cameraService.switchCamera()
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .foregroundColor(.white)
                            .font(.system(size: 24))
                    }
                    .padding(.trailing, 10)
                }
                .padding(.top, 50)
                Spacer()
            }
        )
    }
}

