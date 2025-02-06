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
                    .frame(width: 63, height:28)
                    .padding(.leading, -4)
            }
            .padding(.top, 24)
            
            Spacer()
            
            VStack{
                
                Image("startImage")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.8)
                    .cornerRadius(10)
                    .clipped()
                
                // ✅ 하단에 텍스트 추가
                Text("세계를 탐험하고 영상 컬렉션을 완성하세요!")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.top, 12)
                
            }
            .padding(.bottom, 24)
            
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
                            // ✅ Firestore에서 데이터 동기화 대기
                            await loginService.waitForDataSync()
                            
                            DispatchQueue.main.async {
                                // 화면 전환 코드가 있다면 여기에 넣어도 됨.
                            }
                            // ✅ 로딩 UI는 3초 더 유지한 후 해제
                            try? await Task.sleep(nanoseconds: 5 * 1_000_000_000)
                            
                            DispatchQueue.main.async {
                                isLoading = false // ✅ 3초 후 로딩 UI 해제
                            }
                        }
                    }
                )
                .frame(height: 50)
                .signInWithAppleButtonStyle(.white)
                .cornerRadius(16)
                .padding(.bottom, 8)
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
            VStack {
                Text(attributedString)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.bottom, 16)
                    .onTapGesture {
                        // 탭 제스처를 감지하여 링크를 열도록 설정
                        if let range = attributedString.range(of: "이용약관"),
                           let url = attributedString[range].link {
                            openURL(url)
                        } else if let range = attributedString.range(of: "개인정보처리방침"),
                                  let url = attributedString[range].link {
                            openURL(url)
                        }
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
    
    private var attributedString: AttributedString {
        var string = AttributedString("로그인 시 이용약관 및 개인정보처리방침에 동의하게 됩니다.")
        if let range = string.range(of: "이용약관") {
            string[range].foregroundColor = .gray // 원하는 색상으로 설정
            string[range].link = URL(string: "https://nmax.notion.site/18c6a17d455480c48f7decd6bc89b802?pvs=4")
        }
        if let range = string.range(of: "개인정보처리방침") {
            string[range].foregroundColor = .gray // 원하는 색상으로 설정
            string[range].link = URL(string: "https://nmax.notion.site/18c6a17d4554809db4d5ca7ee4ba709f?pvs=4")
        }
        return string
    }

    private func openURL(_ url: URL) {
        UIApplication.shared.open(url)
    }
}
