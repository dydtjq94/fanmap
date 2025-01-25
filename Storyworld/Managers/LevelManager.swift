//
//  LevelManager.swift
//  Storyworld
//
//  Created by peter on 1/25/25.
//


import Foundation

class LevelManager {
    static let shared = LevelManager()
    
    private init() {}
    
    // 경험치를 바탕으로 레벨 계산
    func calculateLevel(from experience: Int) -> Int {
        return 1 + (experience / 1000)  // 1000 경험치당 1레벨
    }
}
