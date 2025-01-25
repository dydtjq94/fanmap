//
//  CollectionViewModel.swift
//  Storyworld
//
//  Created by peter on 1/21/25.
//

import SwiftUI

class CollectionViewModel: ObservableObject {
    @Published var collectedVideos: [CollectedVideo] = []
    private let collectionService = CollectionService.shared
    
    func loadVideos() {
        let videos = collectionService.fetchAllVideos()
        // 중복 제거 및 최신 수집된 순서대로 정렬
        let uniqueVideos = Array(Set(videos)).sorted {
            $0.collectedDate > $1.collectedDate
        }
        collectedVideos = uniqueVideos
        print("✅ 수집된 영상 불러오기 완료: \(collectedVideos.count)개")
    }
}
