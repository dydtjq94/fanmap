//
//  resultBg.swift
//  Storyworld
//
//  Created by peter on 2/14/25.
//

import SwiftUI

// 🌟 **Rarity별 카드 내부 배경**
struct RarityCardBackground: View {
    let rarity: VideoRarity
    
    var body: some View {
        switch rarity {
        case .silver:
            SilverCardBackground() // ✅ 실버 카드 배경
        case .gold:
            GoldCardBackground() // ✅ 골드 카드 배경
        case .diamond:
            DiamondCardBackground() // ✅ 다이아몬드 카드 배경
        case .ruby:
            RubyCardBackground() // ✅ 루비 카드 배경
        }
    }
}

// 🌟 **실버 카드 배경 (더 어둡고 무게감 있는 실버)**
struct SilverCardBackground: View {
    var body: some View {
        ZStack {
            // 🌑 더 깊고 차분한 실버 그라데이션
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.gray.opacity(0.6), Color.white.opacity(0.4), Color.gray.opacity(0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blur(radius: 6)
            
            // ✨ **더 은은한 빛 반사 효과**
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.2), // 광택 효과를 낮춤
                    Color.clear
                ]),
                center: .center,
                startRadius: 30,
                endRadius: 220
            )
            .blendMode(.softLight)
        }
    }
}


// 🏆 **골드 카드 배경 (더 어둡고 깊이 있는 느낌)**
struct GoldCardBackground: View {
    var body: some View {
        ZStack {
            // 🌟 깊이 있는 골드 톤
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.5, green: 0.3, blue: 0.0),  // 어두운 금색
                    Color(red: 0.7, green: 0.5, blue: 0.1),  // 중간 금색
                    Color(red: 0.5, green: 0.3, blue: 0.0)   // 다시 어두운 금색
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blur(radius: 6)
            
            // ✨ **더 낮은 광택 효과 (무게감 있는 골드)**
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.2), // 은은한 빛 반사
                    Color.clear
                ]),
                center: .center,
                startRadius: 40,
                endRadius: 250
            )
            .blendMode(.softLight)
        }
    }
}

// 💎 **다이아몬드 카드 배경 (톤 다운 & 더 차분한 느낌)**
struct DiamondCardBackground: View {
    var body: some View {
        ZStack {
            // 🌟 톤 다운된 다이아몬드 블루 계열
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.5), Color.cyan.opacity(0.4), Color.mint.opacity(0.3),
                    Color.blue.opacity(0.5)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blur(radius: 6)
            
            // ✨ **더 차분한 빛 반사 효과**
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.3), // 광택 효과를 살짝 줄임
                    Color.clear
                ]),
                center: .center,
                startRadius: 50,
                endRadius: 250
            )
            .blendMode(.softLight)
            
            // 🌈 **더 차분한 오로라 효과**
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.3), Color.cyan.opacity(0.3), Color.mint.opacity(0.3),
                    Color.blue.opacity(0.3)
                ]),
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .blur(radius: 80)
            .opacity(0.5)
        }
    }
}


// 🔥 **루비 카드 배경 (더 어둡고 깊이 있는 색감)**
struct RubyCardBackground: View {
    var body: some View {
        ZStack {
            // 🌟 어둡고 깊은 루비 컬러
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.2, green: 0.0, blue: 0.0),  // 더 어두운 다크 레드
                    Color(red: 0.4, green: 0.0, blue: 0.0),  // 중간 루비 레드
                    Color(red: 0.5, green: 0.0, blue: 0.0),  // 밝은 루비 레드 (톤 다운)
                    Color(red: 0.4, green: 0.0, blue: 0.0),  // 다시 중간 레드
                    Color(red: 0.2, green: 0.0, blue: 0.0)   // 다시 다크 레드
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blur(radius: 6) // 더 깊은 느낌 추가
            
            // ✨ **더 은은한 빛 반사 효과**
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.2), // 광택을 더 낮춰서 자연스럽게
                    Color.clear
                ]),
                center: .center,
                startRadius: 50,
                endRadius: 250
            )
            .blendMode(.softLight)
            
            // 🔥 **더 차분한 루비 오로라 효과**
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.red.opacity(0.3), Color.pink.opacity(0.2),
                    Color.red.opacity(0.4), Color.purple.opacity(0.2),
                    Color.red.opacity(0.3)
                ]),
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .blur(radius: 80) // 오로라 느낌 유지하되, 더 부드럽게 확산
            .opacity(0.5)
        }
    }
}
