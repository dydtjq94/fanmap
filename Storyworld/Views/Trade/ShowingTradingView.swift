//
//  ShowingTradingView.swift
//  Storyworld
//
//  Created by peter on 2/12/25.
//

import SwiftUI

struct ShowingTradingView: View {
    @StateObject private var offerViewModel = TradeOfferViewModel() // 받은 요청 관리
    @StateObject private var tradeViewModel = ManageTradingViewModel() // 내 트레이드 관리
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedTab: String = "received" // ✅ 기본값: 받은 요청
    
    var body: some View {
        NavigationStack {
            VStack {
                // ✅ Segmented Picker (받은 요청 / 내 트레이드)
                Picker("거래 보기", selection: $selectedTab) {
                    Text("받은 요청").tag("received")
                    Text("내 트레이드").tag("myTrades")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 16)
                .onChange(of: selectedTab) { _ in
                    if selectedTab == "myTrades" {
                        tradeViewModel.loadUserTrades() // 내 트레이드 로드
                    } else {
                        offerViewModel.loadReceivedOffers() // 받은 요청 로드
                    }
                }
                
                if selectedTab == "received" {
                    // ✅ 받은 트레이드 요청 리스트
                    receivedTradesView()
                } else {
                    // ✅ 내가 등록한 트레이드 리스트
                    myTradesView()
                }
                
                Spacer()
            }
            .padding(.top, 20)
            .background(Color(UIColor(hex: "#1D1D1D")))
            .onAppear {
                offerViewModel.loadReceivedOffers() // 받은 요청 로드
                tradeViewModel.loadUserTrades() // 내 트레이드 로드
            }
            .navigationTitle("트레이드 관리") // ✅ 타이틀 변경
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        UIImpactFeedbackGenerator.trigger(.light)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.down") // 🔽 닫기 버튼
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
    
    // ✅ 받은 트레이드 요청 UI
    @ViewBuilder
    private func receivedTradesView() -> some View {
        if offerViewModel.offers.isEmpty {
            Text("받은 트레이드 요청이 없습니다.")
                .foregroundColor(.gray)
                .padding(.top, 20)
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(offerViewModel.offers) { offer in
                        OfferItemView(offer: offer, viewModel: offerViewModel)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    // ✅ 내가 등록한 트레이드 UI
    @ViewBuilder
    private func myTradesView() -> some View {
        if tradeViewModel.trades.isEmpty {
            Text("등록된 트레이드가 없습니다.")
                .foregroundColor(.gray)
                .padding(.top, 20)
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(tradeViewModel.trades) { trade in
                        TradeVideoPreviewView(video: trade.video)
                            .overlay(
                                Button(action: {
                                    UIImpactFeedbackGenerator.trigger(.light)
                                    tradeViewModel.cancelTrade(trade: trade) // ✅ 트레이드 취소
                                }) {
                                    Text("등록 취소")
                                        .font(.caption)
                                        .padding(6)
                                        .background(Color.black.opacity(0.2))
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                },
                                alignment: .bottomTrailing
                            )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}
