//
//  DropDataService.swift
//  Storyworld
//
//  Created by peter on 1/27/25.
//

import Foundation
import CoreLocation

class DropDataService {
    static let shared = DropDataService()
    private let key = "droppedCircles"

    func saveDrop(circle: MapCircleService.CircleData) {
        var savedDrops = loadDrops()
        if let index = savedDrops.firstIndex(where: { $0.id == circle.id }) {
            savedDrops[index].lastDropTime = Date()
        } else {
            var updatedCircle = circle
            updatedCircle.lastDropTime = Date()
            savedDrops.append(updatedCircle)
        }

        if let encoded = try? JSONEncoder().encode(savedDrops) {
            UserDefaults.standard.set(encoded, forKey: key)
            print("✅ 드롭 정보 저장 완료")
        }
    }

    func loadDrops() -> [MapCircleService.CircleData] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let savedDrops = try? JSONDecoder().decode([MapCircleService.CircleData].self, from: data) else {
            return []
        }
        return savedDrops
    }

    func hasCooldownPassed(for circle: MapCircleService.CircleData) -> Bool {
        guard let lastDrop = circle.lastDropTime else {
            return true  // 한 번도 드롭되지 않음
        }
        return Date().timeIntervalSince(lastDrop) > circle.cooldownTime
    }
}
