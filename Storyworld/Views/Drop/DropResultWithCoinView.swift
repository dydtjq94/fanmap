//
//  DropResultWithCoinView.swift
//  Storyworld
//
//  Created by peter on 1/27/25.
//


import SwiftUI

struct DropResultWithCoinView: View {
    let video: Video
    let genre: VideoGenre
    let rarity: VideoRarity
    let closeAction: () -> Void
    
    var body: some View {
        ZStack {
            AsyncImage(url: URL(string: video.thumbnailURL)) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                    .blur(radius: 10)
                    .overlay(Color.black.opacity(0.8))
            } placeholder: {
                Color.black.opacity(0.8)
            }
            VStack{
                Spacer()
                VStack(spacing: 20) {
                    AsyncImage(url: URL(string: video.thumbnailURL)) { image in
                        image
                            .resizable()
                            .frame(width: 330, height: 185)
                            .cornerRadius(10)
                            .shadow(radius: 10)
                    } placeholder: {
                        Color.gray.frame(width: 330, height: 185)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(video.title)
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                        
                        Text(Channel.getChannelName(by: video.channelId))
                            .font(.headline)
                            .foregroundColor(Color.gray)
                        
                        HStack(spacing: 12) {
                            RarityBadgeView(rarity: rarity)
                            GenreBadgeView(genre: genre)
                        }
                    }
                    .frame(width: 330, alignment: .leading)
                }
                .padding()
                .background(Color(rarity.dropBackgroundColor))
                .cornerRadius(20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                Spacer()
                // Collect 버튼
                Button(action: closeAction) {
                    Text("Collect")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color(UIColor(hex: "#F8483B")))
                        .cornerRadius(10)
                        .padding(.horizontal, 40)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
                // 애니메이션 효과
            }
        }
    }
}
