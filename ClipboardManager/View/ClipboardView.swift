//
//  ClipboardView.swift
//  ClipboardManager
//
//  Created by Le Tien Dat on 6/13/25.
//

import SwiftUI

// swiftlint:disable closure_body_length
struct ContentView: View {
    @StateObject private var clipboardManager = ClipboardManager()
    @EnvironmentObject var popoverManager: PopoverManager
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertIsError = false

    var body: some View {
        VStack {
            HStack(spacing: 10) {
                Text("Total: \(clipboardManager.clipboardItems.count) items")

                Menu("Import JSON") {
                    Button("Overwrite") {
                        let result = clipboardManager.importJSON()
                        switch result {
                        case .success(let message):
                            alertMessage = message
                            alertIsError = false
                        case .failure(let message):
                            alertMessage = message
                            alertIsError = true
                        }
                        showAlert = true
                    }
                    Button("Merge") {
                        let result = clipboardManager.importJSON(
                            shouldMerge: true)
                        switch result {
                        case .success(let message):
                            alertMessage = message
                            alertIsError = false
                        case .failure(let message):
                            alertMessage = message
                            alertIsError = true
                        }
                        showAlert = true
                    }
                }

                Button("Export JSON") {
                    let result = clipboardManager.exportJSON()
                    switch result {
                    case .success(let message):
                        alertMessage = message
                        alertIsError = false
                    case .failure(let message):
                        alertMessage = message
                        alertIsError = true
                    }
                    showAlert = true
                }

                Button("Refresh") {
                    let result = clipboardManager.loadItems()
                    switch result {
                    case .success(let message):
                        alertMessage = message
                        alertIsError = false
                    case .failure(let message):
                        alertMessage = message
                        alertIsError = true
                    }
                    showAlert = true
                }
            }
            .padding(.trailing)

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
                        .shadow(
                            color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                }
            }
            .overlay(
                Text("No items").opacity(
                    clipboardManager.clipboardItems.isEmpty ? 1 : 0)
            )
            .frame(minWidth: 500, minHeight: 400)
            .padding(.bottom)
        }
        .padding([.top, .leading])
        .background(Color.gray.opacity(0.2))
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(
                    alertIsError ? "Error" : "Success"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    showAlert = false
                }
            )
        }
    }
}
// swiftlint:enable closure_body_length

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
