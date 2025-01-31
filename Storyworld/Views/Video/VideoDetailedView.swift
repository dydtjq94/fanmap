//
//  VideoDetailedView.swift
//  Storyworld
//
//  Created by peter on 1/21/25.
//

import SwiftUI

struct VideoDetailedView: View {
    let video: Video
    let genre: VideoGenre
    let rarity: VideoRarity
    @Environment(\.presentationMode) var presentationMode
    
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
            
            VStack(spacing: 20) {
                VStack(spacing: 20) {
                    AsyncImage(url: URL(string: video.thumbnailURL)) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 330)
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
                        
                        HStack{
                            HStack(spacing: 12) {
                                RarityBadgeView(rarity: rarity)
                                GenreBadgeView(genre: genre)
                            }
                            Spacer()
                            Button(action: {
                                UIImpactFeedbackGenerator.trigger(.light)
                                if let url = URL(string: "https://www.youtube.com/watch?v=\(video.videoId)") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Image("youtube-logo") // ▶️ 아이콘 변경 (재생 버튼 느낌)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60)
                            }
                            .buttonStyle(PlainButtonStyle()) // ✅ 버튼 스타일 기본으로 설정
                        }
                        .padding(.top, 16)
                    }
                    .frame(width: 330, alignment: .leading)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
                .background(Color(rarity.dropBackgroundColor))
                .cornerRadius(10)
            }
            .padding(.vertical, 40)
        }
    }
}
