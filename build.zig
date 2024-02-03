const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const @"Vulkan-Headers" = b.dependency(
        "Vulkan-Headers",
        .{
            .target = target,
            .optimize = optimize,
        },
    );

    const vulkan_loader = b.addStaticLibrary(.{
        .name = "vulkan",
        .target = target,
        .optimize = optimize,
    });
    vulkan_loader.addIncludePath(.{ .path = "loader/" });
    vulkan_loader.addIncludePath(.{ .path = "loader/generated" });

    // normal loader sources
    vulkan_loader.addCSourceFiles(.{
        .files = &.{
            "loader/allocation.c",
            "loader/cJSON.c",
            "loader/debug_utils.c",
            "loader/extension_manual.c",
            "loader/loader_environment.c",
            "loader/gpa_helper.c",
            "loader/loader.c",
            "loader/log.c",
            "loader/settings.c",
            "loader/terminator.c",
            "loader/trampoline.c",
            "loader/unknown_function_handling.c",
            "loader/wsi.c",
        },
    });

    if (target.result.os.tag == .windows) {
        vulkan_loader.addCSourceFiles(.{
            .files = &.{
                "loader/loader_windows.c",
                "loader/dirent_on_windows.h",
            },
        });
    } else if (target.result.os.tag == .linux or target.result.os.tag.isBSD()) {
        vulkan_loader.addCSourceFiles(.{
            .files = &.{
                "loader/loader_linux.c",
            },
        });
        vulkan_loader.root_module.addCMacro("FALLBACK_CONFIG_DIRS", "\"/etc/xdg\"");
        vulkan_loader.root_module.addCMacro("FALLBACK_DATA_DIRS", "\"/usr/local/share:/usr/share\"");
        vulkan_loader.root_module.addCMacro("SYSCONFDIR", "\"\"");
    }

    vulkan_loader.linkLibrary(@"Vulkan-Headers".artifact("vulkan-headers"));
    vulkan_loader.linkLibC();

    b.installArtifact(vulkan_loader);
}
