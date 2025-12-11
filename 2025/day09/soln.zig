const std = @import("std");

const Allocator = std.mem.Allocator;
const SHMap = std.StringHashMap;
const AList = @import("orcz").ManagedArrayList;
const Vec2 = @import("qpEngine").math.Vector(i32, 2);

const input: []const u8 = @embedFile("data.txt");
const Data = struct {
    tiles: AList(Vec2),
};

fn loadData(alloc_: Allocator) !Data {
    const time_start = std.time.nanoTimestamp();
    const content = std.mem.trimRight(u8, input, "\n");

    var data: Data = .{
        .tiles = .init(alloc_),
    };
    var rows = std.mem.splitSequence(u8, content, "\n");
    while (rows.next()) |row| {
        var components = std.mem.tokenizeScalar(u8, row, ',');
        try data.tiles.append(Vec2.from(.{
            try std.fmt.parseInt(i32, components.next().?, 10),
            try std.fmt.parseInt(i32, components.next().?, 10),
        }));
    }

    // try printData(data);

    const time_end = std.time.nanoTimestamp();
    std.debug.print("load data time: {D}\n", .{@as(i64, @intCast(time_end - time_start))});
    return data;
}

fn printData(data_: Data) !void {
    for (data_.tiles.items()) |tile| {
        std.debug.print("{any}\n", .{tile});
    }
}

const TPair = struct {
    a: usize,
    b: usize,
    c: u64,

    pub fn compare(ctx_: @TypeOf(.{}), lhs: TPair, rhs: TPair) bool {
        _ = ctx_;
        return lhs.c > rhs.c;
    }
};

fn puzzle1(alloc_: Allocator, data_: Data) !void {
    const time_start = std.time.nanoTimestamp();

    var sum: u64 = 0;
    var bounds: AList(TPair) = .init(alloc_);
    for (0..data_.tiles.len() - 1) |i| {
        for (i + 1..data_.tiles.len()) |j| {
            var s = data_.tiles.items()[i];
            var o = data_.tiles.items()[j];
            try bounds.append(.{
                .a = i,
                .b = j,
                .c = s.content(u64, o.summated(o.subtracted(s).signed())),
            });
        }
    }
    std.mem.sort(TPair, bounds.items(), .{}, TPair.compare);

    sum = @intCast(bounds.items()[0].c);
    const time_end = std.time.nanoTimestamp();
    std.debug.print("part 1: {d} time: {D}\n", .{ sum, @as(i64, @intCast(time_end - time_start)) });
}

fn puzzle2(alloc_: Allocator, data_: Data) !void {
    const time_start = std.time.nanoTimestamp();

    var sum: u64 = 0;
    var bounds: AList(TPair) = .init(alloc_);
    for (0..data_.tiles.len() - 1) |i| {
        for (i + 1..data_.tiles.len()) |j| {
            var s = data_.tiles.items()[i];
            var o = data_.tiles.items()[j];
            try bounds.append(.{
                .a = i,
                .b = j,
                .c = s.content(u64, o.summated(o.subtracted(s).signed())),
            });
        }
    }
    std.mem.sort(TPair, bounds.items(), .{}, TPair.compare);

    var lines: AList(TPair) = .init(alloc_);
    for (0..data_.tiles.len()) |i| {
        try lines.append(.{
            .a = i,
            .b = (i + 1) % data_.tiles.len(),
            .c = 0,
        });
    }

    blk: for (bounds.items()) |b| {
        var s = data_.tiles.items()[b.a];
        const o = data_.tiles.items()[b.b];
        const min = s.minimumOfed(o).ptr().summated(.{ 1, 1 });
        const max = s.maximumOfed(o).ptr().subtracted(.{ 1, 1 });
        for (lines.items()) |l| {
            var p1 = data_.tiles.items()[l.a];
            const p2 = data_.tiles.items()[l.b];
            const seg_min = p1.minimumOfed(p2);
            const seg_max = p1.maximumOfed(p2);
            const outside = @reduce(.Or, seg_max.lesser(min)) or @reduce(.Or, seg_min.greater(max));

            if (!outside) continue :blk;
        }

        sum = b.c;
        break :blk;
    }

    const time_end = std.time.nanoTimestamp();
    std.debug.print("part 2: {d} time: {D}\n", .{ sum, @as(i64, @intCast(time_end - time_start)) });
}

pub fn main() !void {
    const time_start = std.time.nanoTimestamp();
    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("\nHello, 2025 Day 09!\n\n", .{});

    const data = try loadData(allocator);

    try puzzle1(allocator, data);
    try puzzle2(allocator, data);

    const time_end = std.time.nanoTimestamp();
    std.debug.print("overall time: {D}\n", .{@as(i64, @intCast(time_end - time_start))});
    std.debug.print("\nfin\n", .{});
}
