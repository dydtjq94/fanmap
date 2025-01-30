//
//  DropResultTestView.swift
//  Storyworld
//
//  Created by peter on 1/30/25.
//


import SwiftUI

struct DropResultTestView: View {
    let videoTitle: String
    let closeAction: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8) // 반투명 배경
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text("Drop 결과")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)
                
                Text(videoTitle)
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
                
                Button(action: closeAction) {
                    Text("닫기")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: 200)
                        .background(Color.white)
                        .cornerRadius(10)
                }
            }
            .padding(30)
            .background(Color.gray.opacity(0.9))
            .cornerRadius(15)
            .shadow(radius: 10)
        }
    }
}
