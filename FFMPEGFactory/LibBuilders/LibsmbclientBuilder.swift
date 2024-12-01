//
//  LibsmbclientBuilder.swift
//  FFMPEGBuilder
//
//  Created by tinuv on 2024/5/8.
//

import Foundation

// 需要 python3.8 因为最新版本的 python distutils模块被弃用
class LibsmbclientBuilder: Builder {
    override func wafPath() -> String {
        "buildtools/bin/waf"
    }

    override func cFlags(platform: PlatformType, arch: ArchType) -> [String] {
        var cFlags = super.cFlags(platform: platform, arch: arch)
        cFlags.append("-Wno-error=implicit-function-declaration")
        cFlags.append("-D_DARWIN_USE_64_BIT_INODE")
        cFlags.append("-D_FILE_OFFSET_BITS=64")
        // 新添加了选项
        cFlags.append("-Wno-int-conversion")
        return cFlags
    }

    override func environment(platform: PlatformType, arch: ArchType) -> [String: String] {
        var env = super.environment(platform: platform, arch: arch)
        env["PATH"]? += (":" + (FFMPEGBuilder.libsmbclientDepDirector + "bin").path + ":"
            + (lib.libSourceDirectory + "buildtools/bin").path)
        env["PYTHONHASHSEED"] = "1"
        env["WAF_MAKE"] = "1"
        env["ac_cv_sizeof_off_t"] = "8"
        return env
    }

    override func wafBuildArg() -> [String] {
        ["--targets=smbclient"]
    }

    override func wafInstallArg() -> [String] {
        ["--targets=smbclient"]
    }

    // 将默认的 python 版本替换为 3.8
    override func preCompile() {
        super.preCompile()
        var arguments = ["/opt/homebrew/bin/pip3"]
        try! Utility.launch(path: "/bin/rm", arguments: arguments)
        arguments = ["/opt/homebrew/bin/python3"]
        try! Utility.launch(path: "/bin/rm", arguments: arguments)
        arguments = ["/opt/homebrew/bin/python3-config"]
        try! Utility.launch(path: "/bin/rm", arguments: arguments)

        arguments = ["-s", "/opt/homebrew/Cellar/python@3.8/3.8.19/bin/python3.8", "/opt/homebrew/bin/python3"]
        try! Utility.launch(path: "/bin/ln", arguments: arguments)
        arguments = ["-s", "/opt/homebrew/Cellar/python@3.8/3.8.19/bin/pip3.8", "/opt/homebrew/bin/pip3"]
        try! Utility.launch(path: "/bin/ln", arguments: arguments)
        arguments = ["-s", "/opt/homebrew/Cellar/python@3.8/3.8.19/bin/python3.8-config", "/opt/homebrew/bin/python3-config"]
        try! Utility.launch(path: "/bin/ln", arguments: arguments)
    }

    override func postBuild(platform: PlatformType, arch: ArchType,lib: Library) {
        super.postBuild(platform: platform, arch: arch,lib: lib)
        do {
            try FileManager.default.copyItem(at: lib.libSourceDirectory + "bin/default/source3/libsmb/libsmbclient.a",
                                             to: lib.thin(platform: platform, arch: arch) + "lib/libsmbclient.a")
        } catch {
            print("LibsmbclientBuilder复制异常: \(error)")
            fatalError()
        }
        
    }

    override func postCompile() {
        super.postCompile()
        var arguments = ["/opt/homebrew/bin/pip3"]
        try! Utility.launch(path: "/bin/rm", arguments: arguments)
        arguments = ["/opt/homebrew/bin/python3"]
        try! Utility.launch(path: "/bin/rm", arguments: arguments)
        arguments = ["/opt/homebrew/bin/python3-config"]
        try! Utility.launch(path: "/bin/rm", arguments: arguments)

        arguments = ["-s", "/opt/homebrew/Cellar/python@3.12/3.12.3/bin/python3.12", "/opt/homebrew/bin/python3"]
        try! Utility.launch(path: "/bin/ln", arguments: arguments)
        arguments = ["-s", "/opt/homebrew/Cellar/python@3.12/3.12.3/bin/pip3.12", "/opt/homebrew/bin/pip3"]
        try! Utility.launch(path: "/bin/ln", arguments: arguments)
        arguments = ["-s", "/opt/homebrew/Cellar/python@3.12/3.12.3/bin/python3.12-config", "/opt/homebrew/bin/python3-config"]
        try! Utility.launch(path: "/bin/ln", arguments: arguments)
    }

    override func arguments(platform: PlatformType, arch: ArchType) -> [String] {
        var arg =
            [
                "--without-cluster-support",
                "--disable-rpath",
                "--without-ldap",
                "--without-pam",
                "--enable-fhs",
                "--without-winbind",
                "--without-ads",
                "--disable-avahi",
                "--disable-cups",
                "--without-gettext",
                "--without-ad-dc",
                "--without-acl-support",
                "--without-utmp",
                "--disable-iprint",
                "--nopyc",
                "--nopyo",
                "--disable-python",
                "--disable-symbol-versions",
                "--without-json",
                "--without-libarchive",
                "--without-regedit",
                "--without-lttng",
                "--without-gpgme",
                "--disable-cephfs",
                "--disable-glusterfs",
                "--without-syslog",
                "--without-quotas",
                "--bundled-libraries=ALL",
                "--with-static-modules=!vfs_snapper,ALL",
                "--nonshared-binary=smbtorture,smbd/smbd,client/smbclient",
                "--builtin-libraries=!smbclient,!smbd_base,!smbstatus,ALL",
                "--host=\(platform.host(arch: arch))",
                "--prefix=\(lib.thin(platform: platform, arch: arch).path)",
            ]
        arg.append("--cross-compile")
        arg.append("--cross-answers=cross-answers.txt")
        return arg
    }
}
