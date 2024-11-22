//
//  Library.swift
//  FFMPEGBuilder
//
//  Created by tinuv on 2024/5/1.
//

import Foundation

enum Library: String, CaseIterable {
    case libshaderc
    case vulkan
    case lcms2
    case libplacebo
    case libdav1d
    case gmp
    case nettle
    case gnutls
    case readline
    case libsmbclient
    case libsrt
    case libzvbi
    case libfreetype
    case libfribidi
    case libharfbuzz
    case libass
    case libfontconfig
    case libbluray
    case libunibreak
    case ffmpeg
    case libmpv
}

extension Library {
    var libRepoURL: String {
        switch self {
            case .libshaderc:
                "https://github.com/google/shaderc"
            case .vulkan:
                "https://github.com/KhronosGroup/MoltenVK"
            case .lcms2:
                "https://github.com/mm2/Little-CMS"
            case .libplacebo:
                "https://github.com/haasn/libplacebo"
            case .libdav1d:
                "https://github.com/videolan/dav1d"
            case .gmp:
                "https://github.com/alisw/GMP"
            case .nettle:
                "https://git.lysator.liu.se/nettle/nettle"
            case .gnutls:
                "https://github.com/gnutls/gnutls"
            case .readline:
                "https://git.savannah.gnu.org/git/readline.git"
            case .libsmbclient:
                "https://github.com/samba-team/samba"
            case .libsrt:
                "https://github.com/Haivision/srt"
            case .libzvbi:
                "https://github.com/zapping-vbi/zvbi"
            case .libfreetype:
                "https://github.com/freetype/freetype"
            case .libfribidi:
                "https://github.com/fribidi/fribidi"
            case .libharfbuzz:
                "https://github.com/harfbuzz/harfbuzz"
            case .libass:
                "https://github.com/libass/libass"
            case .libfontconfig:
                "https://gitlab.freedesktop.org/fontconfig/fontconfig"
            case .libbluray:
                "https://code.videolan.org/videolan/libbluray"
            case .libunibreak:
                "https://github.com/adah1972/libunibreak"
            case .ffmpeg:
                "https://github.com/FFmpeg/FFmpeg"
            case .libmpv:
                "https://github.com/mpv-player/mpv"
        }
    }

    var libVersion: String {
        switch self {
            case .libshaderc:
                "v2024.0"
            case .vulkan:
                "v1.2.8"
            case .lcms2:
                "lcms2.16"
            case .libplacebo:
                "v6.338.2"
            case .libdav1d:
                "1.1.0"
            case .gmp:
                "v6.2.1"
            case .nettle:
                "nettle_3.9.1_release_20230601"
            case .gnutls:
                "3.8.3"
            case .readline:
                "readline-8.2"
            case .libsmbclient:
                "samba-4.15.13"
            case .libsrt:
                "v1.5.3"
            case .libzvbi:
                "v0.2.42"
            case .libfreetype:
                "VER-2-13-2"
            case .libfribidi:
                "v1.0.12"
            case .libharfbuzz:
                "8.5.0"
            case .libass:
                "0.17.1-branch"
            case .libfontconfig:
                "2.14.2"
            case .libbluray:
                "1.3.4"
            case .libunibreak:
                "libunibreak_6_1"
            case .ffmpeg:
                "n7.0.2"
            case .libmpv:
                "v0.39.0"
        }
    }

    var libBuilder: Builder {
        switch self {
            case .libshaderc:
                LibShadercBuilder(lib: self)
            case .vulkan:
                LibVulkanBuilder(lib: self)
            case .lcms2:
                LibLcms2Builder(lib: self)
            case .libplacebo:
                LibplaceboBuilder(lib: self)
            case .libdav1d:
                Libdav1dBuilder(lib: self)
            case .gmp:
                LibGmpBuilder(lib: self)
            case .nettle:
                LibNettleBuilder(lib: self)
            case .gnutls:
                LibGnutlsBuilder(lib: self)
            case .readline:
                LibReadLineBuilder(lib: self)
            case .libsmbclient:
                LibsmbclientBuilder(lib: self)
            case .libsrt:
                LibSrtBuilder(lib: self)
            case .libzvbi:
                LibzvbiBuilder(lib: self)
            case .libfreetype:
                LibFreeTypeBuilder(lib: self)
            case .libfribidi:
                LibfribidiBuilder(lib: self)
            case .libharfbuzz:
                LibharfbuzzBuilder(lib: self)
            case .libass:
                LibassBuilder(lib: self)
            case .libfontconfig:
                LibfontconfigBuilder(lib: self)
            case .libbluray:
                LibblurayBuilder(lib: self)
            case .libunibreak:
                LibunibreakBuilder(lib: self)
            case .ffmpeg:
                LibFFMPEGBuilder(lib: self)
            case .libmpv:
                LibmpvBuilder(lib: self)
        }
    }

    var libSourceDirectory: URL {
        URL(fileURLWithPath: FFMPEGBuilder.buildDirectory+"/\(self.rawValue)"+"-"+"source"+"-"+"\(self.libVersion)")
    }

    func thin(platform: PlatformType, arch: ArchType) -> URL {
        URL(fileURLWithPath: FFMPEGBuilder.buildDirectory+"/\(self.rawValue)-build"+"/\(platform.rawValue)"+"/thin"+"/\(arch.rawValue)")
    }

    func scratch(platform: PlatformType, arch: ArchType) -> URL {
        URL(fileURLWithPath: FFMPEGBuilder.buildDirectory+"/\(self.rawValue)-build"+"/\(platform.rawValue)"+"/scratch"+"/\(arch.rawValue)")
    }

    func framework(platform: PlatformType, framework: String) -> URL {
        URL(fileURLWithPath: FFMPEGBuilder.buildDirectory+"/\(self.rawValue)-frameworks"+"/\(platform.rawValue)"+"/\(framework).framework")
    }

    func xcFramework(framework: String) -> URL {
        URL(fileURLWithPath: FFMPEGBuilder.distDirectory+"/\(framework).xcframework")
    }

    var isFFmpegDependentLibrary: Bool {
        switch self {
            case .gmp,
                 .gnutls,
                 /* .libglslang, */ .lcms2,
                 .libbluray,
                 .libdav1d,
                 .libfontconfig,
                 .libplacebo,
                 .libshaderc,
                 .libsrt,
                 .libzvbi,
                 .vulkan: return true
            //case .libsmbclient:
            //    return true
            default:
                return false
        }
    }
}
