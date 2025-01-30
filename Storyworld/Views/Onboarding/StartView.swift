//
//  StartView.swift
//  Storyworld
//
//  Created by peter on 1/29/25.
//

import SwiftUI

struct StartView: View {
    @AppStorage("isUserInitialized") private var isUserInitialized = false
    @StateObject private var userService = UserService.shared
    
    @State private var randomImageNumber: Int = Int.random(in: 1...10) // 랜덤 이미지
    @State private var isAnimating: Bool = false
    @State private var timer: Timer?
    @State private var playIcon: String = "play.fill"
    @State private var blurOffset: CGSize = .zero
    @State private var imageOffset: CGSize = .zero
    
    var body: some View {
        VStack {
            // ✅ 로고 애니메이션 적용
            HStack{
                Image("logo")
                    .resizable()
                    .frame(width: 36, height: 36)
                
                Text("침착맵")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white.opacity(1.0)) // 살짝 연한 색으로 스타일링
            }
            .padding(.top, 24)
            Spacer()
            VStack{
                // ✅ 이미지 애니메이션 영역
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
                .frame(maxWidth: UIScreen.main.bounds.width * 0.8)  // 화면의 80% 너비로 조정
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        startDropViewAnimation() // ✅ 화면이 나타날 때 이미지에 애니메이션 적용
                    }
                }
                
                // ✅ 하단에 텍스트 추가
                Text("For 한국인,  By 개청자,  Of 침싸개")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8)) // 살짝 연한 색으로 스타일링
                    .padding(.top, 12) // 위쪽 여백 추가
            }
            Spacer()
            
            // ✅ 시작 버튼
            
            Button(action: {
                userService.createNewUser() // ✅ "Guest" 유저 생성
                isUserInitialized = true // ✅ 닉네임 설정 없이 바로 앱 진입
            }) {
                Text("영상 수집 시작하기")
                    .font(.system(size: 20, weight: .bold))
                    .bold()
                    .padding()
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.8)  // 화면의 80% 너비로 조정
                    .background(Color(AppColors.mainColor))
                    .foregroundColor(.black)
                    .cornerRadius(20)
                    .padding(.vertical, 16)
            }
            
        }
        .frame(maxWidth: .infinity)
        .background(Color(AppColors.mainBgColor))
    }
    
    // ✅ 초기 애니메이션 (이미지와 블러 효과)
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
    
    // ✅ 이미지 전환 애니메이션
    private func startImageAnimation() {
        playIcon = "pause.fill"
        isAnimating = true
        
        withAnimation(.easeInOut(duration: 0.3)) {
            blurOffset = .zero
            imageOffset = .zero
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            startImageSequenceAnimation()
        }
    }
    
    let totalDuration: TimeInterval = 3
    let interval: TimeInterval = 0.1
    let imageCount = 11
    
    // ✅ 이미지 연속 애니메이션
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
            playIcon = "play.fill"
        }
    }
}
