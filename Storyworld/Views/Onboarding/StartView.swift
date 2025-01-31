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
    @State private var isButtonDisabled: Bool = false // ✅ 버튼 비활성화 상태
    @State private var timer: Timer?
    @State private var playIcon: String = "play.fill"
    @State private var blurOffset: CGSize = .zero
    @State private var imageOffset: CGSize = .zero

    var body: some View {
        VStack {
            // ✅ 로고 애니메이션 적용
            HStack {
                Image("logo")
                    .resizable()
                    .frame(width: 24, height: 24)
                
                Image("logo_korean")
                    .resizable()
                    .frame(width: 56, height:28)
                    .padding(.leading, -6)
            }
            .padding(.top, 24)
            
            Spacer()
            
            VStack {
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

                    }) {
                        Image(systemName: playIcon)
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: UIScreen.main.bounds.width * 0.8)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        startDropViewAnimation() // ✅ 화면이 나타날 때 이미지에 애니메이션 적용
                    }
                }
                
                // ✅ 하단에 텍스트 추가
                Text("Chimchakmap For 한국인  By 개청자")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.top, 12)
            }
            
            Spacer()
            
            // ✅ 시작 버튼 (애니메이션 후 화면 전환)
            Button(action: {
                if !isButtonDisabled { // ✅ 버튼이 이미 눌린 상태면 동작 안 함
                    isButtonDisabled = true // ✅ 버튼 비활성화
                    startFullSequenceAndNavigate()
                    UIImpactFeedbackGenerator.trigger(.heavy)
                }
            }) {
                Text("영상 수집 시작하기")
                    .font(.system(size: 18, weight: .bold))
                    .bold()
                    .padding()
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.8)
                    .background(Color(AppColors.mainColor))
                    .foregroundColor(.black)
                    .cornerRadius(10)
                    .padding(.vertical, 16)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color(AppColors.mainBgColor))
    }
    
    // ✅ 전체 애니메이션 실행 후 화면 이동
    private func startFullSequenceAndNavigate() {
        startImageAnimation()

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            userService.createNewUser()
            isUserInitialized = true
        }
    }
    
    // ✅ 초기 애니메이션 (이미지와 블러 효과)
    private func startDropViewAnimation() {
        withAnimation(.easeInOut(duration: 0.3)) {
            blurOffset = CGSize(width: -5, height: 3)
            imageOffset = CGSize(width: 5, height: -3)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            UIImpactFeedbackGenerator.trigger(.heavy)
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
            UIImpactFeedbackGenerator.trigger(.light)
            
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
