//
//  ClipboardView.swift
//  ClipboardManager
//
//  Created by Le Tien Dat on 6/13/25.
//

import SwiftUI
import Carbon
import ApplicationServices

struct ContentView: View {
    @StateObject private var clipboardManager = ClipboardManager()
    
    var body: some View {
        VStack {
            Text("Clipboard History")
                .font(.title)
                .padding()
            
            List {
                ForEach(Array(clipboardManager.clipboardItems.enumerated()), id: \.offset) { index, item in
                    HStack {
                        Text(item)
                            .lineLimit(1)
                        Spacer()
                        Button("Copy") {
                            clipboardManager.copyItem(item)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .overlay(Text("No items yet").opacity(clipboardManager.clipboardItems.isEmpty ? 1 : 0))
        }
        .frame(minWidth: 400, minHeight: 300)
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
