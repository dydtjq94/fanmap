//
//  UserProfileView.swift
//  Storyworld
//
//  Created by peter on 1/24/25.
//

import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var userService: UserService
    @State private var isEditingNickname = false
    @State private var isEditingBio = false
    @State private var editedNickname = ""
    @State private var editedBio = ""
    
    var body: some View {
        if let user = userService.user {
            HStack(alignment: .center, spacing: 16) {
                // 프로필 이미지 (URL이 없으면 기본 이미지 표시)
                if let profileURL = user.profileImageURL, let url = URL(string: profileURL) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    } placeholder: {
                        ProgressView()
                    }
                } else {
                    Image("default_user_image1")  // 기본 이미지 적용
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                }
                VStack(alignment: .leading) {
                    // 닉네임 수정 버튼
                    Button(action: {
                        UIImpactFeedbackGenerator.trigger(.light)
                        editedNickname = userService.user?.nickname ?? "Guest"
                        isEditingNickname = true
                    }) {
                        Text(userService.user?.nickname ?? "Guest")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.bottom, 2)
                    
                    
                    HStack(spacing: 8) {
                        // 레벨 섹션
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.up.square.fill")
                                .foregroundColor(Color(AppColors.mainColor))
                                .font(.system(size: 12))
                            
                            Text("Lv. \(UserStatusManager.shared.calculateLevel(from: userService.user?.experience ?? 0))")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(UIColor(hex: "#7E7E7E")))
                        }
                        
                        // 수집한 영상 수 섹션
                        HStack(spacing: 2) {
                            Image(systemName: "film.stack.fill")
                                .foregroundColor(Color(AppColors.green1))
                                .font(.system(size: 12))
                            
                            Text("\(userService.user?.collectedVideos.count ?? 0)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(UIColor(hex: "#7E7E7E")))
                        }
                        
                        HStack(spacing: 2) {
                            Image(systemName: "inset.filled.diamond")
                                .foregroundColor(Color(UIColor(hex: "#00FFFF")))
                                .font(.system(size: 12))
                            Text("\(userService.user?.gems ?? 0)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(UIColor(hex: "#7E7E7E")))
                        }
                        
                        HStack(spacing: 2) {
                            Image(systemName: "dollarsign.circle.fill")
                                .foregroundColor(Color(UIColor(hex: "#FFD700")))
                                .font(.system(size: 12))
                            Text("\(userService.user?.balance ?? 0)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(UIColor(hex: "#7E7E7E")))
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom, 4)
                    
                    // 소개글 수정 버튼
                    Button(action: {
                        UIImpactFeedbackGenerator.trigger(.light)
                        editedBio = userService.user?.bio ?? "소개글을 입력하세요"
                        isEditingBio = true
                    }) {
                        Text(userService.user?.bio?.isEmpty == false ? userService.user!.bio! : "소개글을 입력하세요")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(userService.user?.bio?.isEmpty == false ? .gray : .gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .alert("닉네임 수정", isPresented: $isEditingNickname) {
                VStack {
                    TextField("닉네임을 입력하세요", text: $editedNickname)
                        .onChange(of: editedNickname) {
                            // 최대 길이 제한 (모든 문자 포함 12글자)
                            if editedNickname.count > 12 {
                                editedNickname = String(editedNickname.prefix(12))
                            }
                        }
                    
                    HStack {
                        Button("취소", role: .cancel) {
                            isEditingNickname = false
                        }
                        Button("저장") {
                            if var user = userService.user {
                                user.nickname = editedNickname
                                userService.saveUser(user)
                            }
                            isEditingNickname = false
                        }
                    }
                }
            }
            .alert("소개글 수정", isPresented: $isEditingBio) {
                TextField("소개글을 입력하세요", text: $editedBio)
                Button("취소", role: .cancel) {}
                Button("저장") {
                    if var user = userService.user {
                        user.bio = editedBio
                        userService.saveUser(user)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color(UIColor(hex: "#1D1D1D")))
            .cornerRadius(16)
            .shadow(radius: 10)
        } else {
            ProgressView("Loading user data...")
                .padding()
        }
        
    }
}
