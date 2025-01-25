//
//  DateFormatterUtility.swift
//  Storyworld
//
//  Created by peter on 1/16/25.
//

import Foundation

struct DateFormatterUtility {
    static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    // 날짜 문자열을 Date로 변환 (nil 처리 포함)
    static func dateOrDefault(from iso8601String: String, defaultDate: Date = Date()) -> Date {
        return iso8601Formatter.date(from: iso8601String) ?? defaultDate
    }
}
