//
//  DropViewPart.swift
//  Storyworld
//
//  Created by peter on 1/27/25.
//

import SwiftUI

struct DropViewPart: View {
    var onPlayButtonTapped: (() -> Void)?
    
    // 애니메이션 상태 변수
    @State private var blurOffset: CGSize = .zero
    @State private var imageOffset: CGSize = .zero
    @State private var playIcon: String = "play.fill"  // 초기 아이콘 설정
    @State private var randomImageNumber: Int = Int.random(in: 1...10)
    @State private var isAnimating: Bool = false
    @State private var timer: Timer?
    // 드롭 결과 뷰를 표시할 상태 변수
    @State private var showDropResultView = false
    @State private var selectedVideo: Video?
    
    let totalDuration: TimeInterval = 3
    let interval: TimeInterval = 0.1
    let imageCount = 11
    
    let genre: VideoGenre
    let rarity: VideoRarity
    
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
                .shadow(radius: 10)
            
            // Drop Image View (썸네일 이미지)
            Image("image\(randomImageNumber)")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 330, height: 185)
                .cornerRadius(10)
                .clipped()
                .offset(imageOffset)  // 이미지 애니메이션 적용
            
            // 블러 효과 뷰 (이미지 위에 위치)
            VisualEffectBlur(style: .light)
                .cornerRadius(10)
                .frame(width: 330, height: 185)
                .offset(blurOffset)  // 블러 뷰 애니메이션 적용
            
            // Play Button (SF Symbol)
            Button(action: {
                if !isAnimating {
                    onPlayButtonTapped?()
                    startImageAnimation()  // 버튼 클릭 시 애니메이션 시작
                }
            }) {
                Image(systemName: playIcon)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 330, height: 185)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                startDropViewAnimation()  // 뷰가 나타날 때 애니메이션 실행
            }
        }
        .fullScreenCover(isPresented: $showDropResultView) {
            if let video = selectedVideo {
                DropResultView(
                    video: video,
                    genre: genre,
                    rarity: rarity,
                    closeAction: { showDropResultView = false }
                )
            }
        }
    }
    
    // 애니메이션 로직 (블러뷰는 왼쪽 하단, 이미지뷰는 오른쪽 상단)
    private func startDropViewAnimation() {
        withAnimation(.easeInOut(duration: 0.3)) {
            blurOffset = CGSize(width: -5, height: 3)  // 블러 뷰 왼쪽 하단 이동
            imageOffset = CGSize(width: 5, height: -3) // 이미지 오른쪽 상단 이동
        }
        
        // 햅틱 피드백 추가
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    }
    
    // 플레이 버튼 클릭 시 애니메이션 및 아이콘 변경 후 이미지 변경
    private func startImageAnimation() {
        playIcon = "pause.fill"  // 아이콘을 일시 정지로 변경
        isAnimating = true
        
        // 1. 원래 위치로 복귀
        withAnimation(.easeInOut(duration: 0.3)) {
            blurOffset = .zero   // 블러뷰 원래 위치로 복귀
            imageOffset = .zero  // 이미지 원래 위치로 복귀
        }
        
        // 2. 복귀 후 이미지 변경 시작 (0.3초 후 실행)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            startImageSequenceAnimation()
        }
    }
    
    // 이미지 시퀀스 애니메이션
    private func startImageSequenceAnimation() {
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
            
            randomImageNumber += 1
            if randomImageNumber > imageCount {
                randomImageNumber = 1
            }
        }
        
        // 3초 후 타이머 종료 및 결과 표시
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
            timer?.invalidate()
            timer = nil
            playIcon = "play.fill"
            isAnimating = false
            showDropResult()
        }
    }
    
    private func fetchVideosAndAnimate() {
        CollectionService.shared.fetchUncollectedVideos(for: genre, rarity: rarity) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let filteredVideos):
                    guard let video = filteredVideos.randomElement() else {
                        print("⚠️ No videos available")
                        return
                    }
                    self.selectedVideo = video
                    CollectionService.shared.saveCollectedVideo(video)
                    startImageAnimation()
                case .failure(let error):
                    print("❌ 비디오 가져오기 실패: \(error.localizedDescription)")
                }
            }
        }
    }
    
    
    // 드롭 결과 표시
    private func showDropResult() {
        print("🎉 Drop Result Shown")
        showDropResultView = true
    }
}
