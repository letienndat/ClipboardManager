//
//  NSImage+Ex.swift
//  ClipboardManager
//
//  Created by Le Tien Dat on 17/6/25.
//

import AppKit
import Foundation

extension NSImage {
    func resizedToFit(maxDimension: CGFloat = 1_000) -> NSImage? {
        let originalSize = self.size
        let maxOriginalDimension = max(originalSize.width, originalSize.height)

        guard maxOriginalDimension > maxDimension else {
            return self
        }

        let scale = maxDimension / maxOriginalDimension
        let newSize = NSSize(
            width: originalSize.width * scale,
            height: originalSize.height * scale
        )

        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        self.draw(
            in: NSRect(origin: .zero, size: newSize),
            from: NSRect(origin: .zero, size: originalSize),
            operation: .copy,
            fraction: 1.0
        )
        newImage.unlockFocus()
        return newImage
    }

    func jpegData(compression: CGFloat = 0.8) -> Data? {
        guard let tiffData = self.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData)
        else {
            return nil
        }
        return bitmap.representation(
            using: .jpeg, properties: [.compressionFactor: compression])
    }
}
