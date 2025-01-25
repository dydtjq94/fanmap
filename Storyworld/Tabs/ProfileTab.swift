//
//  ProfileTab.swift
//  Storyworld
//
//  Created by peter on 1/8/25.
//

import SwiftUI

struct ProfileTab: View {
    @EnvironmentObject var userService: UserService
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                
                // 유저 프로필 섹션
                if userService.user != nil {
                    UserProfileView()
                } else {
                    ProgressView("Loading...")
                }
                
                // 플레이리스트 섹션
                PlaylistView()
                
                // 컬렉션 섹션
                CollectionView()
            }
            .padding(.horizontal, 16) // 좌우 패딩 적용
            .padding(.bottom, 32) // 하단 패딩 적용
            .padding(.top, 24)
        }
        .background(Color(UIColor(hex:"#121212")))
    }
}
