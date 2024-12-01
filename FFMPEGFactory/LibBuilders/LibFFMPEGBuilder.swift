//
//  FFMPEGBuilder.swift
//  FFMPEGBuilder
//
//  Created by tinuv on 2024/5/8.
//

import Foundation

class LibFFMPEGBuilder: Builder {
    
    override func platforms() -> [PlatformType] {
        // Placebo编译maccatalyst的时候，vulkan会报找不到UIKit的问题，所以要先屏蔽。
        super.platforms().filter {
            ![].contains($0)
        }
    }
    
    
    override func preCompile() {
        super.preCompile()
        if Utility.shell("which nasm") == nil {
            Utility.shell("brew install nasm")
        }
        if Utility.shell("which sdl2-config") == nil {
            Utility.shell("brew install sdl2")
        }
        let lldbFile = URL.currentDirectory + "LLDBInitFile"
        try? FileManager.default.removeItem(at: lldbFile)
        FileManager.default.createFile(atPath: lldbFile.path, contents: nil, attributes: nil)
        let path = lib.libSourceDirectory + "libavcodec/videotoolbox.c"
        if let data = FileManager.default.contents(atPath: path.path), var str = String(data: data, encoding: .utf8) {
            str = str.replacingOccurrences(of: "kCVPixelBufferOpenGLESCompatibilityKey", with: "kCVPixelBufferMetalCompatibilityKey")
            str = str.replacingOccurrences(of: "kCVPixelBufferIOSurfaceOpenGLTextureCompatibilityKey", with: "kCVPixelBufferMetalCompatibilityKey")
            try! str.write(toFile: path.path, atomically: true, encoding: .utf8)
        }
    }
    
    override func flagsDependencelibrarys() -> [Library] {
        [.gmp, .nettle, .gnutls, .libsmbclient,/*.libsleef*/.lcms2,.libbluray,.libfontconfig,.libfreetype,.libdav1d,.libplacebo,.libshaderc,.libsrt,.libzvbi]
    }
    
    override func frameworks() -> [String] {
        var frameworks: [String] = []
        if let platform = platforms().first {
            if let arch = platform.architectures.first {
                let lib = lib.thin(platform: platform, arch: arch) + "lib"
                let fileNames = try! FileManager.default.contentsOfDirectory(atPath: lib.path)
                for fileName in fileNames {
                    if fileName.hasPrefix("lib"), fileName.hasSuffix(".a") {
                        frameworks.append("Lib" + fileName.dropFirst(3).dropLast(2))
                    }
                }
            }
        }
        return frameworks
    }
    
    override func ldFlags(platform: PlatformType, arch: ArchType) -> [String] {
        var ldFlags = super.ldFlags(platform: platform, arch: arch)
        ldFlags.append("-lc++")
        return ldFlags
    }
    
    override func environment(platform: PlatformType, arch: ArchType) -> [String: String] {
        var env = super.environment(platform: platform, arch: arch)
        env["CPPFLAGS"] = env["CFLAGS"]
        return env
    }
    
