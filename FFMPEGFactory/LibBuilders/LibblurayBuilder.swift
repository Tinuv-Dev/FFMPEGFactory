//
//  LibblurayBuilder.swift
//  FFMPEGBuilder
//
//  Created by tinuv on 2024/5/8.
//

import Foundation

class LibblurayBuilder: Builder {
    // 只有macos支持mount
    override func platforms() -> [PlatformType] {
        [.macos]
    }

    override func arguments(platform: PlatformType, arch: ArchType) -> [String] {
        [
            "--disable-bdjava-jar",
            "--disable-silent-rules",
            "--disable-dependency-tracking",
            "--host=\(platform.host(arch: arch))",
            "--prefix=\(lib.thin(platform: platform, arch: arch).path)",
        ]
    }
}
