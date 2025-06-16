//
//  ClipboardItem.swift
//  ClipboardManager
//
//  Created by Le Tien Dat on 13/6/25.
//

import AppKit
import Foundation

struct ClipboardItem: Identifiable, Codable {
    let id: UUID
    let content: ContentType
    var timestamp: Date

    enum ContentType: Codable {
        case text(String)
        case image(Data)

        enum CodingKeys: String, CodingKey {
            case type, data
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .text(let string):
                try container.encode("text", forKey: .type)
                try container.encode(string, forKey: .data)
            case .image(let data):
                try container.encode("image", forKey: .type)
                try container.encode(data, forKey: .data)
            }
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            switch type {
            case "text":
                let string = try container.decode(String.self, forKey: .data)
                self = .text(string)
            case "image":
                let data = try container.decode(Data.self, forKey: .data)
                self = .image(data)
            default:
                throw DecodingError.dataCorruptedError(
                    forKey: .type,
                    in: container,
                    debugDescription: "Unknown type")
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, content, timestamp
    }

    init(content: Any, timestamp: Date = Date()) {
        self.id = UUID()
        self.timestamp = timestamp
        if let string = content as? String {
            self.content = .text(string)
        } else if let image = content as? NSImage,
            let data = image.tiffRepresentation {
            self.content = .image(data)
        } else {
            self.content = .text("")
        }
    }

    mutating func updateTimestamp(_ newDate: Date) {
        self.timestamp = newDate
    }
}
