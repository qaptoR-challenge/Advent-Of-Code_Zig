const std = @import("std");

const Allocator = std.mem.Allocator;
const SHMap = std.StringHashMap;
const AList = @import("orcz").ManagedArrayList;

const reduce = @import("aoc").functional.reduce;

const input: []const u8 = @embedFile("data.txt");
const Data1 = struct {
    vals: AList(AList(u64)),
    ops: AList([]const u8),
};
const Data2 = struct {
    vals: AList([][]u8),
    ops: AList([]const u8),
};
const Range = struct {
    start: usize,
    end: usize,
};

var eq_len: usize = 0;
var math_len: usize = 0;

fn loadData1(alloc_: Allocator) !Data1 {
    const time_start = std.time.nanoTimestamp();
    const content = std.mem.trimRight(u8, input, "\n");

    var data: Data1 = .{
        .vals = AList(AList(u64)).init(alloc_),
        .ops = AList([]const u8).init(alloc_),
    };
    var vcount: usize = std.mem.count(u8, content, "\n");
    var rows = std.mem.splitSequence(u8, content, "\n");
    while (rows.next()) |row| {
        var v = AList(u64).init(alloc_);
        var vals = std.mem.tokenizeScalar(u8, row, ' ');
        while (vals.next()) |val| {
            try v.append(try std.fmt.parseInt(u64, val, 10));
        }
        try data.vals.append(v);
        vcount -= 1;
        if (vcount == 0) break;
    }
    if (rows.next()) |row| {
        var ops = std.mem.tokenizeScalar(u8, row, ' ');
        while (ops.next()) |val| {
            try data.ops.append(val);
        }
    }
    eq_len = data.vals.len();
    math_len = data.ops.len();

    // try printData1(data);

    const time_end = std.time.nanoTimestamp();
    std.debug.print("load data time: {D}\n", .{@as(i64, @intCast(time_end - time_start))});
    return data;
}

fn printData1(data_: Data1) !void {
    for (data_.vals.items()) |row| {
        for (row.items()) |val| {
            std.debug.print("{d: <3} ", .{val});
        }
        std.debug.print("\n", .{});
    }
    for (data_.ops.items()) |val| {
        std.debug.print("{s: <3} ", .{val});
    }
    std.debug.print("\n", .{});
}

fn loadData2(alloc_: Allocator) !Data2 {
    const time_start = std.time.nanoTimestamp();
    const content = std.mem.trimRight(u8, input, "\n");
    const opstart = std.mem.lastIndexOfScalar(u8, content, '\n').? + 1;
    const numlen = std.mem.count(u8, content, "\n");

    var ranges: AList(Range) = .init(alloc_);
    var data: Data2 = .{
        .vals = AList([][]u8).init(alloc_),
        .ops = AList([]const u8).init(alloc_),
    };

    var idx: usize = 0;
    while (std.mem.indexOfAny(u8, content[opstart + idx + 1 ..], "+*")) |pos| {
        try ranges.append(.{ .start = idx, .end = idx + pos });
        idx += pos + 1;
    }
    try ranges.append(.{ .start = idx, .end = content.len - opstart });

    for (ranges.items()) |range| {
        const len = range.end - range.start;
        var vals = try alloc_.alloc([]u8, len);
        for (0..len) |i| {
            vals[i] = try alloc_.alloc(u8, numlen);
        }
        var iter = std.mem.splitScalar(u8, content, '\n');
        var iidx: usize = 0;
        while (iter.next()) |line| {
            for (range.start..range.end, 0..) |i, j| {
                vals[j][iidx] = line[i];
            }
            iidx += 1;
            if (iidx == numlen) break;
        }
        try data.vals.append(vals);
    }

    var ops_iter = std.mem.tokenizeScalar(u8, content[opstart..], ' ');
    while (ops_iter.next()) |val| {
        try data.ops.append(val);
    }

    // try printData2(data);

    const time_end = std.time.nanoTimestamp();
    std.debug.print("load data2 time: {D}\n", .{@as(i64, @intCast(time_end - time_start))});
    return data;
}

fn printData2(data_: Data2) !void {
    for (data_.vals.items(), 0..) |row, i| {
        for (row) |val| {
            std.debug.print("{s} ", .{val[0..]});
        }
        std.debug.print("{s}\n", .{data_.ops.items()[i]});
    }
}

fn add(a: u64, b: u64) u64 {
    return a + b;
}

fn mul(a: u64, b: u64) u64 {
    return a * b;
}

fn puzzle1(alloc_: Allocator, data_: Data1) !void {
    const time_start = std.time.nanoTimestamp();

    var sum: u64 = 0;

    var equation: AList(u64) = .init(alloc_);
    try equation.ensureTotalCapacity(eq_len);
    for (0..math_len) |i| {
        equation.clearRetainingCapacity();
        for (data_.vals.items()) |row| {
            try equation.append(row.items()[i]);
        }
        switch (data_.ops.items()[i][0]) {
            '+' => {
                sum += reduce(u64, u64, equation.items(), 0, add);
            },
            '*' => {
                sum += reduce(u64, u64, equation.items(), 1, mul);
            },
            else => unreachable,
        }
    }

    const time_end = std.time.nanoTimestamp();
    std.debug.print("part 1: {d} time: {D}\n", .{ sum, @as(i64, @intCast(time_end - time_start)) });
}

fn puzzle2(alloc_: Allocator, data_: Data2) !void {
    const time_start = std.time.nanoTimestamp();

    var sum: u64 = 0;

    var equation: AList(u64) = .init(alloc_);
    for (data_.vals.items(), 0..) |row, i| {
        equation.clearRetainingCapacity();
        for (row) |val| {
            try equation.append(try std.fmt.parseInt(u64, std.mem.trim(u8, val[0..], " "), 10));
        }
        switch (data_.ops.items()[i][0]) {
            '+' => {
                sum += reduce(u64, u64, equation.items(), 0, add);
            },
            '*' => {
                sum += reduce(u64, u64, equation.items(), 1, mul);
            },
            else => unreachable,
        }
    }

    const time_end = std.time.nanoTimestamp();
    std.debug.print("part 2: {d} time: {D}\n", .{ sum, @as(i64, @intCast(time_end - time_start)) });
}

pub fn main() !void {
    const time_start = std.time.nanoTimestamp();
    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("\nHello, 20$$ Day @@!\n\n", .{});

    const data1 = try loadData1(allocator);
    const data2 = try loadData2(allocator);
    // defer {
    //     for (data1.vals.items()) |*row| {
    //         row.deinit();
    //     }
    //     data1.ops.deinit();
    // }

    try puzzle1(allocator, data1);
    try puzzle2(allocator, data2);

    const time_end = std.time.nanoTimestamp();
    std.debug.print("overall time: {D}\n", .{@as(i64, @intCast(time_end - time_start))});
    std.debug.print("\nfin\n", .{});
}
