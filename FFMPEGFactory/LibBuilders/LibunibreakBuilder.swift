//
//  LibunibreakBuilder.swift
//  FFMPEGBuilder
//
//  Created by tinuv on 2024/5/8.
//

import Foundation

class LibunibreakBuilder: Builder {
    override func arguments(platform: PlatformType, arch: ArchType) -> [String] {
        [
            "--disable-shared",
            "--host=\(platform.host(arch: arch))",
            "--prefix=\(lib.thin(platform: platform, arch: arch).path)",
        ]
    }
}
