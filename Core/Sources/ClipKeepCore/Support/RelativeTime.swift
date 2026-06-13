import Foundation

public enum RelativeTime {
    public static func string(for date: Date, now: Date) -> String {
        let seconds = max(0, now.timeIntervalSince(date))
        switch seconds {
        case ..<60:    return "now"
        case ..<3600:  return "\(Int(seconds / 60))m"
        case ..<86400: return "\(Int(seconds / 3600))h"
        default:       return "\(Int(seconds / 86400))d"
        }
    }
}
