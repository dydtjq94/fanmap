//
//  TradeView.swift
//  Storyworld
//
//  Created by peter on 2/25/25.
//

import SwiftUI

struct TradeView: View {
    @ObservedObject var viewModel = TradeViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            let grouped = Dictionary(grouping: viewModel.trades, by: { $0.ownerId })
            
            // 각 ownerId별로 섹션 구성
            ForEach(grouped.keys.sorted(), id: \.self) { ownerId in
                VStack(alignment: .leading, spacing: 8) {
                    ownerHeaderView(ownerId: ownerId) // 🔥 유저 정보 헤더
                        .padding(.bottom, 8)
                    
                    // 🔥 각 사용자의 TradeItemView 렌더링
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(grouped[ownerId] ?? []) { trade in
                            TradeItemView(trade: trade)
                        }
                    }
                    .padding(.bottom, 16)
                    
                    let user = viewModel.userMap[ownerId]
                    if let memo = user?.tradeMemo, !memo.isEmpty {
                        Text("메모: \(memo)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.gray)
                            .lineSpacing(4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color(UIColor(hex: "#1D1D1D")))
                .cornerRadius(16)
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            viewModel.loadTrades() // 트레이드 로드 호출
        }
    }
    
    @ViewBuilder
     private func ownerHeaderView(ownerId: String) -> some View {
         // 해당 ownerId에 맞는 사용자 정보를 가져옵니다.
         if let user = viewModel.userMap[ownerId] {
             HStack(spacing: 8) {
                 // 프로필 (예: AsyncImage)
                 if let urlStr = user.profileImageURL,
                    let url = URL(string: urlStr) {
                     AsyncImage(url: url) { phase in
                         switch phase {
                         case .empty:
                             ProgressView()
                                 .frame(width: 24, height: 24)
                         case .success(let image):
                             image
                                 .resizable()
                                 .scaledToFill()
                                 .frame(width: 24, height: 24)
                                 .clipShape(Circle())
                         case .failure(_):
                             Image(systemName: "person.crop.circle.badge.exclamationmark")
                                 .resizable()
                                 .frame(width: 24, height: 24)
                                 .foregroundColor(.gray)
                         @unknown default:
                             EmptyView()
                                 .frame(width: 24, height: 24)
                         }
                     }
                 } else {
                     Image(systemName: "person.crop.circle.fill")
                         .resizable()
                         .frame(width: 24, height: 24)
                         .foregroundColor(.gray)
                 }
                 
                 // 닉네임
                 VStack(alignment: .leading, spacing: 2) {
                     Text(user.nickname)
                         .font(.system(size: 16, weight: .black))
                         .foregroundColor(.white)
                 }
             }
         } else {
             // 아직 로딩 안 됨
             Text("Owner: \(ownerId)")
                 .font(.headline)
                 .foregroundColor(.white)
         }
     }
}
