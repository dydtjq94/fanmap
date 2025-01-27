//
//  userStatusManager.swift
//  Storyworld
//
//  Created by peter on 1/25/25.
//

import Foundation

class UserStatusManager {
    static let shared = UserStatusManager()
    private init() {}

    // 경험치 필요량 계산 (레벨업 난이도 증가)
    func experienceRequired(for level: Int) -> Int {
        let baseXP = 500  // 기본 경험치
        return Int(Double(baseXP) * pow(Double(level), 1.3))
    }

    // 현재 경험치 기반 레벨 계산 (시작 레벨 1 보장)
    func calculateLevel(from experience: Int) -> Int {
        var level = 1
        while experience >= experienceRequired(for: level) {
            level += 1
        }
        return level
    }

    // 경험치 보상 계산
    func getExperienceReward(for rarity: VideoRarity) -> Int {
        switch rarity {
        case .silver:
            return 25
        case .gold:
            return 100
        case .diamond:
            return 400
        case .ruby:
            return 1000
        }
    }

    // 코인 보상 계산 (랜덤 값 반환)
    func getCoinReward(for rarity: VideoRarity) -> Int {
        switch rarity {
        case .silver:
            return Int.random(in: 5...15)
        case .gold:
            return Int.random(in: 50...150)
        case .diamond:
            return Int.random(in: 400...600)
        case .ruby:
            return Int.random(in: 1800...2200)
        }
    }
    
    func getCoinDeduct(for rarity: VideoRarity) -> Int {
        switch rarity {
        case .silver:
            return Int.random(in: 100...300)
        case .gold:
            return Int.random(in: 1000...2000)
        case .diamond:
            return Int.random(in: 10000...20000)
        case .ruby:
            return Int.random(in: 50000...100000)
        }
    }
}
