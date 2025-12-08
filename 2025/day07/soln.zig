const std = @import("std");

const Allocator = std.mem.Allocator;
// const SHMap = std.StringHashMap;
const AHSet = @import("aoc").AutoHashSet;
const AList = @import("orcz").ManagedArrayList;

const input: []const u8 = @embedFile("data.txt");
const Data = struct {
    lines: AList([]const u8),
};

fn loadData(alloc_: Allocator) !Data {
    const time_start = std.time.nanoTimestamp();
    const content = std.mem.trimRight(u8, input, "\n");

    var data: Data = .{
        .lines = AList([]const u8).init(alloc_),
    };
    var rows = std.mem.splitSequence(u8, content, "\n");
    while (rows.next()) |row| {
        try data.lines.append(row);
    }

    // try printData(data);

    const time_end = std.time.nanoTimestamp();
    std.debug.print("load data time: {D}\n", .{@as(i64, @intCast(time_end - time_start))});
    return data;
}

fn printData(data_: Data) !void {
    _ = data_;
}

fn puzzle1(alloc_: Allocator, data_: Data) !void {
    const time_start = std.time.nanoTimestamp();

    var sum: u32 = 0;

    var set: AHSet(usize) = .init(alloc_);
    var insert: AList(usize) = .init(alloc_);
    var remove: AList(usize) = .init(alloc_);
    _ = try set.insert(std.mem.indexOfScalar(u8, data_.lines.items()[0], 'S').?);
    for (2..data_.lines.len()) |i| {
        insert.clearRetainingCapacity();
        remove.clearRetainingCapacity();
        if (i % 2 == 1) continue;
        var iter = set.iterator();
        while (iter.next()) |idx| {
            if (data_.lines.items()[i][idx.*] == '^') {
                sum += 1;
                try insert.append(idx.* + 1);
                try insert.append(idx.* - 1);
                try remove.append(idx.*);
            }
        }
        for (remove.items()) |idx| {
            _ = set.remove(idx);
        }
        for (insert.items()) |idx| {
            _ = try set.insert(idx);
        }
    }

    const time_end = std.time.nanoTimestamp();
    std.debug.print("part 1: {d} time: {D}\n", .{ sum, @as(i64, @intCast(time_end - time_start)) });
}

const Beam = struct {
    idx: usize,
    count: u128,
};

fn puzzle2(alloc_: Allocator, data_: Data) !void {
    const time_start = std.time.nanoTimestamp();

    var sum: u128 = 0;
    var set: std.AutoHashMap(usize, u128) = .init(alloc_);
    var insert: AList(Beam) = .init(alloc_);
    var remove: AList(Beam) = .init(alloc_);
    const idx0: usize = std.mem.indexOfScalar(u8, data_.lines.items()[0], 'S').?;
    _ = try set.put(idx0, 1);
    for (2..data_.lines.len()) |i| {
        insert.clearRetainingCapacity();
        remove.clearRetainingCapacity();
        if (i % 2 == 1) continue;
        var iter = set.iterator();
        while (iter.next()) |beam| {
            if (data_.lines.items()[i][beam.key_ptr.*] == '^') {
                try insert.append(.{ .idx = beam.key_ptr.* + 1, .count = beam.value_ptr.* });
                try insert.append(.{ .idx = beam.key_ptr.* - 1, .count = beam.value_ptr.* });
                try remove.append(.{ .idx = beam.key_ptr.*, .count = 0 });
            }
        }
        for (remove.items()) |beam| {
            _ = set.remove(beam.idx);
        }
        for (insert.items()) |beam| {
            const gop = try set.getOrPut(beam.idx);
            if (gop.found_existing) {
                gop.value_ptr.* += beam.count;
            } else {
                gop.value_ptr.* = beam.count;
            }
        }
    }

    var iter = set.iterator();
    while (iter.next()) |beam| {
        sum += @as(u128, beam.value_ptr.*);
    }

    const time_end = std.time.nanoTimestamp();
    std.debug.print("part 2: {d} time: {D}\n", .{ sum, @as(i64, @intCast(time_end - time_start)) });
}

pub fn main() !void {
    const time_start = std.time.nanoTimestamp();
    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("\nHello, 2025 Day 07!\n\n", .{});

    const data = try loadData(allocator);

    try puzzle1(allocator, data);
    try puzzle2(allocator, data);

    const time_end = std.time.nanoTimestamp();
    std.debug.print("overall time: {D}\n", .{@as(i64, @intCast(time_end - time_start))});
    std.debug.print("\nfin\n", .{});
}
