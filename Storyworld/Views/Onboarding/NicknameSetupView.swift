//
//  NicknameSetupView.swift
//  Storyworld
//
//  Created by peter on 1/29/25.
//


import SwiftUI

struct NicknameSetupView: View {
    @State private var nickname = ""
    @StateObject private var userService = UserService.shared
    @AppStorage("isUserInitialized") private var isUserInitialized = false
    
    var body: some View {
        VStack {
            Spacer()
            
            Text("닉네임을 설정하세요")
                .font(.title)
                .fontWeight(.bold)
            
            TextField("닉네임 입력", text: $nickname)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button(action: {
                if !nickname.isEmpty {
                    userService.updateNickname(nickname) // ✅ 닉네임 업데이트
                    isUserInitialized = true // ✅ 유저 설정 완료 → 앱 진입 가능
                }
            }) {
                Text("다음")
                    .font(.title2)
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .onAppear {
            DispatchQueue.main.async {
                if userService.user == nil {
                    userService.createNewUser() // ✅ 이제 필요할 때만 실행됨
                }
            }
        }
    }
}
