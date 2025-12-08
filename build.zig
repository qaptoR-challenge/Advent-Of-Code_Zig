const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Define a build option to specify the day to run
    // const day_option = b.option(u16, "day", "Specify the challenge day") orelse 1;
    // const year_option = b.option(u16, "year", "Specify the challenge year") orelse 2024;
    //
    // const path = b.fmt("{d}/day{d}/soln.zig", .{ year_option, day_option });

    const script_opt = b.option([]const u8, "script", "Specify the script to run") orelse "main.zig";

    // Add an executable target for the specified day's script
    const exe = b.addExecutable(.{
        .name = "aocZig",
        .root_module = b.createModule(.{
            .root_source_file = b.path(script_opt),
            .target = target,
            .optimize = optimize,
        }),
    });

    const qp_engine = b.dependency("qpEngine", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("qpEngine", qp_engine.module("qpEngine"));

    const orcz = b.dependency("orcz", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("orcz", orcz.module("orcz"));

    const aoc_lib = b.addModule("aocLib", .{
        .root_source_file = b.path("src/aoc.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("aoc", aoc_lib);

    const lib_tests = b.addTest(.{
        .root_module = aoc_lib,
    });
    const run_lib_tests = b.addRunArtifact(lib_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_lib_tests.step);

    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
