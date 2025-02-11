//
//  TradeTab.swift
//  Storyworld
//
//  Created by peter on 2/10/25.
//


import SwiftUI

struct TradeTab: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                NavigationView {
                    TradeView()
                }
            }
            .padding(.horizontal, 16) // 좌우 패딩 적용
            .padding(.bottom, 32) // 하단 패딩 적용
            .padding(.top, 16)
        }
        .background(Color(UIColor(hex:"#121212")))
    }
}
