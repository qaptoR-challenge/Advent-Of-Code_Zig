const std = @import("std");
const qp = @import("qpEngine");

const Allocator = std.mem.Allocator;
const SHMap = std.StringHashMap;
const AList = @import("orcz").ManagedArrayList;

const Regex = qp.re.Regex;
const RegexMatch = qp.re.RegexMatch;

const DATA_FILE = ( // zig fmt: off
    "/home/qaptor/Programming/zig/aoc_z/2025/day02/data.txt"
    // "/Users/rocco/Programming/advent_zig/2024/day00/data.txt"
); // zig fmt: on

const Range = struct {
    start: u64,
    end: u64,
};

fn loadData(alloc_: Allocator, filename: []const u8) !AList(Range) {
    const time_start = std.time.nanoTimestamp();
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
    const content = std.mem.trimRight(u8, try file.readToEndAlloc(alloc_, std.math.maxInt(u64)), "\n");
    defer alloc_.free(content);

    var data = AList(Range).init(alloc_);
    var ranges = std.mem.splitScalar(u8, content, ',');
    while (ranges.next()) |range| {
        var iter = std.mem.tokenizeScalar(u8, range, '-');
        const r: Range = .{
            .start = try std.fmt.parseInt(u64, iter.next().?, 10),
            .end = try std.fmt.parseInt(u64, iter.next().?, 10),
        };
        try data.append(r);
    }

    const time_end = std.time.nanoTimestamp();
    std.debug.print("load data time: {D}\n", .{@as(i64, @intCast(time_end - time_start))});
    return data;
}

fn puzzle1(alloc_: Allocator, data_: AList(Range)) !void {
    const time_start = std.time.nanoTimestamp();

    var sum: u64 = 0;
    var buf: [256]u8 = undefined;
    var idreg: Regex = try Regex.from(
        \\^(\d+)\1$
    , false, alloc_);
    for (data_.items()) |item| {
        for (item.start..item.end + 1) |id| {
            const ids: []const u8 = try std.fmt.bufPrint(&buf, "{d}", .{id});
            const idmatch: ?RegexMatch = idreg.search(ids, null, null);
            if (idmatch != null) {
                sum += id;
            }
        }
    }

    const time_end = std.time.nanoTimestamp();
    std.debug.print("part 1: {d} time: {D}\n", .{ sum, @as(i64, @intCast(time_end - time_start)) });
}

fn puzzle2(alloc_: Allocator, data_: AList(Range)) !void {
    const time_start = std.time.nanoTimestamp();

    var sum: u64 = 0;
    var buf: [256]u8 = undefined;
    var idreg: Regex = try Regex.from(
        \\^(\d+)\1+$
    , false, alloc_);

    for (data_.items()) |item| {
        for (item.start..item.end + 1) |id| {
            const ids: []const u8 = try std.fmt.bufPrint(&buf, "{d}", .{id});
            const idmatch: ?RegexMatch = idreg.search(ids, null, null);
            if (idmatch != null) {
                sum += id;
            }
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

    std.debug.print("\nHello, 2025 Day 02!\n\n", .{});

    var data = try loadData(allocator, DATA_FILE);
    defer {
        data.deinit();
    }

    try puzzle1(allocator, data);
    try puzzle2(allocator, data);

    const time_end = std.time.nanoTimestamp();
    std.debug.print("overall time: {D}\n", .{@as(i64, @intCast(time_end - time_start))});
    std.debug.print("\nfin\n", .{});
}
