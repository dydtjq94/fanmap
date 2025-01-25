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

struct MapTabUserProfileView: View {
    @EnvironmentObject var userService: UserService

    var body: some View {
        HStack{
            HStack(spacing: 6){
                if let profileURL = userService.user?.profileImageURL, let url = URL(string: profileURL) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                            .scaledToFill()
                            .frame(width: 16, height: 16)
                            .clipShape(Circle())
                    } placeholder: {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundColor(.gray)
                    }
                } else {
                    Image("default_user_image1")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .clipShape(Circle())
                }

                Text(userService.user?.nickname ?? "Guest")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.trailing, 16)

            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.square.fill")
                        .foregroundColor(Color(UIColor(hex:"#A1A1A1")))
                        .font(.system(size: 12))
                    Text("Lv.\(calculateLevel(from: userService.user?.experience ?? 0))")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(UIColor(hex:"#A1A1A1")))
                }

                HStack(spacing: 4) {
                    Image(systemName: "film.stack.fill")
                        .foregroundColor(Color(UIColor(hex:"#A1A1A1")))
                        .font(.system(size: 12))
                    Text("\(userService.user?.collectedVideos.count ?? 0)")
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

                HStack(spacing: 4) {
                    Image(systemName: "diamond.fill")
                        .foregroundColor(Color(UIColor(hex:"#00FFFF")))
                        .font(.system(size: 12))
                    Text("\(userService.user?.gems ?? 0)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(UIColor(hex:"#A1A1A1")))
                }
            }
        }
        .padding()
        .background(Color(UIColor(hex:"#1B1B1B")))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }
    
    private func calculateLevel(from experience: Int) -> Int {
        return 1 + (experience / 1000)  // 1000 경험치당 1레벨
    }
}
