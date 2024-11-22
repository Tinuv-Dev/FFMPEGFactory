//
//  LibmpvBuilder.swift
//  FFMPEGBuilder
//
//  Created by tinuv on 2024/5/9.
//

import Foundation

class LibmpvBuilder: Builder {
    override func preCompile() {
        super.preCompile()
        let path = lib.libSourceDirectory + "meson.build"
        if let data = FileManager.default.contents(atPath: path.path), var str = String(data: data, encoding: .utf8) {
            str = str.replacingOccurrences(of: "# ffmpeg", with: """
            add_languages('objc')
            #ffmpeg
            """)
            str = str.replacingOccurrences(of: """
            subprocess_source = files('osdep/subprocess-posix.c')
            """, with: """
            if host_machine.subsystem() == 'tvos' or host_machine.subsystem() == 'tvos-simulator'
                subprocess_source = files('osdep/subprocess-dummy.c')
            else
                subprocess_source =files('osdep/subprocess-posix.c')
            endif
            """)
            try! str.write(toFile: path.path, atomically: true, encoding: .utf8)
        }
    }

    override func flagsDependencelibrarys() -> [Library] {
        [.gmp, .libsmbclient]
    }
    
    override func cFlags(platform: PlatformType, arch: ArchType) -> [String] {
        var cFlags = super.cFlags(platform: platform, arch: arch)
        cFlags.append("-Wno-incompatible-function-pointer-types")
        return cFlags
    }

    override func arguments(platform: PlatformType, arch: ArchType) -> [String] {
        var array = [
            "-Dlibmpv=true",
            "-Dgl=enabled",
            "-Dplain-gl=enabled",
            "-Diconv=enabled",
        ]
        // if BaseBuild.disableGPL {
        //    array.append("-Dgpl=false")
        // }
        if !(platform == .macos && arch.executable) {
            array.append("-Dcplayer=false")
        }
        if platform == .macos {
            array.append("-Dswift-flags=-sdk \(platform.isysroot) -target \(platform.deploymentTarget(arch: arch))")
            array.append("-Dcocoa=enabled")
            array.append("-Dcoreaudio=enabled")
            array.append("-Dgl-cocoa=enabled")
            array.append("-Dvideotoolbox-gl=enabled")
        } else {
            array.append("-Dvideotoolbox-gl=disabled")
            array.append("-Dswift-build=disabled")
            array.append("-Daudiounit=enabled")
            array.append("-Dcoreaudio=disabled")
            array.append("-Davfoundation=disabled")
            if platform == .maccatalyst {
                array.append("-Dcocoa=disabled")
                array.append("-Dcoreaudio=disabled")
            } else if platform == .xros || platform == .xrsimulator {
                array.append("-Dios-gl=disabled")
            } else {
                array.append("-Dios-gl=enabled")
            }
        }
        return array
    }
}
