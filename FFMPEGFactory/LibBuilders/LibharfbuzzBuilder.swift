//
//  LibharfbuzzBuilder.swift
//  FFMPEGBuilder
//
//  Created by tinuv on 2024/5/8.
//

import Foundation

class LibharfbuzzBuilder: Builder {
    override func arguments(platform _: PlatformType, arch _: ArchType) -> [String] {
        [
            "-Dglib=disabled",
            "-Ddocs=disabled",
        ]
    }
}
