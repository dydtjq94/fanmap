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
                    .padding(.vertical, 16)
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
                
            
                HStack(spacing: 16){
                    Button(action: {
                        UIImpactFeedbackGenerator.trigger(.heavy)
                    }) {
                        ZStack{
                            Circle()
                                .frame(width: 36, height: 40)
                                .foregroundColor(.gray)
                            Image(systemName: "square.and.arrow.up.circle.fill")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(Color(AppColors.btnSubBgColor))
                        }
                    }
                    
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
                        
                        ZStack{
                            Circle()
                                .frame(width: 36, height: 36)
                                .foregroundColor(.gray)
                            Image(systemName: "play.rectangle.on.rectangle.circle.fill")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(Color(AppColors.btnSubBgColor))
                        }
                    }
                }
                .padding(.bottom, 16)
            }
        }
    }
    
    // MARK: - 거래 등록 함수
    func createTrade() {
        guard let ownerId = UserService.shared.user?.id else { return }
        let collectedVideo = CollectedVideo(
            id: video.videoId,
            video: video,
            collectedDate: Date(),
            tradeStatus: .available,
            isFavorite: false,
            ownerId: ownerId
        )
        
        TradeService.shared.createTrade(for: collectedVideo) { success in
            if success {
                print("✅ 거래 등록 완료!")
                // 등록 성공 시 화면 닫기
                closeAction()
            } else {
                print("❌ 거래 등록 실패...")
            }
        }
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

// 🌟 **Rarity별 카드 내부 배경**
struct RarityCardBackground: View {
    let rarity: VideoRarity
    
    var body: some View {
        switch rarity {
        case .silver:
            SilverCardBackground() // ✅ 실버 카드 배경
        case .gold:
            GoldCardBackground() // ✅ 골드 카드 배경
        case .diamond:
            DiamondCardBackground() // ✅ 다이아몬드 카드 배경
        case .ruby:
            RubyCardBackground() // ✅ 루비 카드 배경
        }
    }
}

// 🌟 **실버 카드 배경 (더 어둡고 무게감 있는 실버)**
struct SilverCardBackground: View {
    var body: some View {
        ZStack {
            // 🌑 더 깊고 차분한 실버 그라데이션
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.gray.opacity(0.6), Color.white.opacity(0.4), Color.gray.opacity(0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blur(radius: 6)
            
            // ✨ **더 은은한 빛 반사 효과**
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.2), // 광택 효과를 낮춤
                    Color.clear
                ]),
                center: .center,
                startRadius: 30,
                endRadius: 220
            )
            .blendMode(.softLight)
        }
    }
}


// 🏆 **골드 카드 배경 (더 어둡고 깊이 있는 느낌)**
struct GoldCardBackground: View {
    var body: some View {
        ZStack {
            // 🌟 깊이 있는 골드 톤
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.5, green: 0.3, blue: 0.0),  // 어두운 금색
                    Color(red: 0.7, green: 0.5, blue: 0.1),  // 중간 금색
                    Color(red: 0.5, green: 0.3, blue: 0.0)   // 다시 어두운 금색
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blur(radius: 6)
            
            // ✨ **더 낮은 광택 효과 (무게감 있는 골드)**
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.2), // 은은한 빛 반사
                    Color.clear
                ]),
                center: .center,
                startRadius: 40,
                endRadius: 250
            )
            .blendMode(.softLight)
        }
    }
}

// 💎 **다이아몬드 카드 배경 (톤 다운 & 더 차분한 느낌)**
struct DiamondCardBackground: View {
    var body: some View {
        ZStack {
            // 🌟 톤 다운된 다이아몬드 블루 계열
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.5), Color.cyan.opacity(0.4), Color.mint.opacity(0.3),
                    Color.blue.opacity(0.5)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blur(radius: 6)
            
            // ✨ **더 차분한 빛 반사 효과**
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.3), // 광택 효과를 살짝 줄임
                    Color.clear
                ]),
                center: .center,
                startRadius: 50,
                endRadius: 250
            )
            .blendMode(.softLight)
            
            // 🌈 **더 차분한 오로라 효과**
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.3), Color.cyan.opacity(0.3), Color.mint.opacity(0.3),
                    Color.blue.opacity(0.3)
                ]),
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .blur(radius: 80)
            .opacity(0.5)
        }
    }
}


// 🔥 **루비 카드 배경 (더 어둡고 깊이 있는 색감)**
struct RubyCardBackground: View {
    var body: some View {
        ZStack {
            // 🌟 어둡고 깊은 루비 컬러
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.2, green: 0.0, blue: 0.0),  // 더 어두운 다크 레드
                    Color(red: 0.4, green: 0.0, blue: 0.0),  // 중간 루비 레드
                    Color(red: 0.5, green: 0.0, blue: 0.0),  // 밝은 루비 레드 (톤 다운)
                    Color(red: 0.4, green: 0.0, blue: 0.0),  // 다시 중간 레드
                    Color(red: 0.2, green: 0.0, blue: 0.0)   // 다시 다크 레드
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blur(radius: 6) // 더 깊은 느낌 추가
            
            // ✨ **더 은은한 빛 반사 효과**
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.2), // 광택을 더 낮춰서 자연스럽게
                    Color.clear
                ]),
                center: .center,
                startRadius: 50,
                endRadius: 250
            )
            .blendMode(.softLight)
            
            // 🔥 **더 차분한 루비 오로라 효과**
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.red.opacity(0.3), Color.pink.opacity(0.2),
                    Color.red.opacity(0.4), Color.purple.opacity(0.2),
                    Color.red.opacity(0.3)
                ]),
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .blur(radius: 80) // 오로라 느낌 유지하되, 더 부드럽게 확산
            .opacity(0.5)
        }
    }
}
