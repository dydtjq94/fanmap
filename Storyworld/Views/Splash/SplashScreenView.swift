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
            Color(AppColors.mainBgColor).ignoresSafeArea()

            
                Image("logo")
                    .resizable()
                    .frame(width: 240, height: 240)
                    .foregroundColor(.white)
                    .scaleEffect(scaleEffect)
                    .opacity(1.0)
        }
    }
}
