//
//  SplashScreenView.swift
//  Storyworld
//
//  Created by peter on 1/29/25.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var opacity = 0.0
    @State private var scaleEffect = 0.8

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                Image(systemName: "play.circle.fill")
                    .resizable()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.white)
                    .scaleEffect(scaleEffect)
                    .opacity(opacity)
                    .animation(.easeInOut(duration: 1.5), value: opacity)

                Spacer().frame(height: 20)

                Text("Storyworld")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .opacity(opacity)
                    .animation(.easeInOut(duration: 1.5), value: opacity)
            }
        }
        .onAppear {
            withAnimation {
                opacity = 1.0
                scaleEffect = 1.2
            }
        }
    }
}
