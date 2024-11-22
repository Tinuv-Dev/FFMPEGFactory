//
//  URL.swift
//  FFMPEGBuilder
//
//  Created by tinuv on 2024/5/1.
//

import Foundation

extension URL {
    static var currentDirectory: URL {
        URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    }

    static func + (left: URL, right: String) -> URL {
        var url = left
        url.appendPathComponent(right)
        return url
    }

    static func + (left: URL, right: [String]) -> URL {
        var url = left
        for item in right {
            url.appendPathComponent(item)
        }
        return url
    }
}
