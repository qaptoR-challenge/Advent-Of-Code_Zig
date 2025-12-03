const std = @import("std");
const find = @import("aoc").find;

const Allocator = std.mem.Allocator;
const SHMap = std.StringHashMap;
const AList = @import("orcz").ManagedArrayList;

const DATA_FILE = ( // zig fmt: off
    "/home/qaptor/Programming/zig/aoc_z/2025/day03/data.txt"
    // "/Users/rocco/Programming/advent_zig/2025/day03/data.txt"
); // zig fmt: on

fn loadData(alloc_: Allocator, filename: []const u8) !AList([]const u8) {
    const time_start = std.time.nanoTimestamp();
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
    const content = std.mem.trimRight(u8, try file.readToEndAlloc(alloc_, std.math.maxInt(u64)), "\n");

    var data = AList([]const u8).init(alloc_);
    var rows = std.mem.splitSequence(u8, content, "\n");
    while (rows.next()) |row| {
        try data.append(row);
    }

    const time_end = std.time.nanoTimestamp();
    std.debug.print("load data time: {D}\n", .{@as(i64, @intCast(time_end - time_start))});
    return data;
}

fn puzzle1(alloc_: Allocator, data_: AList([]const u8)) !void {
    const time_start = std.time.nanoTimestamp();
    _ = alloc_;

    var sum: u32 = 0;
    var buf: [2]u8 = .{ 0, 0 };

    for (data_.items()) |item| {
        buf[0] = maxV(item[0 .. item.len - 1]);
        // const lidx = find(item, buf[0..1]).?;
        const lidx = std.mem.indexOfScalar(u8, item, buf[0]).?;
        buf[1] = maxV(item[lidx + 1 ..]);

        const joltage: u32 = try std.fmt.parseInt(u32, &buf, 10);
        sum += joltage;
    }

    const time_end = std.time.nanoTimestamp();
    std.debug.print("part 1: {d} time: {D}\n", .{ sum, @as(i64, @intCast(time_end - time_start)) });
}

// constrained greedy search with SIMD
fn puzzle2(alloc_: Allocator, data_: AList([]const u8)) !void {
    const time_start = std.time.nanoTimestamp();
    _ = alloc_;

    var sum: u64 = 0;
    // sum += 0;
    const len: usize = 12;

    for (data_.items()) |item| {
        var buf: [len]u8 = @splat(0);
        var lidx: usize = 0;
        for (0..len) |i| {
            const tail: usize = 11 - i;
            const head: usize = if (i == 0) lidx else lidx + 1;
            buf[i] = maxV(item[head .. item.len - tail]);
            lidx = head + std.mem.indexOfScalar(u8, item[head..], buf[i]).?;
        }

        const joltage: u64 = try std.fmt.parseInt(u64, &buf, 10);
        sum += joltage;
    }

    const time_end = std.time.nanoTimestamp();
    std.debug.print("part 2: {d} time: {D}\n", .{ sum, @as(i64, @intCast(time_end - time_start)) });
}

// monotonic stack solution
fn puzzle3(alloc_: Allocator, data_: AList([]const u8)) !void {
    const time_start = std.time.nanoTimestamp();
    const M: usize = 12;
    const N: usize = data_.list.items[0].len;

    var stack = try std.ArrayList(u8).initCapacity(alloc_, 100);
    defer stack.deinit(alloc_);

    var sum: u64 = 0;
    // sum += 0;

    for (data_.items()) |item| {
        var drops: usize = N - M;
        stack.clearRetainingCapacity();
        for (item) |digit| {
            while (stack.items.len > 0 and
                digit > stack.items[stack.items.len - 1] and
                drops > 0)
            {
                stack.shrinkRetainingCapacity(stack.items.len - 1);
                drops -= 1;
            }
            stack.appendAssumeCapacity(digit);
        }

        const joltage: u64 = try std.fmt.parseInt(u64, stack.items[0..12], 10);
        sum += joltage;
    }

    const time_end = std.time.nanoTimestamp();
    std.debug.print("part 3: {d} time: {D}\n", .{ sum, @as(i64, @intCast(time_end - time_start)) });
}

fn maxL(search_: []const u8) u8 {
    var max: u8 = 0;
    for (search_) |c| {
        max = @max(c, max);
    }
    return max;
}

fn maxV(search_: []const u8) u8 {
    const vlen: usize = 32;
    const V: type = @Vector(vlen, u8);
    var m: u8 = 0;
    var i: usize = 0;
    while (i + vlen <= search_.len) : (i += vlen) {
        const ptr = @as(*const [vlen]u8, @ptrCast(&search_[i])).*;
        const vec: V = @as(V, ptr);
        const temp: u8 = @reduce(.Max, vec);
        m = @max(m, temp);
    }

    if (i < search_.len) {
        var vec: [vlen]u8 = @splat(0);
        std.mem.copyForwards(u8, &vec, search_[i..]);
        const temp: u8 = @reduce(.Max, @as(V, vec));
        m = @max(m, temp);
    }

    return m;
}

pub fn main() !void {
    const time_start = std.time.nanoTimestamp();
    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("\nHello, 2025 Day 03!\n\n", .{});

    var data = try loadData(allocator, DATA_FILE);
    defer {
        // for (data.items) |row| {
        //     row.deinit();
        // }
        data.deinit();
    }

    try puzzle1(allocator, data);
    try puzzle2(allocator, data);
    try puzzle3(allocator, data);

    const time_end = std.time.nanoTimestamp();
    std.debug.print("overall time: {D}\n", .{@as(i64, @intCast(time_end - time_start))});
    std.debug.print("\nfin\n", .{});
}
