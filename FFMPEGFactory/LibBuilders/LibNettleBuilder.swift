//
//  LibNettleBuilder.swift
//  FFMPEGBuilder
//
//  Created by tinuv on 2024/5/8.
//

import Foundation
class LibNettleBuilder: Builder {
    override func preCompile() {
        super.preCompile()
        if Utility.shell("which autoconf") == nil {
            Utility.shell("brew install autoconf")
        }
    }

    override func flagsDependencelibrarys() -> [Library] {
        [.gmp]
    }

    override func arguments(platform: PlatformType, arch: ArchType) -> [String] {
        [
            "--disable-assembler",
            "--disable-openssl",
            "--disable-gcov",
            "--disable-documentation",
            "--enable-pic",
            "--enable-static",
            "--disable-shared",
            "--disable-dependency-tracking",
            "--host=\(platform.host(arch: arch))",
            "--prefix=\(lib.thin(platform: platform, arch: arch).path)",
        ]
    }

    override func frameworks() -> [String] {
        [lib.rawValue, "hogweed"]
    }
}
