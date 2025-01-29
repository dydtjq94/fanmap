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
    @State private var navigateToNicknameSetup = false // ✅ 닉네임 설정으로 이동 플래그 추가

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                Image(systemName: "play.circle.fill")
                    .resizable()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.white)
                
                Text("Storyworld")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()

                NavigationLink(destination: NicknameSetupView(), isActive: $navigateToNicknameSetup) {
                    EmptyView() // ✅ 버튼으로 네비게이션을 직접 컨트롤
                }

                Button(action: {
                    userService.createNewUser() // ✅ "시작하기" 버튼을 누르면 새로운 유저 생성
                    navigateToNicknameSetup = true // ✅ 닉네임 설정 화면으로 이동
                }) {
                    Text("시작하기")
                        .font(.title2)
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                        .padding(.horizontal, 40)
                }

                Spacer()
            }
        }
    }
}
