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
    @State private var scrollToTopTrigger = false

    var body: some View {
        VStack {
            HStack(spacing: 10) {
                Text("Total: \(clipboardManager.clipboardItems.count) items (max: \(AppConst.numberOfItems))")

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
                        scrollToTopTrigger.toggle()
                    case .failure(let message):
                        alertMessage = message
                        alertIsError = true
                    }
                    showAlert = true
                }
            }
            .padding(.trailing)

            ScrollViewReader { scrollProxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(clipboardManager.clipboardItems), id: \.id) { item in
                            ExpandableTextView(
                                item: item,
                                onCopy: {
                                    clipboardManager.copyItem(item)
                                },
                                onDelete: {
                                    let result = clipboardManager.deleteItem(id: item.id)
                                    switch result {
                                    case .success(let message):
                                        alertMessage = message
                                        alertIsError = false
                                    case .failure(let message):
                                        alertMessage = message
                                        alertIsError = true
                                    }
                                    showAlert = true
                                    popoverManager.closePopover()
                                },
                                popoverManager: popoverManager
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                            .id(item.id)
                        }
                    }
                    .padding(.trailing)
                }
                .overlay(
                    Text("No items")
                        .opacity(clipboardManager.clipboardItems.isEmpty ? 1 : 0)
                )
                .frame(minWidth: 500, minHeight: 400)
                .padding(.bottom)
                .onChange(of: scrollToTopTrigger) { _ in
                    if let first = clipboardManager.clipboardItems.first {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            scrollProxy.scrollTo(first.id, anchor: .top)
                        }
                    }
                }
                .onAppear {
                    self.scrollToTopTrigger.toggle()
                }
            }
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
    let onDelete: () -> Void
    @ObservedObject var popoverManager: PopoverManager
    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack {
            HStack {
                Text(item.timestamp.formatToString())
                    .font(.system(size: 11))
                    .foregroundColor(.gray)

                Spacer(minLength: 10)

                HStack(spacing: 3) {
                    Button("Copy") {
                        onCopy()
                        popoverManager.closePopover()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.blue)

                    Button("Remove") {
                        showDeleteConfirmation = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.red)
                    .alert(isPresented: $showDeleteConfirmation) {
                        Alert(
                            title: Text("Confirm Delete"),
                            message: Text("Are you sure you want to delete this item?"),
                            primaryButton: .destructive(Text("Delete")) {
                                onDelete()
                            },
                            secondaryButton: .cancel()
                        )
                    }
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
