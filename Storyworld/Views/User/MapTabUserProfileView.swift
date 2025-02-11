//
//  MapTopBar.swift
//  Storyworld
//
//  Created by peter on 1/24/25.
//


//
//  MapTopBar.swift
//  Storyworld
//

import SwiftUI
import UIKit

struct MapTabUserProfileView: View {
    @EnvironmentObject var userService: UserService
    @State private var profileImage: UIImage? = nil
    
    var body: some View {
        HStack{
            Spacer() // 왼쪽 공간을 채워서 오른쪽 정렬
            HStack{
                HStack(spacing: 6){
                    // ✅ 로컬에서 캐싱된 이미지 먼저 표시
                    if let image = profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 20, height: 20)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.gray)
                    }
                    
                    Text(userService.user?.nickname ?? "Guest")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.trailing, 16)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.square.fill")
                            .foregroundColor(Color(AppColors.mainColor))
                            .font(.system(size: 12))
                        Text("Lv. \(UserStatusManager.shared.calculateLevel(from: userService.user?.experience ?? 0))")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(UIColor(hex:"#A1A1A1")))
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "inset.filled.diamond")
                            .foregroundColor(Color(UIColor(hex:"#00FFFF")))
                            .font(.system(size: 12))
                        Text("\(userService.user?.gems ?? 0)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(UIColor(hex:"#A1A1A1")))
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(Color(UIColor(hex:"#FFD700")))
                            .font(.system(size: 12))
                        Text("\(userService.user?.balance ?? 0)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(UIColor(hex:"#A1A1A1")))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(UIColor(hex:"#1B1B1B")))
            .cornerRadius(12)
            .padding(.top, 4)
            .padding(.trailing, 12)
        }
        .onAppear {
            userService.loadProfileImage { image in
                self.profileImage = image
            }
        }
        .onChange(of: userService.user?.profileImageURL) {
            userService.loadProfileImage { image in
                self.profileImage = image
            }
        }
    }
}
