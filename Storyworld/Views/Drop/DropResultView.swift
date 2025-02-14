//
//  DropResultWithCoinView.swift
//  Storyworld
//
//  Created by peter on 1/27/25.
//


import SwiftUI

struct DropResultView: View {
    let video: Video
    let closeAction: () -> Void
    @State private var isGlowing = false // ✅ 상태 변수 추가
    @State private var coinSellValue: Int = 0
    
    var body: some View {
        ZStack {
            // 📌 배경 (블러 처리된 영상 + 오로라 효과 적용)
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
            
            VStack {
                Button(action: {
                    UIImpactFeedbackGenerator.trigger(.heavy)
                    CollectionService.shared.sellCollectedVideo(video, coinAmount: coinSellValue) { success in
                           if success {
                               closeAction() // ✅ 판매 성공 시 창 닫기
                           } else {
                               print("❌ 영상 판매 실패")
                           }
                       }
                }) {
                    HStack(spacing: 2) {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(Color(UIColor(hex: "#FFD700")))
                            .font(.system(size: 14))
                        Text("\(coinSellValue)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(UIColor(hex: "#7E7E7E")))
                        Text("에 판매")
                            .font(.system(size: 14))
                            .foregroundColor(Color(UIColor(hex: "#7E7E7E")))
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color(AppColors.btnSubBgColor))
                }
                .cornerRadius(20)
                .padding(.top, 8)
                .onAppear {
                    coinSellValue = UserStatusManager.shared.getCoinSell(for: video.rarity)  // ✅ 한 번만 가져오도록 변경
                }
                
                Spacer()
                
                VStack(spacing: 20) {
                    AsyncImage(url: URL(string: "https://img.youtube.com/vi/\(video.videoId)/mqdefault.jpg")) { image in
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
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                        
                        HStack(spacing: 4) {
                            Image(VideoChannel.getChannelImageName(by: video.channelId)) // 🔥 채널 프로필 이미지 사용
                                .resizable()
                                .scaledToFill()
                                .frame(width: 20, height: 20)
                                .clipShape(Circle()) // 🔥 원형으로 변환
                            
                            Text(VideoChannel.getChannelName(by: video.channelId))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color.white)
                                .padding(.leading, 2)
                        }
                        .padding(.top, 4)

                        
                        HStack {
                            HStack(spacing: 12) {
                                RarityBadgeView(rarity: video.rarity)
                            }
                            Spacer()
                            Button(action: {
                                UIImpactFeedbackGenerator.trigger(.light)
                                if let url = URL(string: "https://www.youtube.com/watch?v=\(video.videoId)") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Image("youtube-logo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.top, 16)
                    }
                    .frame(width: 330, alignment: .leading)
                }
                .padding()
                .background(RarityCardBackground(rarity: video.rarity)) // ✅ 등급별 카드 배경 적용
                .cornerRadius(20)
                .shadow(color: getShadowColor(for: video.rarity), radius: getShadowRadius(for: video.rarity), x: 0, y: 0) // ✅ Rarity별 애니메이션 적용
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: getAnimationDuration(for: video.rarity)).repeatForever(autoreverses: true)) {
                        isGlowing.toggle() // ✅ 어두워졌다 밝아지는 애니메이션 실행
                    }
                    playHapticPattern(for: video.rarity)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                
                Spacer()
                
            
                HStack(spacing: 8){
                    // 2) 수집하기 버튼 (기존)
                    Button(action: {
                        UIImpactFeedbackGenerator.trigger(.heavy)
                        closeAction()
                    }) {
                        Text("수집하기")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 200)
                            .padding()
                            .background(Color(AppColors.mainColor))
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        UIImpactFeedbackGenerator.trigger(.heavy)
                        createTrade()
                    }) {
                        
                        Text("트레이드")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(AppColors.mainColor))
                            .frame(width: 80)
                            .padding()
                            .cornerRadius(10)
                            .overlay( // ✅ 테두리 추가
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(AppColors.mainColor), lineWidth: 1.5) // ✅ 테두리 색상 및 두께 설정
                            )
                    }
                }
                .padding(.bottom, 16)
            }
        }
    }
    
    func createTrade() {
        TradeService.shared.createTrade(video: video) { result in
            switch result {
            case .success(let tradeDocId):
                print("✅ Trade 생성 성공: \(tradeDocId)")
                // 필요하다면 Alert나 UI 업데이트
            case .failure(let error):
                print("❌ Trade 생성 실패: \(error.localizedDescription)")
            }
        }
        closeAction()
    }

    func playHapticPattern(for rarity: VideoRarity) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        
        let repeatCount: Int
        
        switch rarity {
        case .silver:
            repeatCount = 5
        case .gold:
            repeatCount = 5
        case .diamond:
            repeatCount = 20
        case .ruby:
            repeatCount = 20
        }
        
        for i in 0..<repeatCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + (0.025 * Double(i))) {
                generator.impactOccurred()
            }
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
