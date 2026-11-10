import Foundation

enum ClockLuminanceMode {
    case manual
    case day
    case night

    var title: String {
        switch self {
        case .manual: return "MANUAL"
        case .day: return "DAY"
        case .night: return "NIGHT"
        }
    }
}

struct ClockLuminanceSchedule {
    let enabled: Bool
    let nightStart: Int
    let dayStart: Int
    let manualLuminance: Double
    let dayLuminance: Double
    let nightLuminance: Double

    func mode(at date: Date, calendar: Calendar, timeZone: TimeZone) -> ClockLuminanceMode {
        guard enabled else { return .manual }
        var calendar = calendar
        calendar.timeZone = timeZone
        let current = calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
        let isNight: Bool
        if nightStart < dayStart {
            isNight = current >= nightStart && current < dayStart
        } else if nightStart > dayStart {
            isNight = current >= nightStart || current < dayStart
        } else {
            isNight = false
        }
        return isNight ? .night : .day
    }

    func luminance(for mode: ClockLuminanceMode) -> Double {
        switch mode {
        case .manual: return manualLuminance
        case .day: return dayLuminance
        case .night: return nightLuminance
        }
    }
}
