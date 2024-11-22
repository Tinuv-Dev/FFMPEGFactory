//
//  LibplaceboBuilder.swift
//  FFMPEGBuilder
//
//  Created by tinuv on 2024/5/8.
//

import Foundation

class LibplaceboBuilder: Builder {
    override func preCompile() {
        let path = lib.libSourceDirectory + "demos/meson.build"
        if let data = FileManager.default.contents(atPath: path.path), var str = String(data: data, encoding: .utf8) {
            str = str.replacingOccurrences(of: "if sdl.found()", with: "if false")
            try! str.write(toFile: path.path, atomically: true, encoding: .utf8)
        }
    }

    override func arguments(platform _: PlatformType, arch _: ArchType) -> [String] {
        ["-Dxxhash=disabled", "-Dopengl=disabled"]
    }
}
