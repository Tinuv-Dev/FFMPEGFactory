//
//  LibReadLineBuilder.swift
//  FFMPEGBuilder
//
//  Created by tinuv on 2024/5/8.
//

import Foundation

class LibReadLineBuilder: Builder {
    // readline 只是在编译的时候需要用到。外面不需要用到
    override func frameworks() -> [String] {
        []
    }

    override func arguments(platform: PlatformType, arch: ArchType) -> [String] {
        [
            "--enable-static",
            "--disable-shared",
            "--host=\(platform.host(arch: arch))",
            "--prefix=\(lib.thin(platform: platform, arch: arch).path)",
        ]
    }
}
