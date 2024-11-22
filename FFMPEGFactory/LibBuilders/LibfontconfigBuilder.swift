//
//  LibfontconfigBuilder.swift
//  FFMPEGBuilder
//
//  Created by tinuv on 2024/5/8.
//

import Foundation
class LibfontconfigBuilder: Builder {
    override func arguments(platform _: PlatformType, arch _: ArchType) -> [String] {
        [
            "-Ddoc=disabled",
            "-Dtests=disabled",
        ]
    }
}
