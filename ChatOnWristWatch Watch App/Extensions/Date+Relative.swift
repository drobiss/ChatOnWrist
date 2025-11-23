//
//  Date+Relative.swift
//  ChatOnWristWatch Watch App
//
//  Created by Codex on 06.11.2025.
//

import Foundation

extension Date {
    var relativeTimeString: String {
        RelativeDateTimeFormatter.watchFormatter.localizedString(for: self, relativeTo: Date())
    }
}

extension RelativeDateTimeFormatter {
    static let watchFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
}
