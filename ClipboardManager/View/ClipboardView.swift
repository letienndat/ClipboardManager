//
//  ClipboardView.swift
//  viewModel
//
//  Created by Le Tien Dat on 6/13/25.
//

import SwiftUI

struct ClipboardView: View {
    @EnvironmentObject var popoverManager: PopoverManager
    @ObservedObject var viewModel: ClipboardViewModel
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertIsError = false
    @State private var scrollToTopTrigger = false

    var body: some View {
        VStack {
            headerView
            scrollableContentView
        }
        .padding([.top, .leading])
        .background(Color.gray.opacity(0.2))
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertIsError ? "Error" : "Success"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    showAlert = false
                }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .clipboardOperationResult)) { notification in
            if let result = notification.object as? FileOperationResult {
                handleResult(result)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .loadItemsFromClipboard)) { notification in
            if let result = notification.object as? FileOperationResult {
                handleResult(result)
                if case .success = result {
                    scrollToTopTrigger.toggle()
                }
            }
        }
    }

    private var headerView: some View {
        HStack(spacing: 10) {
            Text("Total: \(viewModel.clipboardItems.count) items (max: \(AppConst.numberOfItems))")
            importJSONMenu
            Button("Export JSON") { viewModel.exportJSON() }
            Button("Refresh") { viewModel.loadItems() }
        }
        .padding(.trailing)
    }

    private var importJSONMenu: some View {
        Menu("Import JSON") {
            Button("Overwrite") { viewModel.importJSON() }
            Button("Merge") { viewModel.importJSON(shouldMerge: true) }
        }
    }

    private var scrollableContentView: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    itemsListView()
                }
                .padding(.trailing)
            }
            .overlay(emptyStateView() )
            .frame(minWidth: 500, minHeight: 400)
            .padding(.bottom)
            .onChange(of: scrollToTopTrigger) { _ in
                scrollToTop(scrollProxy)
            }
            .onAppear {
                scrollToTopTrigger.toggle()
            }
        }
    }

    private func itemsListView() -> some View {
        ForEach(Array(viewModel.clipboardItems), id: \.id) { item in
            ClipboardItemView(
                item: item,
                onCopy: { viewModel.copyItem(item) },
                onDelete: {
                    viewModel.deleteItem(id: item.id)
                },
                popoverManager: popoverManager
            )
            .itemCard()
            .id(item.id)
        }
    }

    private func emptyStateView() -> some View {
        Text("No items")
            .opacity(viewModel.clipboardItems.isEmpty ? 1 : 0)
    }

    private func scrollToTop(_ scrollProxy: ScrollViewProxy) {
        if let first = viewModel.clipboardItems.first {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                scrollProxy.scrollTo(first.id, anchor: .top)
            }
        }
    }

    private func handleResult(_ result: FileOperationResult) {
        switch result {
        case .success(let message):
            alertMessage = message
            alertIsError = false
            Log.log(message)
        case .failure(let message):
            alertMessage = message
            alertIsError = true
            Log.log(message)
        }
        showAlert = true
    }
}

struct ClipboardItemView: View {
    let item: ClipboardItem
    let onCopy: () -> Void
    let onDelete: () -> Void
    @ObservedObject var popoverManager: PopoverManager

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
                        onDelete()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.red)
                }
            }

            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.3))

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