    override func postBuild(platform: PlatformType, arch: ArchType,lib: Library) {
        super.postBuild(platform: platform, arch: arch,lib: lib)
        let prefix = lib.thin(platform: platform, arch: arch)
        let lldbFile = URL.currentDirectory + "LLDBInitFile"
        let buildURL = lib.scratch(platform: platform, arch: arch)
        if let data = FileManager.default.contents(atPath: lldbFile.path), var str = String(data: data, encoding: .utf8) {
            str.append("settings \(str.isEmpty ? "set" : "append") target.source-map \((buildURL + "src").path) \(lib.libSourceDirectory.path)\n")
            do {
                try str.write(toFile: lldbFile.path, atomically: true, encoding: .utf8)
            } catch {
                print("LibFFMPEGBuilder error: \(error)")
                fatalError()
            }
        }
        
        do {
            try FileManager.default.copyItem(at: buildURL + "config.h", to: prefix + "include/libavutil/config.h")
            try FileManager.default.copyItem(at: buildURL + "config.h", to: prefix + "include/libavcodec/config.h")
            try FileManager.default.copyItem(at: buildURL + "config.h", to: prefix + "include/libavformat/config.h")
            try FileManager.default.copyItem(at: buildURL + "src/libavutil/getenv_utf8.h", to: prefix + "include/libavutil/getenv_utf8.h")
            try FileManager.default.copyItem(at: buildURL + "src/libavutil/libm.h", to: prefix + "include/libavutil/libm.h")
            try FileManager.default.copyItem(at: buildURL + "src/libavutil/thread.h", to: prefix + "include/libavutil/thread.h")
            try FileManager.default.copyItem(at: buildURL + "src/libavutil/intmath.h", to: prefix + "include/libavutil/intmath.h")
            try FileManager.default.copyItem(at: buildURL + "src/libavutil/mem_internal.h", to: prefix + "include/libavutil/mem_internal.h")
            try FileManager.default.copyItem(at: buildURL + "src/libavutil/attributes_internal.h", to: prefix + "include/libavutil/attributes_internal.h")
            try FileManager.default.copyItem(at: buildURL + "src/libavcodec/mathops.h", to: prefix + "include/libavcodec/mathops.h")
            try FileManager.default.copyItem(at: buildURL + "src/libavformat/os_support.h", to: prefix + "include/libavformat/os_support.h")
        } catch {
            print("复制文件异常: \(error)")
            fatalError()
        }
        let internalPath = prefix + "include/libavutil/internal.h"
        do {
            try FileManager.default.copyItem(at: buildURL + "src/libavutil/internal.h", to: internalPath)
        } catch {
            print("error: \(error)")
        }
        
        if let data = FileManager.default.contents(atPath: internalPath.path), var str = String(data: data, encoding: .utf8) {
            str = str.replacingOccurrences(of: """
            #include "timer.h"
            """, with: """
            // #include "timer.h"
            """)
            str = str.replacingOccurrences(of: "kCVPixelBufferIOSurfaceOpenGLTextureCompatibilityKey", with: "kCVPixelBufferMetalCompatibilityKey")
            do {
                try str.write(toFile: internalPath.path, atomically: true, encoding: .utf8)
            } catch {
                print("复制文件异常")
                fatalError()
            }
        }
        if platform == .macos, arch.executable {
            let fftoolsFile = URL.currentDirectory + "../Sources/fftools"
            try? FileManager.default.removeItem(at: fftoolsFile)
            if !FileManager.default.fileExists(atPath: (fftoolsFile + "include/compat").path) {
                do {
                    try FileManager.default.createDirectory(at: fftoolsFile + "include/compat", withIntermediateDirectories: true)
                } catch {
                    print("复制文件异常")
                    fatalError()
                }
            }
            do {
                try FileManager.default.copyItem(at: buildURL + "src/compat/va_copy.h", to: fftoolsFile + "include/compat/va_copy.h")
                try FileManager.default.copyItem(at: buildURL + "config.h", to: fftoolsFile + "include/config.h")
                try FileManager.default.copyItem(at: buildURL + "config_components.h", to: fftoolsFile + "include/config_components.h")
                if !FileManager.default.fileExists(atPath: (fftoolsFile + "include/libavdevice").path) {
                    try FileManager.default.createDirectory(at: fftoolsFile + "include/libavdevice", withIntermediateDirectories: true)
                }
                try FileManager.default.copyItem(at: buildURL + "src/libavdevice/avdevice.h", to: fftoolsFile + "include/libavdevice/avdevice.h")
                try FileManager.default.copyItem(at: buildURL + "src/libavdevice/version_major.h", to: fftoolsFile + "include/libavdevice/version_major.h")
                try FileManager.default.copyItem(at: buildURL + "src/libavdevice/version.h", to: fftoolsFile + "include/libavdevice/version.h")
                if !FileManager.default.fileExists(atPath: (fftoolsFile + "include/libpostproc").path) {
                    try FileManager.default.createDirectory(at: fftoolsFile + "include/libpostproc", withIntermediateDirectories: true)
                }
                try FileManager.default.copyItem(at: buildURL + "src/libpostproc/postprocess_internal.h", to: fftoolsFile + "include/libpostproc/postprocess_internal.h")
                try FileManager.default.copyItem(at: buildURL + "src/libpostproc/postprocess.h", to: fftoolsFile + "include/libpostproc/postprocess.h")
                try FileManager.default.copyItem(at: buildURL + "src/libpostproc/version_major.h", to: fftoolsFile + "include/libpostproc/version_major.h")
                try FileManager.default.copyItem(at: buildURL + "src/libpostproc/version.h", to: fftoolsFile + "include/libpostproc/version.h")
            } catch {
                print("error")
                fatalError()
            }
            do {
                let ffplayFile = URL.currentDirectory + "../Sources/ffplay"
                try? FileManager.default.removeItem(at: ffplayFile)
                try FileManager.default.createDirectory(at: ffplayFile, withIntermediateDirectories: true)
                let ffprobeFile = URL.currentDirectory + "../Sources/ffprobe"
                try? FileManager.default.removeItem(at: ffprobeFile)
                try FileManager.default.createDirectory(at: ffprobeFile, withIntermediateDirectories: true)
                let ffmpegFile = URL.currentDirectory + "../Sources/ffmpeg"
                try? FileManager.default.removeItem(at: ffmpegFile)
                try FileManager.default.createDirectory(at: ffmpegFile + "include", withIntermediateDirectories: true)
                let fftools = buildURL + "src/fftools"
                let fileNames = try FileManager.default.contentsOfDirectory(atPath: fftools.path)
                for fileName in fileNames {
                    if fileName.hasPrefix("ffplay") {
                        try FileManager.default.copyItem(at: fftools + fileName, to: ffplayFile + fileName)
                    } else if fileName.hasPrefix("ffprobe") {
                        try FileManager.default.copyItem(at: fftools + fileName, to: ffprobeFile + fileName)
                    } else if fileName.hasPrefix("ffmpeg") {
                        if fileName.hasSuffix(".h") {
                            try FileManager.default.copyItem(at: fftools + fileName, to: ffmpegFile + "include" + fileName)
                        } else {
                            try FileManager.default.copyItem(at: fftools + fileName, to: ffmpegFile + fileName)
                        }
                    } else if fileName.hasSuffix(".h") {
                        try FileManager.default.copyItem(at: fftools + fileName, to: fftoolsFile + "include" + fileName)
                    } else if fileName.hasSuffix(".c") {
                        try FileManager.default.copyItem(at: fftools + fileName, to: fftoolsFile + fileName)
                    }
                }
            } catch {
                print("error")
                fatalError()
            }
            let prefix = lib.scratch(platform: platform, arch: arch)
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: "/usr/local/bin/ffmpeg"))
            try? FileManager.default.copyItem(at: prefix + "ffmpeg", to: URL(fileURLWithPath: "/usr/local/bin/ffmpeg"))
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: "/usr/local/bin/ffplay"))
            try? FileManager.default.copyItem(at: prefix + "ffplay", to: URL(fileURLWithPath: "/usr/local/bin/ffplay"))
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: "/usr/local/bin/ffprobe"))
            try? FileManager.default.copyItem(at: prefix + "ffprobe", to: URL(fileURLWithPath: "/usr/local/bin/ffprobe"))
        }
        
    }
    
    override func frameworkExcludeHeaders(_ framework: String) -> [String] {
        if framework == "Libavcodec" {
            return ["xvmc", "vdpau", "qsv", "dxva2", "d3d11va", "mathops", "videotoolbox"]
        } else if framework == "Libavutil" {
            return ["hwcontext_vulkan", "hwcontext_vdpau", "hwcontext_vaapi", "hwcontext_qsv", "hwcontext_opencl", "hwcontext_dxva2", "hwcontext_d3d11va", "hwcontext_cuda", "hwcontext_videotoolbox", "getenv_utf8", "intmath", "libm", "thread", "mem_internal", "internal", "attributes_internal"]
        } else if framework == "Libavformat" {
            return ["os_support"]
        } else {
            return super.frameworkExcludeHeaders(framework)
        }
    }

    override func arguments(platform: PlatformType, arch: ArchType) -> [String] {
        var arguments = [
            "--prefix=\(lib.thin(platform: platform, arch: arch).path)",
        ]
        arguments += ffmpegConfiguers
        arguments += FFMPEGBuilder.ffmpegConfiguers
        arguments.append("--arch=\(arch.cpuFamily)")
        if platform == .android {
            arguments.append("--target-os=android")
            // 这些参数apple不加也可以编译通过，android一定要加
            arguments.append("--cc=\(platform.cc)")
            arguments.append("--cxx=\(platform.cc)++")
//            arguments.append("--cross-prefix=\(platform.host(arch: arch))-")
//            arguments.append("--sysroot=\(platform.isysroot)")
        } else {
            arguments.append("--target-os=darwin")
            arguments.append("--enable-libxml2")
        }
        //arguments.append("-DCMAKE_C_VISIBILITY_PRESET=hidden")
        //arguments.append("-DCMAKE_CXX_VISIBILITY_PRESET=hidden")
        // arguments.append(arch.cpu())
        /**
         aacpsdsp.o), building for Mac Catalyst, but linking in object file built for
         x86_64 binaries are built without ASM support, since ASM for x86_64 is actually x86 and that confuses `xcodebuild -create-xcframework` https://stackoverflow.com/questions/58796267/building-for-macos-but-linking-in-object-file-built-for-free-standing/59103419#59103419
         */
        //arguments.append("--disable-libsmbclient")
        if platform == .maccatalyst || arch == .x86_64 {
            arguments.append("--disable-neon")
            arguments.append("--disable-asm")
        } else {
            arguments.append("--enable-neon")
            arguments.append("--enable-asm")
        }
        if ![.watchsimulator, .watchos, .android].contains(platform) {
            arguments.append("--enable-videotoolbox")
            arguments.append("--enable-audiotoolbox")
            arguments.append("--enable-filter=yadif_videotoolbox")
            arguments.append("--enable-filter=scale_vt")
            arguments.append("--enable-filter=transpose_vt")
        } else {
            arguments.append("--enable-encoder=h264_videotoolbox")
            arguments.append("--enable-encoder=hevc_videotoolbox")
            arguments.append("--enable-encoder=prores_videotoolbox")
        }
        if platform == .macos, arch.executable {
            arguments.append("--enable-ffplay")
            arguments.append("--enable-sdl2")
            arguments.append("--enable-decoder=rawvideo")
            arguments.append("--enable-filter=color")
            arguments.append("--enable-filter=lut")
            arguments.append("--enable-filter=testsrc")
            // debug
            arguments.append("--enable-debug")
            arguments.append("--enable-debug=3")
            arguments.append("--disable-stripping")
        } else {
            arguments.append("--disable-programs")
        }
        if platform == .macos {
            arguments.append("--enable-outdev=audiotoolbox")
        }
        if !([PlatformType.tvos, .tvsimulator, .xros, .xrsimulator].contains(platform)) {
            // tvos17才支持AVCaptureDeviceInput
//            'defaultDeviceWithMediaType:' is unavailable: not available on visionOS
            arguments.append("--enable-indev=avfoundation")
        }
        //        if platform == .isimulator || platform == .tvsimulator {
        //            arguments.append("--assert-level=1")
        //        }
        for library in Library.allCases {
            let path = library.thin(platform: platform, arch: arch)
            if FileManager.default.fileExists(atPath: path.path), library.isFFmpegDependentLibrary {
                arguments.append("--enable-\(library.rawValue)")
                if library == .libsrt || library == .libsmbclient {
                    arguments.append("--enable-protocol=\(library.rawValue)")
                } else if library == .libdav1d {
                    arguments.append("--enable-decoder=\(library.rawValue)")
                } else if library == .libass {
                    arguments.append("--enable-filter=ass")
                    arguments.append("--enable-filter=subtitles")
                } else if library == .libzvbi {
                    arguments.append("--enable-decoder=libzvbi_teletext")
                } else if library == .libplacebo {
                    arguments.append("--enable-filter=libplacebo")
                }
            }
        }
        return arguments
    }

    /*
     boxblur_filter_deps="gpl"
     delogo_filter_deps="gpl"
     */
    private let ffmpegConfiguers = [
        // Configuration options:
        "--enable-gpl",
        //"--enable-libtorch",
        "--disable-armv5te", "--disable-armv6", "--disable-armv6t2",
        "--disable-bzlib", "--disable-gray", "--disable-iconv", "--disable-linux-perf",
        "--disable-shared", "--disable-small", "--disable-swscale-alpha", "--disable-symver", "--disable-xlib",
        "--enable-cross-compile",
        "--enable-optimizations", "--enable-pic", "--enable-runtime-cpudetect", "--enable-static", "--enable-thumb", "--enable-version3",
        "--pkg-config-flags=--static",
        // Documentation options:
        "--disable-doc", "--disable-htmlpages", "--disable-manpages", "--disable-podpages", "--disable-txtpages",
        // Component options:
        "--enable-avcodec", "--enable-avformat", "--enable-avutil", "--enable-network", "--enable-swresample", "--enable-swscale",
        "--disable-devices", "--disable-outdevs", "--disable-indevs", "--disable-postproc",
        "--enable-indev=lavfi",
        // ,"--disable-pthreads"
        // ,"--disable-w32threads"
        // ,"--disable-os2threads"
        // ,"--disable-dct"
        // ,"--disable-dwt"
        // ,"--disable-lsp"
        // ,"--disable-lzo"
        // ,"--disable-mdct"
        // ,"--disable-rdft"
        // ,"--disable-fft"
        // Hardware accelerators:
        "--disable-d3d11va", "--disable-dxva2", "--disable-vaapi", "--disable-vdpau",
        // todo ffmpeg的编译脚本有问题，没有加入libavcodec/vulkan_video_codec_av1std.h
        "--disable-hwaccel=av1_vulkan,hevc_vulkan,h264_vulkan",
        "--enable-libass",
        // Individual component options:
        // ,"--disable-everything"
        // ./configure --list-muxers
        "--enable-muxers",
        // ./configure --list-encoders
        "--enable-encoders",
        // ./configure --list-protocols
        "--enable-protocols",
        // ./configure --list-demuxers
        // 用所有的demuxers的话，那avformat就会达到8MB了，指定的话，那就只要4MB。
        "--enable-demuxers",
        // ./configure --list-bsfs
        "--enable-bsfs",
        // ./configure --list-decoders
        // 用所有的decoders的话，那avcodec就会达到40MB了，指定的话，那就只要20MB。
        "--enable-decoders",
        // 视频
        
        // 音频

        // 字幕

        // ./configure --list-filters
        "--disable-filters",
        "--enable-filter=aformat", "--enable-filter=amix", "--enable-filter=anull", "--enable-filter=aresample",
        "--enable-filter=areverse", "--enable-filter=asetrate", "--enable-filter=atempo", "--enable-filter=atrim",
        "--enable-filter=boxblur", "--enable-filter=bwdif", "--enable-filter=delogo",
        "--enable-filter=equalizer", "--enable-filter=estdif",
        "--enable-filter=firequalizer", "--enable-filter=format", "--enable-filter=fps",
        "--enable-filter=gblur",
        "--enable-filter=hflip", "--enable-filter=hwdownload", "--enable-filter=hwmap", "--enable-filter=hwupload",
        "--enable-filter=idet", "--enable-filter=lenscorrection", "--enable-filter=lut*", "--enable-filter=negate", "--enable-filter=null",
        "--enable-filter=overlay",
        "--enable-filter=palettegen", "--enable-filter=paletteuse", "--enable-filter=pan",
        "--enable-filter=rotate",
        "--enable-filter=scale", "--enable-filter=setpts", "--enable-filter=superequalizer",
        "--enable-filter=transpose", "--enable-filter=trim",
        "--enable-filter=vflip", "--enable-filter=volume",
        "--enable-filter=w3fdif",
        "--enable-filter=yadif",
        "--enable-filter=avgblur_vulkan", "--enable-filter=blend_vulkan", "--enable-filter=bwdif_vulkan",
        "--enable-filter=chromaber_vulkan", "--enable-filter=flip_vulkan", "--enable-filter=gblur_vulkan",
        "--enable-filter=hflip_vulkan", "--enable-filter=nlmeans_vulkan", "--enable-filter=overlay_vulkan",
        "--enable-filter=vflip_vulkan", "--enable-filter=xfade_vulkan","--enable-filter=subtitles","--enable-filter=drawbox","--enable-filter=myfilter"
    ]
}
