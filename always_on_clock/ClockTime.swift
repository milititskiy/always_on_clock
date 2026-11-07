import Foundation

enum ClockTimeFormat: String {
    case system
    case twelveHour
    case twentyFourHour
}

struct ClockTime {
    let hour: String
    let minute: String
    let second: String
    let secondNumber: Int
    let period: String?

    var accessibilityLabel: String {
        [hour + ":" + minute, period].compactMap { $0 }.joined(separator: " ")
    }

    init(date: Date, format: ClockTimeFormat, locale: Locale, timeZone: TimeZone, calendar: Calendar) {
        var calendar = calendar
        calendar.timeZone = timeZone
        let hourNumber = calendar.component(.hour, from: date)
        let minuteNumber = calendar.component(.minute, from: date)
        secondNumber = calendar.component(.second, from: date)

        let isTwelveHour: Bool
        switch format {
        case .system:
            let systemFormat = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: locale) ?? ""
            isTwelveHour = systemFormat.contains("h") || systemFormat.contains("K")
        case .twelveHour:
            isTwelveHour = true
        case .twentyFourHour:
            isTwelveHour = false
        }

        let displayedHour = isTwelveHour ? (hourNumber % 12 == 0 ? 12 : hourNumber % 12) : hourNumber
        let numberStyle = IntegerFormatStyle<Int>.number.locale(locale).grouping(.never).precision(.integerLength(2))
        hour = displayedHour.formatted(numberStyle)
        minute = minuteNumber.formatted(numberStyle)
        second = secondNumber.formatted(numberStyle)

        if isTwelveHour {
            let formatter = DateFormatter()
            formatter.locale = locale
            formatter.calendar = calendar
            formatter.timeZone = timeZone
            period = hourNumber < 12 ? formatter.amSymbol : formatter.pmSymbol
        } else {
            period = nil
        }
    }
}
