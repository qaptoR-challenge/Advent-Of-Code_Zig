const std = @import("std");

const Allocator = std.mem.Allocator;
const SHMap = std.StringHashMap;
const AList = @import("orcz").ManagedArrayList;

const input: []const u8 = @embedFile("data.txt");
const Data = struct {
    first: AList([]const u8),
};

fn loadData(alloc_: Allocator) !Data {
    const time_start = std.time.nanoTimestamp();
    const content = std.mem.trimRight(u8, input, "\n");

    var data: Data = .{
        .first = AList([]const u8).init(alloc_),
    };
    var rows = std.mem.splitSequence(u8, content, "\n");
    while (rows.next()) |row| {
        try data.first.append(row);
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
    _ = alloc_;
    _ = data_;

    var sum: u32 = 0;
    sum += 0;

    const time_end = std.time.nanoTimestamp();
    std.debug.print("part 1: {d} time: {D}\n", .{ sum, @as(i64, @intCast(time_end - time_start)) });
}

fn puzzle2(alloc_: Allocator, data_: Data) !void {
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
    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("\nHello, 20$$ Day @@!\n\n", .{});

    var data = try loadData(allocator);
    defer {
        // for (data.items) |row| {
        //     row.deinit();
        // }
        data.first.deinit();
    }

    try puzzle1(allocator, data);
    try puzzle2(allocator, data);

    const time_end = std.time.nanoTimestamp();
    std.debug.print("overall time: {D}\n", .{@as(i64, @intCast(time_end - time_start))});
    std.debug.print("\nfin\n", .{});
}
