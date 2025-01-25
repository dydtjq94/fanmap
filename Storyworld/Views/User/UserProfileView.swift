//
//  UserProfileView.swift
//  Storyworld
//
//  Created by peter on 1/24/25.
//

import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var userService: UserService

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
                    // 닉네임
                    Text(user.nickname)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.bottom, 2)

                    HStack(spacing: 12) {
                        // 레벨 섹션
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.square.fill")
                                .foregroundColor(Color(UIColor(hex: "#7E7E7E")))
                                .font(.system(size: 14))

                            Text("Lv.\(LevelManager.shared.calculateLevel(from: user.experience))")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(UIColor(hex: "#7E7E7E")))
                        }

                        // 수집한 영상 수 섹션
                        HStack(spacing: 4) {
                            Image(systemName: "film.stack.fill")
                                .foregroundColor(Color(UIColor(hex: "#7E7E7E")))
                                .font(.system(size: 14))

                            Text("\(user.collectedVideos.count)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(UIColor(hex: "#7E7E7E")))
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "diamond.fill")
                                .foregroundColor(Color(UIColor(hex: "#00FFFF")))
                                .font(.system(size: 14))
                            Text("\(user.gems)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(UIColor(hex: "#7E7E7E")))
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "dollarsign.circle.fill")
                                .foregroundColor(Color(UIColor(hex: "#FFD700")))
                                .font(.system(size: 14))
                            Text("\(user.balance)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(UIColor(hex: "#7E7E7E")))
                        }

                        Spacer()
                    }
                    .padding(.bottom, 4)

                    // 소개글
                    Text(user.bio?.isEmpty == false ? user.bio! : "소개글을 작성하세요")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(user.bio?.isEmpty == false ? .gray : .red)
                        .multilineTextAlignment(.leading)
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
