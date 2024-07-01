//
//  ContentView.swift
//  MyCam
//
//  Created by yeonny on 7/1/24.
//
import SwiftUI

struct ContentView: View {
    var body: some View {
        CameraView()
            .edgesIgnoringSafeArea(.all)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

