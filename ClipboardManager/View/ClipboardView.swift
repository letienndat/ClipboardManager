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
                    Array(clipboardManager.clipboardItems.enumerated()),
                    id: \.offset
                ) { _, item in
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
            Text("No items yet").opacity(
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

    var body: some View {
        HStack(spacing: 5) {
            if let text = item.content as? String {
                Text(text)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if let image = item.content as? NSImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        maxWidth: .infinity, maxHeight: 300, alignment: .leading
                    )
            }

            Spacer()
            VStack {
                Button("Copy") {
                    onCopy()
                    popoverManager.closePopover()
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
    }
}
