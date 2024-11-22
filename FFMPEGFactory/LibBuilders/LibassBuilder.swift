//
//  LibassBuilder.swift
//  FFMPEGBuilder
//
//  Created by tinuv on 2024/5/8.
//

import Foundation

class LibassBuilder: Builder {
    override func arguments(platform: PlatformType, arch: ArchType) -> [String] {
        var result =
            [
                "--disable-libtool-lock",
                "--disable-fontconfig",
                "--disable-require-system-font-provider",
                "--disable-test",
                "--disable-profile",
                "--with-pic",
                "--enable-static",
                "--disable-shared",
                "--disable-fast-install",
                "--disable-dependency-tracking",
                "--disable-libunibreak",
                "--host=\(platform.host(arch: arch))",
                "--prefix=\(lib.thin(platform: platform, arch: arch).path)",
            ]
        if arch == .x86_64 {
            result.append("--enable-asm")
        }
        return result
    }
}
