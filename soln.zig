const std = @import("std");

const Allocator = std.mem.Allocator;
const SHMap = std.StringHashMap;
const AList = @import("orcz").ManagedArrayList;

const DATA_FILE = ( // zig fmt: off
    "/home/qaptor/Programming/zig/aoc_z/2024/day01/data.txt"
    // "/Users/rocco/Programming/advent_zig/2024/day00/data.txt"
); // zig fmt: on

fn loadData(alloc_: Allocator, filename: []const u8) !AList([]const u8) {
    const time_start = std.time.nanoTimestamp();
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
    const content = std.mem.trimRight(u8, try file.readToEndAlloc(alloc_, std.math.maxInt(u64)), "\n");
    defer alloc_.free(content);

    var data = AList([]const u8).init(alloc_);
    var rows = std.mem.splitSequence(u8, content, "\n");
    while (rows.next()) |row| {
        try data.append(row);
    }

    const time_end = std.time.nanoTimestamp();
    std.debug.print("overall time: {D}\n", .{@as(i64, @intCast(time_end - time_start))});
    return data;
}

fn test_data1(alloc_: Allocator, data_: AList([]const u8)) !void {
    const time_start = std.time.nanoTimestamp();
    _ = alloc_;
    _ = data_;

    var sum: u32 = 0;
    sum += 0;

    const time_end = std.time.nanoTimestamp();
    std.debug.print("part 1: {d} time: {D}\n", .{ sum, @as(i64, @intCast(time_end - time_start)) });
}

fn test_data2(alloc_: Allocator, data_: AList([]const u8)) !void {
    const time_start = std.time.nanoTimestamp();
    _ = alloc_;
    _ = data_;

    var sum: i32 = 0;
    sum += 0;

    const time_end = std.time.nanoTimestamp();
    std.debug.print("part 2: {d} time: {D}\n", .{ sum, @as(i64, @intCast(time_end - time_start)) });
}

pub fn main() !void {
    const time_start = std.time.nanoTimestamp();
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("\nHello, Day 00!\n\n", .{});

    var data = try loadData(allocator, DATA_FILE);
    defer {
        // for (data.items) |row| {
        //     row.deinit();
        // }
        data.deinit();
    }

    try test_data1(allocator, data);
    try test_data2(allocator, data);

    const time_end = std.time.nanoTimestamp();
    std.debug.print("overall time: {D}\n", .{@as(i64, @intCast(time_end - time_start))});
    std.debug.print("\nfin\n", .{});
}
