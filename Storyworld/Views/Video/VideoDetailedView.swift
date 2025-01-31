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
    @State private var isGlowing = false // ✅ 상태 변수 추가
    
    var body: some View {
        ZStack {
            AsyncImage(url: URL(string: "https://img.youtube.com/vi/\(video.videoId)/mqdefault.jpg")) { image in
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
                    AsyncImage(url: URL(string: "https://img.youtube.com/vi/\(video.videoId)/mqdefault.jpg")) { image in
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
                            .foregroundColor(Color.white)
                        
                        HStack{
                            HStack(spacing: 12) {
                                RarityBadgeView(rarity: rarity)
//                                GenreBadgeView(genre: genre)
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
                .background(RarityCardBackground(rarity: video.rarity))
                .cornerRadius(10)
                .shadow(color: getShadowColor(for: rarity), radius: getShadowRadius(for: rarity), x: 0, y: 0) // ✅ Rarity별 애니메이션 적용
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: getAnimationDuration(for: rarity)).repeatForever(autoreverses: true)) {
                        isGlowing.toggle() // ✅ 어두워졌다 밝아지는 애니메이션 실행
                    }
                }
            }
            .padding(.vertical, 40)
        }
    }
    // 🔥 **Rarity별 그림자 색상 설정**
       func getShadowColor(for rarity: VideoRarity) -> Color {
           switch rarity {
           case .silver:
               return Color.gray.opacity(isGlowing ? 0.3 : 0.1) // 기본적인 은은한 그림자
           case .gold:
               return Color.yellow.opacity(isGlowing ? 0.5 : 0.3) // 황금빛
           case .diamond:
               return Color.blue.opacity(isGlowing ? 1.0 : 0.7) // 푸른빛이 흐르는 느낌
           case .ruby:
               return Color.red.opacity(isGlowing ? 1.0 : 0.7) // 강렬한 붉은빛 (가장 화려함)
           }
       }

       // 💡 **Rarity별 그림자 크기 설정**
       func getShadowRadius(for rarity: VideoRarity) -> CGFloat {
           switch rarity {
           case .silver:
               return isGlowing ? 10 : 5  // 기본적인 그림자
           case .gold:
               return isGlowing ? 25 : 20  // 살짝 더 커진 황금빛
           case .diamond:
               return isGlowing ? 50 : 30  // 다이아몬드 반짝이는 느낌
           case .ruby:
               return isGlowing ? 50 : 30  // 루비가 가장 강렬한 효과 (최대 그림자)
           }
       }

       // ⏳ **Rarity별 애니메이션 속도 설정**
       func getAnimationDuration(for rarity: VideoRarity) -> Double {
           switch rarity {
           case .silver:
               return 2.0 // 차분한 애니메이션
           case .gold:
               return 3.0 // 약간 더 빠르게 변화
           case .diamond:
               return 3.0 // 빠르고 부드러운 반짝임
           case .ruby:
               return 3.0 // 가장 빠르고 강렬한 반짝임
           }
       }
}
