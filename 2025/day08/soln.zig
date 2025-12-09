const std = @import("std");
const math = @import("qpEngine").math;

const Allocator = std.mem.Allocator;
// const SHMap = std.StringHashMap;
const AHSet = @import("aoc").AutoHashSet;
const AList = @import("orcz").ManagedArrayList;
const Vec3 = math.Vector(i64, 3);

const input: []const u8 = @embedFile("data.txt");
const Data = struct {
    juncs: AList(Vec3),
};

fn loadData(alloc_: Allocator) !Data {
    const time_start = std.time.nanoTimestamp();
    const content = std.mem.trimRight(u8, input, "\n");

    var data: Data = .{
        .juncs = .init(alloc_),
    };
    var rows = std.mem.splitSequence(u8, content, "\n");
    while (rows.next()) |row| {
        var juncs = std.mem.tokenizeScalar(u8, row, ',');
        try data.juncs.append(Vec3.from(.{
            try std.fmt.parseInt(i64, juncs.next().?, 10),
            try std.fmt.parseInt(i64, juncs.next().?, 10),
            try std.fmt.parseInt(i64, juncs.next().?, 10),
        }));
    }

    // try printData(data);

    const time_end = std.time.nanoTimestamp();
    std.debug.print("load data time: {D}\n", .{@as(i64, @intCast(time_end - time_start))});
    return data;
}

fn printData(data_: Data) !void {
    for (data_.juncs.items()) |junc| {
        std.debug.print("{d},{d},{d}\n", .{ junc.x, junc.y, junc.z });
    }
}

const JPair = struct {
    a: usize,
    b: usize,
    d: i64,

    fn lessThan(context_: @TypeOf(.{}), lhs: JPair, rhs: JPair) bool {
        _ = context_;
        return lhs.d < rhs.d;
    }
};

fn circsLessThan(context_: @TypeOf(.{}), lhs: AHSet(Vec3), rhs: AHSet(Vec3)) bool {
    _ = context_;
    return lhs.count() > rhs.count();
}

fn puzzle1(alloc_: Allocator, data_: Data) !void {
    const time_start = std.time.nanoTimestamp();

    var sum: u64 = 1;

    const juncs = data_.juncs.items();
    var dists: AList(JPair) = .init(alloc_);
    for (0..data_.juncs.len() - 1) |i| {
        for (i + 1..data_.juncs.len()) |j| {
            try dists.append(.{
                .a = i,
                .b = j,
                .d = juncs[i].distanceToSq(juncs[j]),
            });
        }
    }
    std.mem.sort(JPair, dists.items(), .{}, JPair.lessThan);

    const pair_count: usize = 1000;
    var circs: AList(AHSet(Vec3)) = .init(alloc_);
    try circs.append(.init(alloc_));
    for (0..pair_count) |k| {
        var jai: ?usize = null;
        var jbi: ?usize = null;
        for (circs.items(), 0..) |*circ, i| {
            if (circ.contains(juncs[dists.items()[k].a])) {
                jai = i;
            }
            if (circ.contains(juncs[dists.items()[k].b])) {
                jbi = i;
            }
        }

        if (jai == null and jbi == null) { // new circuit
            if (circs.len() != 1) try circs.append(.init(alloc_));
            const new_circ_idx = circs.len() - 1;
            _ = try circs.items()[new_circ_idx].insert(juncs[dists.items()[k].a]);
            _ = try circs.items()[new_circ_idx].insert(juncs[dists.items()[k].b]);
        } else if (jai == jbi) { // both in same circuit
            continue;
        } else if (jai != null and jbi == null) { // add b to a circuit
            _ = try circs.items()[jai.?].insert(juncs[dists.items()[k].b]);
        } else if (jai == null and jbi != null) { // add a to b circuit
            _ = try circs.items()[jbi.?].insert(juncs[dists.items()[k].a]);
        } else { // merge
            const to_merge = circs.items()[jbi.?];
            var iter = to_merge.iterator();
            while (iter.next()) |junc| {
                _ = try circs.items()[jai.?].insert(junc.*);
            }
            _ = circs.list.swapRemove(jbi.?);
        }
    }
    std.mem.sort(AHSet(Vec3), circs.items(), .{}, circsLessThan);
    const top_count: usize = 3;
    for (0..top_count) |k_| {
        sum *= @as(u64, circs.items()[k_].count());
    }

    const time_end = std.time.nanoTimestamp();
    std.debug.print("part 1: {d} time: {D}\n", .{ sum, @as(i64, @intCast(time_end - time_start)) });
}

fn puzzle2(alloc_: Allocator, data_: Data) !void {
    const time_start = std.time.nanoTimestamp();

    var sum: i64 = 1;

    const juncs = data_.juncs.items();
    var dists: AList(JPair) = .init(alloc_);
    for (0..data_.juncs.len() - 1) |i| {
        for (i + 1..data_.juncs.len()) |j| {
            try dists.append(.{
                .a = i,
                .b = j,
                .d = juncs[i].distanceToSq(juncs[j]),
            });
        }
    }
    std.mem.sort(JPair, dists.items(), .{}, JPair.lessThan);

    var circs: AList(AHSet(Vec3)) = .init(alloc_);
    try circs.append(.init(alloc_));
    const first: JPair = jlk: for (0..dists.len()) |k| {
        var jai: ?usize = null;
        var jbi: ?usize = null;
        for (circs.items(), 0..) |*circ, i| {
            if (circ.contains(juncs[dists.items()[k].a])) {
                jai = i;
            }
            if (circ.contains(juncs[dists.items()[k].b])) {
                jbi = i;
            }
        }

        if (jai == null and jbi == null) { // new circuit
            if (circs.len() != 1) try circs.append(.init(alloc_));
            const new_circ_idx = circs.len() - 1;
            _ = try circs.items()[new_circ_idx].insert(juncs[dists.items()[k].a]);
            _ = try circs.items()[new_circ_idx].insert(juncs[dists.items()[k].b]);
        } else if (jai == jbi) { // both in same circuit
        } else if (jai != null and jbi == null) { // add b to a circuit
            _ = try circs.items()[jai.?].insert(juncs[dists.items()[k].b]);
        } else if (jai == null and jbi != null) { // add a to b circuit
            _ = try circs.items()[jbi.?].insert(juncs[dists.items()[k].a]);
        } else { // merge
            const to_merge = circs.items()[jbi.?];
            var iter = to_merge.iterator();
            while (iter.next()) |junc| {
                _ = try circs.items()[jai.?].insert(junc.*);
            }
            _ = circs.list.swapRemove(jbi.?);
        }
        if (circs.len() == 1 and circs.items()[0].count() == juncs.len) {
            break :jlk dists.items()[k];
        }
    } else JPair{ .a = undefined, .b = undefined, .d = undefined };

    sum *= juncs[first.a].data[0] * juncs[first.b].data[0];

    const time_end = std.time.nanoTimestamp();
    std.debug.print("part 2: {d} time: {D}\n", .{ sum, @as(i64, @intCast(time_end - time_start)) });
}

pub fn main() !void {
    const time_start = std.time.nanoTimestamp();
    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("\nHello, 2025 Day 08!\n\n", .{});

    const data = try loadData(allocator);

    try puzzle1(allocator, data);
    try puzzle2(allocator, data);

    const time_end = std.time.nanoTimestamp();
    std.debug.print("overall time: {D}\n", .{@as(i64, @intCast(time_end - time_start))});
    std.debug.print("\nfin\n", .{});
}
