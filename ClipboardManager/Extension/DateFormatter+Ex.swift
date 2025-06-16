//
//  DateFormatter+Ex.swift
//  ClipboardManager
//
//  Created by Le Tien Dat on 16/6/25.
//

import Foundation

extension DateFormatter {
    func configFormatLoadStringDate() {
        self.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        self.timeZone = TimeZone.current
    }
}
