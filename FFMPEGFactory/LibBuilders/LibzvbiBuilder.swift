//
//  LibzvbiBuilder.swift
//  FFMPEGBuilder
//
//  Created by tinuv on 2024/5/8.
//

import Foundation

class LibzvbiBuilder: Builder {
    override func preCompile() {
        let path = lib.libSourceDirectory + "configure.ac"
        if let data = FileManager.default.contents(atPath: path.path), var str = String(data: data, encoding: .utf8) {
            str = str.replacingOccurrences(of: "AC_FUNC_MALLOC", with: "")
            str = str.replacingOccurrences(of: "AC_FUNC_REALLOC", with: "")
            try! str.write(toFile: path.path, atomically: true, encoding: .utf8)
        }
    }

    override func platforms() -> [PlatformType] {
        super.platforms().filter {
            $0 != .maccatalyst
        }
    }

    override func arguments(platform: PlatformType, arch: ArchType) -> [String] {
        ["--host=\(platform.host(arch: arch))",
         "--prefix=\(lib.thin(platform: platform, arch: arch).path)"]
    }
}
