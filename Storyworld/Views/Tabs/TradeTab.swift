//
//  TradeTab.swift
//  Storyworld
//
//  Created by peter on 2/10/25.
//

import SwiftUI

struct TradeTab: View {
    @State private var showingManageTrading = false
    @State private var showingTradingOffers = false
    @StateObject private var tradeViewModel = TradeViewModel() // ✅ ViewModel 추가

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 16) {
                    TradeView(viewModel: tradeViewModel)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 80)
                .padding(.top, 16)
            }
            .refreshable {
                print("🔄 TradeTab 새로고침 실행")
                tradeViewModel.loadTrades()
            }
            .background(Color(UIColor(hex:"#121212")))
            
            .toolbar {
                // 🔔 받은 트레이드 보기 (알림 버튼)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        UIImpactFeedbackGenerator.trigger(.light)
                        showingTradingOffers.toggle()
                    }) {
                        ZStack {
                            Image(systemName: "tray") // 기본 아이콘
                        }
                    }
                }
            }
            
            // ✅ 트레이드 관리 버튼 (하단 고정)
            Button(action: {
                UIImpactFeedbackGenerator.trigger(.light)
                showingManageTrading.toggle()
            }) {
                Text("새 트레이드 등록")
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(.black)
                    .frame(width: 180, height: 48)
                    .background(Color(AppColors.mainColor))
                    .cornerRadius(32)
                    .shadow(radius: 4)
                    .shadow(color: Color(AppColors.mainColor).opacity(0.3), radius: 10, x: 0, y: 0)
            }
            .padding(.bottom, 24)
        }
        // ✅ "트레이드 등록" 버튼 → `ManageTradingView()`
        .sheet(isPresented: $showingManageTrading) {
            ManageTradingView()
        }
        // ✅ "알림(🔔)" 버튼 → `ShowingTradingView()`
        .sheet(isPresented: $showingTradingOffers) {
            ShowingTradingView()
        }
    }
}
