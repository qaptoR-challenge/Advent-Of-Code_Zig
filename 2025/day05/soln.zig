const std = @import("std");

const Allocator = std.mem.Allocator;
const SHMap = std.StringHashMap;
const AList = @import("orcz").ManagedArrayList;

const input: []const u8 = @embedFile("data.txt");
const Data = struct {
    ranges: AList(Range),
    ids: AList(usize),
};
const Range = struct {
    start: usize,
    end: usize,

    fn lessThan(context_: @TypeOf(.{}), lhs: Range, rhs: Range) bool {
        _ = context_;
        return lhs.start < rhs.start;
    }
};

fn loadData(alloc_: Allocator) !Data {
    const time_start = std.time.nanoTimestamp();
    const content = std.mem.trimRight(u8, input, "\n");

    var data: Data = .{
        .ranges = AList(Range).init(alloc_),
        .ids = AList(usize).init(alloc_),
    };
    var sections = std.mem.splitSequence(u8, content, "\n\n");
    var ranges = std.mem.splitScalar(u8, sections.next().?, '\n');
    var ids = std.mem.splitScalar(u8, sections.next().?, '\n');

    while (ranges.next()) |range| {
        var terminals = std.mem.splitScalar(u8, range, '-');
        try data.ranges.append(.{
            .start = try std.fmt.parseInt(usize, terminals.next().?, 10),
            .end = try std.fmt.parseInt(usize, terminals.next().?, 10),
        });
    }
    while (ids.next()) |id| {
        try data.ids.append(try std.fmt.parseInt(usize, id, 10));
    }

    // try printData(data);

    const time_end = std.time.nanoTimestamp();
    std.debug.print("load data time: {D}\n", .{@as(i64, @intCast(time_end - time_start))});
    return data;
}

fn printData(data_: Data) !void {
    for (data_.ranges.items()) |range| {
        std.debug.print("{d}-{d}\n", .{ range.start, range.end });
    }
    std.debug.print("\n", .{});
    for (data_.ids.items()) |id| {
        std.debug.print("{d}\n", .{id});
    }
    std.debug.print("\n", .{});
}

fn puzzle1(alloc_: Allocator, data_: Data) !void {
    const time_start = std.time.nanoTimestamp();
    _ = alloc_;

    var sum: u32 = 0;

    for (data_.ids.items()) |id| {
        for (data_.ranges.items()) |range| {
            if (range.start <= id and id <= range.end) {
                sum += 1;
                break;
            }
        }
    }

    const time_end = std.time.nanoTimestamp();
    std.debug.print("part 1: {d} time: {D}\n", .{ sum, @as(i64, @intCast(time_end - time_start)) });
}

fn puzzle2(alloc_: Allocator, data_: *Data) !void {
    const time_start = std.time.nanoTimestamp();

    var sum: u64 = 0;

    std.mem.sort(Range, data_.ranges.list.items, .{}, Range.lessThan);
    var ranges = AList(Range).init(alloc_);
    for (data_.ranges.items()) |newrange| {
        if (ranges.pop()) |lastrange| {
            var r: Range = .{ .start = lastrange.start, .end = lastrange.end };
            if (newrange.start <= lastrange.end) {
                if (lastrange.end < newrange.end) {
                    r.end = newrange.end;
                }
                try ranges.append(r);
            } else {
                try ranges.append(lastrange);
                try ranges.append(newrange);
            }
        } else {
            try ranges.append(newrange);
        }
    }

    for (ranges.items()) |range| {
        sum += 1 + @as(u64, @intCast(range.end - range.start));
    }

    const time_end = std.time.nanoTimestamp();
    std.debug.print("part 2: {d} time: {D}\n", .{ sum, @as(i64, @intCast(time_end - time_start)) });
}

pub fn main() !void {
    const time_start = std.time.nanoTimestamp();
    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("\nHello, 2025 Day 05!\n\n", .{});

    var data = try loadData(allocator);
    defer {
        // for (data.items) |row| {
        //     row.deinit();
        // }
        data.ranges.deinit();
        data.ids.deinit();
    }

    try puzzle1(allocator, data);
    try puzzle2(allocator, &data);

    const time_end = std.time.nanoTimestamp();
    std.debug.print("overall time: {D}\n", .{@as(i64, @intCast(time_end - time_start))});
    std.debug.print("\nfin\n", .{});
}
