//
//  View+itemCard.swift
//  ClipboardManager
//
//  Created by Le Tien Dat on 6/18/25.
//

import SwiftUI

extension View {
    func itemCard() -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
