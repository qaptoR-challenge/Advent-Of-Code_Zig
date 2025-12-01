const std = @import("std");
const AList = @import("orcz").ManagedArrayList;

const Allocator = std.mem.Allocator;

// const DATA_FILE = "/Users/rocco/Programming/advent_zig/2024/day01/data.txt";
const DATA_FILE = "/home/qaptor/Programming/zig/aoc_z/2024/day01/data.txt";

fn loadData(allocator: Allocator, filename: []const u8) !AList(AList(i32)) {
    const time_start = std.time.nanoTimestamp();
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
    const content = try file.readToEndAlloc(allocator, std.math.maxInt(u64));
    defer allocator.free(content);

    var data = AList(AList(i32)).init(allocator);

    // var rows = std.mem.tokenizeSequence(u8, content, "\r\n");
    var rows = std.mem.tokenizeSequence(u8, content, "\n");
    while (rows.next()) |row| {
        var row_data = AList(i32).init(allocator);
        var cols = std.mem.splitSequence(u8, row, "   ");

        while (cols.next()) |col| {
            try row_data.append(try std.fmt.parseInt(i32, col, 10));
        }
        try data.append(row_data);
    }

    const time_end = std.time.nanoTimestamp();
    std.debug.print("load data time: {D}\n", .{@as(i64, @intCast(time_end - time_start))});
    return data;
}

fn test_data1(allocator: Allocator, data: AList(AList(i32))) !void {
    const time_start = std.time.nanoTimestamp();

    var sum: u32 = 0;
    var lists = AList(AList(i32)).init(allocator);

    var list0 = AList(i32).init(allocator);
    var list1 = AList(i32).init(allocator);
    for (data.list.items) |row| {
        try list0.append(row.list.items[0]);
        try list1.append(row.list.items[1]);
    }
    try lists.append(list0);
    try lists.append(list1);

    var i: u32 = 0;
    const len: usize = lists.list.items[0].list.items.len;
    std.mem.sort(i32, lists.list.items[0].list.items, {}, comptime std.sort.desc(i32));
    std.mem.sort(i32, lists.list.items[1].list.items, {}, comptime std.sort.desc(i32));
    while (i < len) : (i += 1) {
        const a: i32 = lists.list.items[0].pop().?;
        const b: i32 = lists.list.items[1].pop().?;
        sum += @abs(a - b);
    }

    const time_end = std.time.nanoTimestamp();
    std.debug.print("part 1: {d} time: {D}\n", .{ sum, @as(i64, @intCast(time_end - time_start)) });
}

fn test_data2(allocator: Allocator, data: AList(AList(i32))) !void {
    const time_start = std.time.nanoTimestamp();

    var sum: i32 = 0;

    var lists = AList(AList(i32)).init(allocator);

    var list0 = AList(i32).init(allocator);
    var list1 = AList(i32).init(allocator);
    for (data.list.items) |row| {
        try list0.append(row.list.items[0]);
        try list1.append(row.list.items[1]);
    }
    try lists.append(list0);
    try lists.append(list1);

    var i: usize = 0;
    while (i < lists.list.items[0].list.items.len) : (i += 1) {
        const a: i32 = lists.list.items[0].list.items[i];
        var b: i32 = 0;
        for (lists.list.items[1].list.items) |val| {
            if (val == a) {
                b += 1;
            }
        }
        sum += a * b;
    }

    const time_end = std.time.nanoTimestamp();
    std.debug.print("part 2: {d} time: {D}\n", .{ sum, @as(i64, @intCast(time_end - time_start)) });
}

pub fn main() !void {
    const time_start = std.time.nanoTimestamp();
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("\nHello, Day 1!\n\n", .{});

    var data = try loadData(allocator, DATA_FILE);
    defer {
        for (data.list.items) |*row| {
            row.deinit();
        }
        data.deinit();
    }

    try test_data1(allocator, data);
    try test_data2(allocator, data);

    const time_end = std.time.nanoTimestamp();
    std.debug.print("overall time: {D}\n", .{@as(i64, @intCast(time_end - time_start))});
    std.debug.print("\nfin\n", .{});
}
