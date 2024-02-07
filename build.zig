const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const CPico = b.addStaticLibrary(.{
        .name = "CPico",
        .target = target,
        .optimize = optimize,
    });

    CPico.addIncludePath(.{ .path = "c/" });
    CPico.addCSourceFile(.{ .file = .{ .path = "c/picohttpparser.c" } });
    CPico.installHeader("c/picohttpparser.h", "picohttpparser.h");
    CPico.linkLibC();

    const ZPico = b.createModule(.{ .root_source_file = .{ .path = "src/ZPico.zig" }, .target = target, .optimize = optimize });
    ZPico.linkLibrary(CPico);

    const UnitTests = b.addTest(.{
        .root_source_file = .{ .path = "src/Test.zig" },
        .target = target,
        .optimize = optimize,
    });

    UnitTests.root_module.addImport("ZPico", ZPico);

    const RunUnitTests = b.addRunArtifact(UnitTests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const TestStep = b.step("test", "Run unit tests");
    TestStep.dependOn(&RunUnitTests.step);
}
