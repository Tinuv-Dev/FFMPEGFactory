//
//  LibGmpBuilder.swift
//  FFMPEGBuilder
//
//  Created by tinuv on 2024/5/8.
//

import Foundation

class LibGmpBuilder: Builder {
    override func preCompile() {
        super.preCompile()
        if Utility.shell("which makeinfo") == nil {
            Utility.shell("brew install texinfo")
        }
    }

    override func arguments(platform: PlatformType, arch: ArchType) -> [String] {
        [
            "--disable-maintainer-mode",
            "--disable-assembly",
            "--with-pic",
            "--enable-static",
            "--disable-shared",
            "--disable-fast-install",
            "--host=\(platform.host(arch: arch))",
            "--prefix=\(lib.thin(platform: platform, arch: arch).path)",
        ]
    }
}
