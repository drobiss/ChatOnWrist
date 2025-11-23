import Foundation

extension Date {
    var relativeTimeString: String {
        RelativeDateTimeFormatter.iOSFormatter.localizedString(for: self, relativeTo: Date())
    }
}

extension RelativeDateTimeFormatter {
    static let iOSFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
}



