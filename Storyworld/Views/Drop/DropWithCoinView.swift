//
//  DropWithCoinView.swift
//  Storyworld
//
//  Created by peter on 1/27/25.
//

import SwiftUI

struct DropWithCoinView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var backgroundOpacity: Double = 0.0
    @State private var playIcon: String = "play.fill"
    @State private var randomImageNumber: Int = Int.random(in: 1...10)
    @State private var isAnimating: Bool = false
    @State private var timer: Timer?
    @State private var selectedVideo: Video?
    @State private var showDropResultView = false
    @State private var blurOffset: CGSize = .zero
    @State private var imageOffset: CGSize = .zero
    @State private var dropPrice: Int  // 가격 상태 변수 추가
    @State private var cooldownRemainingTime: TimeInterval = 0 // 남은 쿨다운 시간
    @State private var cooldownTimer: Timer?
    
    let circleData: MapCircleService.CircleData
  
    
    init(circleData: MapCircleService.CircleData) {
        self.circleData = circleData
        self._dropPrice = State(initialValue: UserStatusManager.shared.getCoinDeduct(for: circleData.rarity))
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .background(Color.black.opacity(0.4))
                .opacity(backgroundOpacity)
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.13) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            backgroundOpacity = 0.8
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        startDropViewAnimation()
                    }
                }
                .onTapGesture {
                    presentationMode.wrappedValue.dismiss()
                }
            
            VStack(spacing: 20) {
                // 이미지 영역
                ZStack {
                    Image("image\(randomImageNumber)")
                        .resizable()
                        .aspectRatio(320.0 / 180.0, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(10)
                        .clipped()
                        .offset(imageOffset)
                    
                    VisualEffectBlur(style: .light)
                        .cornerRadius(10)
                        .frame(maxWidth: .infinity)
                        .aspectRatio(320.0 / 180.0, contentMode: .fit)
                        .offset(blurOffset)
                    
                    Button(action: {
                        if !isAnimating {
                            startImageAnimation()
                        }
                    }) {
                        Image(systemName: playIcon)
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                
                // 쿨다운 시간이 남아있으면 시간 표시, 아니면 안내 문구
                if cooldownRemainingTime > 0 {
                    Text("쿨다운 남은 시간: \(formatTime(cooldownRemainingTime))")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Text("드롭 주변으로 이동이 필요해요")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                // 희귀도 및 장르 뱃지
                HStack(spacing: 12) {
                    RarityBadgeView(rarity: circleData.rarity)
                    GenreBadgeView(genre: circleData.genre)
                }
                .padding(.top, 32)
                
                // 닫기 버튼
                Button(action: {
                    if !isAnimating {
                        startImageAnimation()
                    }
                }) {
                    Text("지금 바로 열기 ")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black) +
                    Text(Image(systemName: "dollarsign.circle.fill"))
                        .font(.system(size: 16))
                        .foregroundColor(.yellow) +
                    Text(" \(dropPrice)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(AppColors.mainColor))
                .cornerRadius(10)
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.8)  // 화면의 80% 너비로 조정
            .padding(20)
            .background(Color(circleData.rarity.dropBackgroundColor))
            .cornerRadius(20)
            .shadow(radius: 10)
        }
        .onAppear {
            startCooldownTimer()
        }
        .fullScreenCover(isPresented: $showDropResultView) {
            if let video = selectedVideo {
                DropResultWithCoinView(
                    video: video,
                    genre: circleData.genre,
                    rarity: circleData.rarity,
                    closeAction: {
                        showDropResultView = false
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }
    
    private func startCooldownTimer() {
        let currentTime = Date().timeIntervalSince1970
        let elapsedTime = currentTime - (circleData.lastDropTime?.timeIntervalSince1970 ?? 0)
        cooldownRemainingTime = max(circleData.cooldownTime - elapsedTime, 0)
        
        if cooldownRemainingTime > 0 {
            cooldownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                if cooldownRemainingTime > 0 {
                    cooldownRemainingTime -= 1
                } else {
                    cooldownTimer?.invalidate()
                }
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private func startDropViewAnimation() {
        withAnimation(.easeInOut(duration: 0.3)) {
            blurOffset = CGSize(width: -5, height: 3)
            imageOffset = CGSize(width: 5, height: -3)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    }
    
    private func startImageAnimation() {
        playIcon = "pause.fill"
        isAnimating = true
        
        // 1. 위치 복귀 후 애니메이션 시작
        withAnimation(.easeInOut(duration: 0.3)) {
            blurOffset = .zero
            imageOffset = .zero
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            fetchVideosAndAnimate()
        }
    }
    
    let totalDuration: TimeInterval = 3
    let interval: TimeInterval = 0.05
    let imageCount = 11
    
    private func startImageSequenceAnimation() {
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
            
            randomImageNumber += 1
            if randomImageNumber > imageCount {
                randomImageNumber = 1
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
            timer?.invalidate()
            timer = nil
            isAnimating = false
            showDropResult()
        }
    }
    
    private func fetchVideosAndAnimate() {
        CollectionService.shared.fetchUncollectedVideos(for: circleData.genre, rarity: circleData.rarity) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let filteredVideos):
                    guard let video = filteredVideos.randomElement() else {
                        print("⚠️ No videos available")
                        return
                    }
                    
                    // 코인 차감 시도
                    let success = UserService.shared.deductCoins(amount: dropPrice)
                    if success {
                        self.selectedVideo = video
                        CollectionService.shared.saveCollectedVideoWithoutReward(video, amount: dropPrice)
                        startImageSequenceAnimation()
                    } else {
                        print("❌ 코인 부족으로 영상 열기 실패")
                        playIcon = "play.fill"
                        withAnimation(.easeInOut(duration: 0.3)) {
                            blurOffset = CGSize(width: -5, height: 3)
                            imageOffset = CGSize(width: 5, height: -3)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            let generator = UIImpactFeedbackGenerator(style: .heavy)
                            generator.prepare()
                            generator.impactOccurred()
                        }
                        isAnimating = false
                    }
                    
                case .failure(let error):
                    print("❌ 비디오 가져오기 실패: \(error.localizedDescription)")
                    playIcon = "play.fill"
                    withAnimation(.easeInOut(duration: 0.3)) {
                        blurOffset = CGSize(width: -5, height: 3)
                        imageOffset = CGSize(width: 5, height: -3)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        let generator = UIImpactFeedbackGenerator(style: .heavy)
                        generator.prepare()
                        generator.impactOccurred()
                    }
                    isAnimating = false
                }
            }
        }
    }
    
    private func showDropResult() {
        print("🎉 Drop Result Shown")
        showDropResultView = true
    }
}
