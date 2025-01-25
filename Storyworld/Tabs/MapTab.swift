//
//  MapTab.swift
//  Storyworld
//
//  Created by peter on 1/24/25.
//

//
//  MapTab.swift
//  Storyworld
//

import SwiftUI

struct MapTab: View {
    @EnvironmentObject var userService: UserService
    
    var body: some View {
        ZStack {
            MapboxMapView()
                .ignoresSafeArea(.container, edges: .top)
            
            VStack {
                if userService.user != nil {
                    MapTabUserProfileView()
                } else {
                    ProgressView("Loading...")
                }
                Spacer()
            }
            
            VStack{
                Spacer()
                MapTabBottomView()
            }
        }
    }
}

