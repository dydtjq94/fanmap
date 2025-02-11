//
//  CollectionAllViewModel.swift
//  Storyworld
//
//  Created by peter on 1/21/25.
//

import Foundation
import Combine

class CollectionAllViewModel: ObservableObject {
    @Published var collectedVideos: [CollectedVideo] = []
    @Published var isLoading: Bool = false
    private let collectionService = CollectionService.shared
    private var currentPage = 0
    private let pageSize = 20
    
    init() {
        loadInitialVideos()
    }
    
    // 초기 데이터 로드 (CollectionService에서 가져오기)
    func loadInitialVideos() {
        DispatchQueue.global().async {
            let videos = self.collectionService.fetchAllVideos()
            let uniqueVideos = Array(Set(videos)).sorted {
                $0.collectedDate > $1.collectedDate
            }
            
            DispatchQueue.main.async {
                self.collectedVideos = uniqueVideos
            }
        }
    }
    
    // 추가 데이터 로드 (페이징)
    func loadMoreVideos() {
        guard !isLoading, hasMoreVideos() else { return }
        isLoading = true
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            let videos = self.collectionService.fetchAllVideos()
            let uniqueVideos = Array(Set(videos)).sorted {
                $0.collectedDate > $1.collectedDate
            }
            
            let start = self.collectedVideos.count
            let end = min(start + self.pageSize, uniqueVideos.count)
            
            DispatchQueue.main.async {
                self.collectedVideos.append(contentsOf: uniqueVideos[start..<end])
                self.isLoading = false
            }
        }
    }
    
    // 더 가져올 영상이 있는지 확인
    func hasMoreVideos() -> Bool {
        let totalVideos = collectionService.fetchAllVideos().count
        return collectedVideos.count < totalVideos
    }
}
