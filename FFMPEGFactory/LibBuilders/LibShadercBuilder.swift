//
//  File.swift
//
//
//  Created by tinuv on 2024/4/30.
//

import Foundation

class LibShadercBuilder: Builder {
    override func preCompile() {
        super.preCompile()
        _ = try? Utility.launch(executableURL: lib.libSourceDirectory + "utils/git-sync-deps", arguments: [], currentDirectoryURL: lib.libSourceDirectory)
        var path = lib.libSourceDirectory + "third_party/spirv-tools/tools/reduce/reduce.cpp"
        if let data = FileManager.default.contents(atPath: path.path), var str = String(data: data, encoding: .utf8) {
            str = str.replacingOccurrences(of: """
              int res = std::system(nullptr);
              return res != 0;
            """, with: """
              FILE* fp = popen(nullptr, "r");
              return fp == NULL;
            """)
            str = str.replacingOccurrences(of: """
              int status = std::system(command.c_str());
            """, with: """
              FILE* fp = popen(command.c_str(), "r");
            """)
            str = str.replacingOccurrences(of: """
              return status == 0;
            """, with: """
              return fp != NULL;
            """)
            try! str.write(toFile: path.path, atomically: true, encoding: .utf8)
        }
        path = lib.libSourceDirectory + "third_party/spirv-tools/tools/fuzz/fuzz.cpp"
        if let data = FileManager.default.contents(atPath: path.path), var str = String(data: data, encoding: .utf8) {
            str = str.replacingOccurrences(of: """
              int res = std::system(nullptr);
              return res != 0;
            """, with: """
              FILE* fp = popen(nullptr, "r");
              return fp == NULL;
            """)
            str = str.replacingOccurrences(of: """
              int status = std::system(command.c_str());
            """, with: """
              FILE* fp = popen(command.c_str(), "r");
            """)
            str = str.replacingOccurrences(of: """
              return status == 0;
            """, with: """
              return fp != NULL;
            """)
            try! str.write(toFile: path.path, atomically: true, encoding: .utf8)
        }
    }

    override func frameworks() -> [String] {
        ["libshaderc_combined"]
    }

    override func postBuild(platform: PlatformType, arch: ArchType) {
        super.postBuild(platform: platform, arch: arch)
        let thinDir = lib.thin(platform: platform, arch: arch)
        let pkgconfig = thinDir + "lib/pkgconfig"
        do {
            try FileManager.default.moveItem(at: pkgconfig + "shaderc.pc", to: pkgconfig + "shaderc_shared.pc")
            try FileManager.default.moveItem(at: pkgconfig + "shaderc_combined.pc", to: pkgconfig + "shaderc.pc")
        } catch {
            print("LibShadercBuilder moveItem error \(error)")
        }
    }
}
