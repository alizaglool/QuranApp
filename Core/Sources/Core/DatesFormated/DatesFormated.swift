import SwiftUI

public enum DateFormat: String, Codable {
    // Basic Formats
    case short = "E. d-MM-yy"  // Mon. 2-10-24
    case fullDate = "EEEE, MMM d, yyyy"  // Monday, Oct 2, 2024
    case numeric = "MM/dd/yyyy"  // 10/02/2024
    case numericDash = "d-MM-yy"
    case compactNumeric = "dd/MM/yy"  // 02/10/24
    case dayMonthYear = "d MMM yyyy"  // 2 Oct 2024
    case monthDayYear = "MMM d, yyyy"  // Oct 2, 2024
    case yearMonthDay = "yyyy-MM-dd"  // 2024-10-02

    // Time Formats
    case timeOnly = "hh:mm a"  // 08:30 AM
    case time24Hour = "HH:mm"  // 20:30
    case fullTimeWithSeconds = "HH:mm:ss"  // 20:30:45
    case timeWithZone = "HH:mm zzz"  // 20:30 GMT
    case hourMinuteSecond = "HH:mm:ss.SSS"  // 20:30:45.123

    // ISO Formats
    case iso8601 = "yyyy-MM-dd'T'HH:mm:ssZ"  // 2024-10-02T08:30:00Z
    case isoYearMonth = "yyyy-MM"  // 2024-10

    // Weekday and Month
    case weekdayOnly = "EEEE"  // Monday
    case shortWeekday = "E"  // Mon
    case monthOnly = "MMMM"  // October
    case shortMonthOnly = "MMM"  // Oct

    // Custom Formats
    case yearOnly = "yyyy"  // 2024
    case monthDay = "MMM d"  // Oct 2
    case dayOnly = "d"  // 2
    case weekOfYear = "'Week' w, yyyy"  // Week 40, 2024
    case dayOfYear = "'Day' D, yyyy"  // Day 275, 2024
    case custom = "yyyy/MM/dd"  // 2024/10/02

    // Combination Formats
    case fullDateWithTime = "EEEE, MMM d, yyyy hh:mm a"  // Monday, Oct 2, 2024 08:30 AM
    case shortDateWithTime = "MM/dd/yyyy HH:mm"  // 10/02/2024 20:30
    case compactDateTime = "d MMM, HH:mm"  // 2 Oct, 20:30
    case fullDateTimeWithSeconds = "dd-MM-yyyy HH:mm:ss a"  // 2024-10-02 20:30:45

    // Extended Formats
    case yearMonthDayCompact = "yyyyMMdd"  // 20241002
    case weekdayAndDate = "EEEE, d MMM"  // Monday, 2 Oct
    case monthYear = "MMMM yyyy"  // October 2024
    case monthDayCompact = "MM/dd"  // 10/02
    case amPmIndicator = "a"  // AM / PM
    case quarterYear = "'Q'Q yyyy"  // Q4 2024
    case fullDateWithOrdinal = "EEEE, d'th' MMM yyyy"  // Monday, 2nd Oct 2024
}

public struct DateFormatStyle: FormatStyle, Equatable{
    private static var cachedFormatters: [String: DateFormatter] = [:]
    private static let lock = NSLock()  // Thread-safe access to the cache

    public typealias FormatInput = Date
    public typealias FormatOutput = String

    public var dateFormat: DateFormat
    // Default initializer with a default format
    public init(dateFormat: DateFormat = .short) {
        self.dateFormat = dateFormat
    }

    // Formatting function
    public func format(_ value: Date) -> String {
        let formatter: DateFormatter
        Self.lock.lock()
        if let cachedFormatter = Self.cachedFormatters[dateFormat.rawValue] {
            formatter = cachedFormatter
        } else {
            formatter = DateFormatter()
            formatter.dateFormat = dateFormat.rawValue
            Self.cachedFormatters[dateFormat.rawValue] = formatter
        }
        Self.lock.unlock()
        return formatter.string(from: value)
    }
}
extension Date {
    func toString(format: DateFormat) -> String {
        return DateFormatStyle(dateFormat: format).format(self)
    }
}

extension String {
    func toDate(format: DateFormat) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = format.rawValue
        return formatter.date(from: self) ?? Date()
    }
}

public extension FormatStyle where Self == DateFormatStyle {
    static func customDate(_ format: DateFormat = .short) -> DateFormatStyle {
        return DateFormatStyle(dateFormat: format)
    }
}
