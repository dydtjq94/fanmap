//
//  TradeTab.swift
//  Storyworld
//
//  Created by peter on 2/7/25.
//

import SwiftUI

struct TradeTab: View {
    @StateObject private var viewModel = TradeViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack {
                    Text("Trade View")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                    
                    if viewModel.listings.isEmpty {
                        Text("No available trades")
                            .foregroundColor(.gray)
                    } else {
                        ScrollView {
                            ForEach(viewModel.listings) { listing in
                                VStack(alignment: .leading) {
                                    Text(listing.video.title)
                                        .foregroundColor(.white)
                                        .font(.headline)
                                    Text("Owner: \(listing.ownerId)")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(8)
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadAvailableListings()
                }
            }
        }
    }
}
