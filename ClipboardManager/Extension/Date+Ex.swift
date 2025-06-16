//
//  Date+Ex.swift
//  ClipboardManager
//
//  Created by Le Tien Dat on 16/6/25.
//

import Foundation

extension Date {
    private var logDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter
    }

    func formatToString() -> String {
        logDateFormatter.string(from: self)
    }

    static func loadFormatedWithString(dateString: String) -> Self? {
        let formatter = DateFormatter()
        formatter.configFormatLoadStringDate()
        if let date = formatter.date(from: dateString) {
            return date
        }

        return nil
    }
}
