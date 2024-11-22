//
//  LibVulkanBuilder.swift
//  FFMPEGBuilder
//
//  Created by tinuv on 2024/5/8.
//

import Foundation

class LibVulkanBuilder: Builder {
    override func platforms() -> [PlatformType] {
        // Placebo编译maccatalyst的时候，vulkan会报找不到UIKit的问题，所以要先屏蔽。
        super.platforms().filter {
            ![.maccatalyst].contains($0)
        }
    }

    override func build() {
        super.obtainSource()
        super.preCompile()
        self.compile()
        super.postCompile()
    }

    override func compile() {
        var arguments = platforms().map {
            "--\($0.name)"
        }
        if !FileManager.default.fileExists(atPath: (lib.libSourceDirectory + "External/build/Release").path) {
            do {
                try Utility.launch(path: (lib.libSourceDirectory + "fetchDependencies").path, arguments: arguments, currentDirectoryURL: lib.libSourceDirectory)
            } catch {
                print("LibVulkanBuilder获取依赖失败: \(error)")
            }
        }
        arguments = platforms().map(\.name)
        if !FileManager.default.fileExists(atPath: (lib.libSourceDirectory + "Package/Release/MoltenVK/static/MoltenVK.xcframework").path) {
            do {
                try Utility.launch(path: "/usr/bin/make", arguments: arguments, currentDirectoryURL: lib.libSourceDirectory)
            } catch {
                print("LibVulkanBuilder编译失败: \(error)")
            }
        }
        try? FileManager.default.removeItem(at: lib.xcFramework(framework: "MoltenVK"))
        try? FileManager.default.copyItem(at: lib.libSourceDirectory + "Package/Release/MoltenVK/static/MoltenVK.xcframework", to: lib.xcFramework(framework: "MoltenVK"))
        for platform in platforms() {
            var frameworks = ["CoreFoundation", "CoreGraphics", "Foundation", "IOSurface", "Metal", "QuartzCore"]
            if platform == .macos {
                frameworks.append("Cocoa")
            } else {
                frameworks.append("UIKit")
            }
            if !(platform == .tvos || platform == .tvsimulator) {
                frameworks.append("IOKit")
            }
            let libframework = frameworks.map {
                "-framework \($0)"
            }.joined(separator: " ")
            for arch in platform.architectures {
                let prefix = lib.thin(platform: platform, arch: arch) + "lib/pkgconfig"
                try? FileManager.default.removeItem(at: prefix)
                try? FileManager.default.createDirectory(at: prefix, withIntermediateDirectories: true, attributes: nil)
                let vulkanPC = prefix + "vulkan.pc"

                let content = """
                prefix=\((lib.libSourceDirectory + "Package/Release/MoltenVK").path)
                includedir=${prefix}/include
                libdir=${prefix}/static/MoltenVK.xcframework/\(platform.frameworkName)

                Name: Vulkan-Loader
                Description: Vulkan Loader
                Version: 1.2
                Libs: -L${libdir} -lMoltenVK \(libframework)
                Cflags: -I${includedir}
                """
                FileManager.default.createFile(atPath: vulkanPC.path, contents: content.data(using: .utf8), attributes: nil)
            }
        }
    }
}
