//
//  StartView.swift
//  Storyworld
//
//  Created by peter on 1/29/25.
//

import SwiftUI
import AuthenticationServices

struct StartView: View {
    @AppStorage("isUserInitialized") private var isUserInitialized = false
    @StateObject private var userService = UserService.shared
    @StateObject private var loginService = LoginService.shared
    
    @State private var randomImageNumber: Int = Int.random(in: 1...10) // 랜덤 이미지
    @State private var isLoading: Bool = false // 로그인 진행 상태
    
    @State private var playIcon: String = "play.fill"
    @State private var blurOffset: CGSize = .zero
    @State private var imageOffset: CGSize = .zero
    
    var body: some View {
        
        VStack {
            // ✅ 로고 애니메이션 적용
            HStack {
                Image("logo")
                    .resizable()
                    .frame(width: 28, height: 28)
                
                Image("logo_korean")
                    .resizable()
                    .frame(width: 100, height:28)
                    .padding(.leading, -2)
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        startDropViewAnimation() // ✅ 화면이 나타날 때 이미지에 애니메이션 적용
                    }
                }
                
                // ✅ 하단에 텍스트 추가
                Text("Welcome to Storyworld!")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.top, 12)
            }
            
            Spacer()
            
            // ✅ Apple 로그인 버튼 (로딩 상태 적용)
            ZStack {
                SignInWithAppleButton(
                    .signIn,
                    onRequest: { request in
                        UIImpactFeedbackGenerator.trigger(.heavy) // ✅ 버튼 클릭 시 햅틱 피드백 추가
                        isLoading = true // ✅ 로그인 시작
                        loginService.handleAppleSignInRequest(request)
                    },
                    onCompletion: { result in
                        loginService.handleAppleSignInCompletion(result)

                        Task {
                            // ✅ Firestore에서 데이터 동기화가 끝날 때까지 로딩 유지
                            await loginService.waitForDataSync()
                            DispatchQueue.main.async {
                                isLoading = false // ✅ 데이터 로딩 후 로딩 종료
                            }
                        }
                    }
                )
                .frame(height: 50)
                .signInWithAppleButtonStyle(.white)
                .cornerRadius(16)
                .padding(.vertical, 16)
                .disabled(isLoading) // ✅ 로딩 중에는 버튼 비활성화
                .opacity(isLoading ? 0.0 : 1.0) // ✅ 로딩 중에는 버튼 투명도 조절

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                        .background(Color.black.opacity(0.3)) // ✅ 로딩 배경 추가
                        .frame(width: 50, height: 50) // ✅ 크기 고정
                        .cornerRadius(25)
                }
            }


        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .background(Color(AppColors.mainBgColor))
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
}
