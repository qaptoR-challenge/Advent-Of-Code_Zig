const std = @import("std");

const Allocator = std.mem.Allocator;
const SHMap = std.StringHashMap;
const AList = @import("orcz").ManagedArrayList;

const DATA_FILE = ( // zig fmt: off
    "/home/qaptor/Programming/zig/aoc_z/2025/day01/data.txt"
    // "/Users/rocco/Programming/advent_zig/2025/day01/data.txt"
); // zig fmt: on

fn loadData(alloc_: Allocator, filename: []const u8) !AList([]const u8) {
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
    const content = std.mem.trimRight(u8, try file.readToEndAlloc(alloc_, std.math.maxInt(u64)), "\n");

    var data = AList([]const u8).init(alloc_);
    var rows = std.mem.splitSequence(u8, content, "\n");
    while (rows.next()) |row| {
        try data.append(row);
    }
    return data;
}

fn puzzle1(alloc_: Allocator, data_: AList([]const u8)) !void {
    const time_start = std.time.milliTimestamp();
    _ = alloc_;

    var sum: u32 = 0;
    var idx: i32 = 50;

    for (data_.items()) |item| {
        const distance = try std.fmt.parseInt(i32, item[1..], 10);
        idx = switch (item[0]) {
            'L' => @mod(idx - distance, 100),
            'R' => @mod(idx + distance, 100),
            else => unreachable,
        };
        if (idx == 0) sum += 1;
    }

    const time_end = std.time.milliTimestamp();
    std.debug.print("part 1: {d} time: {d}\n", .{ sum, time_end - time_start });
}

fn puzzle2(alloc_: Allocator, data_: AList([]const u8)) !void {
    const time_start = std.time.milliTimestamp();
    _ = alloc_;

    var sum: i32 = 0;
    var idx: i32 = 50;

    for (data_.items()) |item| {
        var distance = try std.fmt.parseInt(i32, item[1..], 10);
        if (distance == 0) continue;

        sum += @divTrunc(distance, 100);
        distance = @mod(distance, 100);

        idx = blk: switch (item[0]) {
            'L' => {
                if (idx != 0 and idx - distance < 0) sum += 1;
                break :blk @mod(idx - distance, 100);
            },
            'R' => {
                if (idx != 0 and idx + distance > 100) sum += 1;
                break :blk @mod(idx + distance, 100);
            },
            else => unreachable,
        };
        if (idx == 0) sum += 1;
    }
    const time_end = std.time.milliTimestamp();
    std.debug.print("part 2: {d} time: {d}\n", .{ sum, time_end - time_start });
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("\nHello, 2025 Day 01!\n\n", .{});

    var data = try loadData(allocator, DATA_FILE);
    defer {
        data.deinit();
    }

    try puzzle1(allocator, data);
    try puzzle2(allocator, data);

    std.debug.print("\nfin\n", .{});
}
