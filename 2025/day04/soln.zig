const std = @import("std");
const qp = @import("qpEngine");

const Allocator = std.mem.Allocator;
const AList = @import("orcz").ManagedArrayList;
const Vec2 = qp.math.Vector(i32, 2);
const V2 = qp.math.Vector2(usize);
const HMap = std.AutoArrayHashMap(Vec2, u8);

const DATA_FILE = ( // zig fmt: off
    "/home/qaptor/Programming/zig/aoc_z/2025/day04/data.txt"
    // "/Users/rocco/Programming/advent_zig/2025/day04/data.txt"
); // zig fmt: on
const input_data: []const u8 = @embedFile("data.txt");

var drows: usize = undefined;
var dcols: usize = undefined;
var vlist: [8]Vec2 = undefined;

fn loadData(alloc_: Allocator, filename: []const u8) !HMap {
    const time_start = std.time.nanoTimestamp();
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
    const content = std.mem.trimRight(u8, try file.readToEndAlloc(alloc_, std.math.maxInt(u64)), "\n");

    var data = HMap.init(alloc_);
    var rows = std.mem.splitSequence(u8, content, "\n");
    dcols = rows.peek().?.len;
    var r: usize = 0;
    while (rows.next()) |row| : (r += 1) {
        for (row, 0..) |d, c| {
            const vec = Vec2.from(.{ c, r });
            try data.put(vec, d);
        }
    }
    drows = r;

    // try printData(data);

    const time_end = std.time.nanoTimestamp();
    std.debug.print("load data time: {D}\n", .{@as(i64, @intCast(time_end - time_start))});
    return data;
}

fn printData(data_: HMap) !void {
    for (0..drows) |row| {
        for (0..dcols) |col| {
            const vec = Vec2.from(.{ col, row });
            std.debug.print("{c}", .{data_.get(vec).?});
        }
        std.debug.print("\n", .{});
    }
    std.debug.print("\n", .{});
}

fn puzzle1(alloc_: Allocator, data_: *HMap) !void {
    const time_start = std.time.nanoTimestamp();
    _ = alloc_;

    var sum: u32 = 0;

    for (0..drows) |row| {
        for (0..dcols) |col| {
            var vec = Vec2.from(.{ col, row });
            if (data_.get(vec).? == '.') continue;
            var count: u8 = 0;
            for (vlist) |add| {
                const check: Vec2 = vec.summated(add);
                if (data_.get(check)) |d| {
                    if (d == '@') count += 1;
                }
            }
            if (count < 4) {
                sum += 1;
            }
        }
    }

    const time_end = std.time.nanoTimestamp();
    std.debug.print("part 1: {d} time: {D}\n", .{ sum, @as(i64, @intCast(time_end - time_start)) });
}

fn puzzle2(alloc_: Allocator, data_: *HMap) !void {
    const time_start = std.time.nanoTimestamp();

    var sum: u32 = 0;

    var queue: AList(Vec2) = AList(Vec2).init(alloc_);
    while (true) {
        queue.clearRetainingCapacity();
        for (0..drows) |row| {
            for (0..dcols) |col| {
                var vec = Vec2.from(.{ col, row });
                if (data_.get(vec).? == '.') continue;
                var count: u8 = 0;
                for (vlist) |add| {
                    const check: Vec2 = vec.summated(add);
                    if (data_.get(check)) |d| {
                        if (d == '@') count += 1;
                    }
                }
                if (count < 4) {
                    try queue.append(vec);
                    sum += 1;
                }
            }
        }
        if (queue.len() == 0) break;
        for (queue.items()) |vec| {
            try data_.put(vec, '.');
        }
    }

    const time_end = std.time.nanoTimestamp();
    std.debug.print("part 2: {d} time: {D}\n", .{ sum, @as(i64, @intCast(time_end - time_start)) });
}

fn puzzle3(alloc_: Allocator, data_: *HMap) !void {
    const time_start = std.time.nanoTimestamp();

    var input: []u8 = try alloc_.dupe(u8, input_data);
    var sum: u32 = 0;

    const v32: type = @Vector(32, u8);
    const m32: v32 = @splat('@');

    var queue: AList(Vec2) = AList(Vec2).init(alloc_);
    const cols: usize = dcols + 1;
    while (true) {
        queue.clearRetainingCapacity();
        for (0..drows) |row| {
            var col: usize = 0;
            const rstart = row * cols;

            while (true) {
                if (col >= dcols) break;
                const flag: bool = col + 32 < dcols;
                const update: usize = 32;

                const chunk: v32 = if (flag) blk: {
                    break :blk input[rstart + col ..][0..update].*;
                } else blk: {
                    var splat: [update]u8 = @splat('.');
                    std.mem.copyForwards(u8, &splat, input[rstart + col ..][0 .. dcols - col]);
                    break :blk splat;
                };
                var mask: u32 = @bitCast(chunk == m32);

                while (mask != 0) {
                    const bpos = @ctz(mask);
                    const acol: usize = col + bpos;
                    var vec = Vec2.from(.{ acol, row });
                    var count: u8 = 0;
                    for (vlist) |add| {
                        const check: Vec2 = vec.summated(add);
                        if (data_.get(check)) |d| {
                            if (d == '@') count += 1;
                        }
                    }
                    if (count < 4) {
                        try queue.append(vec);
                        sum += 1;
                    }
                    mask &= mask - 1;
                }

                col += update;
            }
        }
        if (queue.len() == 0) break;
        for (queue.items()) |vec| {
            try data_.put(vec, '.');
            const x: usize = @intCast(vec.data[0]);
            const y: usize = @intCast(vec.data[1]);
            input[y * cols + x] = '.';
        }
    }

    const time_end = std.time.nanoTimestamp();
    std.debug.print("part 3: {d} time: {D}\n", .{ sum, @as(i64, @intCast(time_end - time_start)) });
}

pub fn main() !void {
    const time_start = std.time.nanoTimestamp();
    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("\nHello, 2025 Day 04!\n\n", .{});

    vlist = .{ // zig fmt: off
        Vec2.from(.{ -1, -1 }),
        Vec2.from(.{  0, -1 }),
        Vec2.from(.{  1, -1 }),
        Vec2.from(.{ -1,  0 }),
        Vec2.from(.{  1,  0 }),
        Vec2.from(.{ -1,  1 }),
        Vec2.from(.{  0,  1 }),
        Vec2.from(.{  1,  1 }),
    }; // zig fmt: on

    var data = try loadData(allocator, DATA_FILE);
    defer {
        // for (data.items) |row| {
        //     row.deinit();
        // }
        data.deinit();
    }

    try puzzle1(allocator, &data);
    try puzzle2(allocator, &data);
    try puzzle3(allocator, &data);

    const time_end = std.time.nanoTimestamp();
    std.debug.print("overall time: {D}\n", .{@as(i64, @intCast(time_end - time_start))});
    std.debug.print("\nfin\n", .{});
}
