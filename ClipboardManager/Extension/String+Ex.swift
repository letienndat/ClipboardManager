//
//  String+Ex.swift
//  ClipboardManager
//
//  Created by Le Tien Dat on 16/6/25.
//

import Foundation

extension String {
    var fourCharCodeValue: UInt32 {
        var result: UInt32 = 0
        let chars = self.utf8.prefix(4).map { UInt8($0) }
        for (index, char) in chars.enumerated() {
            result = result | (UInt32(char) << (8 * (3 - index)))
        }
        return result
    }
}
