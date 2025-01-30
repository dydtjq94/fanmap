//
//  DropResultWithCoinView.swift
//  Storyworld
//
//  Created by peter on 1/27/25.
//


import SwiftUI

struct DropResultWithCoinView: View {
    let video: Video
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
                        HStack{
                            HStack(spacing: 12) {
                                RarityBadgeView(rarity: video.rarity)
                                GenreBadgeView(genre: video.genre)
                            }
                            Spacer()
                            Button(action: {
                                if let url = URL(string: "https://www.youtube.com/watch?v=\(video.videoId)") {
                                    UIApplication.shared.open(url)
                                    UIImpactFeedbackGenerator.trigger(.light)
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
                .padding()
                .background(Color(video.rarity.dropBackgroundColor))
                .cornerRadius(20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                Spacer()
                // Collect 버튼
                Button(action: {
                    closeAction()
                    UIImpactFeedbackGenerator.trigger(.heavy)
                }) {
                    Text("수집하기")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: UIScreen.main.bounds.width * 0.6)  // 화면의 80% 너비로 조정
                        .padding()
                        .background(Color(AppColors.mainColor))
                        .cornerRadius(10)
                }
                .padding(.bottom, 16)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
            }
        }
    }
}
