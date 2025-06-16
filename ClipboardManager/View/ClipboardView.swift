//
//  ClipboardView.swift
//  ClipboardManager
//
//  Created by Le Tien Dat on 6/13/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var clipboardManager = ClipboardManager()
    @EnvironmentObject var popoverManager: PopoverManager

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(
                    Array(clipboardManager.clipboardItems),
                    id: \.id
                ) { item in
                    ExpandableTextView(
                        item: item,
                        onCopy: {
                            clipboardManager.copyItem(item)
                        },
                        popoverManager: popoverManager
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
            }
            .padding()
        }
        .overlay(
            Text("No items").opacity(
                clipboardManager.clipboardItems.isEmpty ? 1 : 0)
        )
        .background(Color.gray.opacity(0.2))
        .frame(minWidth: 500, minHeight: 400)
    }
}

struct ExpandableTextView: View {
    let item: ClipboardItem
    let onCopy: () -> Void
    @ObservedObject var popoverManager: PopoverManager

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss dd/MM/yyyy"
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    var body: some View {
        VStack {
            HStack {
                Text(dateFormatter.string(from: item.timestamp))
                    .font(.system(size: 11))
                    .foregroundColor(.gray)

                Spacer(minLength: 10)

                Button("Copy") {
                    onCopy()
                    popoverManager.closePopover()
                }
            }
            switch item.content {
            case .text(let text):
                Text(text)
                    .lineLimit(5)
                    .font(.system(size: 13))
                    .foregroundColor(.black)
                    .textSelection(.enabled)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            case .image(let data):
                if let image = NSImage(data: data) {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .shadow(
                            color: .black.opacity(0.2), radius: 5, x: 0, y: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 200)
    }
}
