const std = @import("std");

const Allocator = std.mem.Allocator;

const DATA_FILE = ( // zig fmt: off
    // "D:/Files/advent/2024/day02/test02.txt"
    // "D:/Files/advent/2024/day02/data02.txt"
    "/Users/rocco/Programming/advent_zig/2024/day02/data.txt"
); // zig fmt: on

fn loadData(allocator: Allocator, filename: []const u8) !std.ArrayList(std.ArrayList(i32)) {
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
    const content = try file.readToEndAlloc(allocator, std.math.maxInt(u64));
    defer allocator.free(content);

    var data = std.ArrayList(std.ArrayList(i32)).init(allocator);

    var rows = std.mem.splitSequence(u8, content, "\n");
    while (rows.next()) |row| {
        if (row.len == 0) continue;

        var row_data = try std.ArrayList(i32).initCapacity(allocator, 2);
        var cols = std.mem.splitSequence(u8, row, " ");

        while (cols.next()) |col| {
            try row_data.append(try std.fmt.parseInt(i32, col, 10));
        }
        try data.append(row_data);
    }

    return data;
}

fn test_data1(data: std.ArrayList(std.ArrayList(i32))) !void {
    const time_start = std.time.milliTimestamp();

    var sum: u32 = 0;
    for (data.items) |row| {
        if (rec_compare(row, 0, 0)) {
            sum += 1;
        }
    }

    const time_end = std.time.milliTimestamp();
    std.debug.print("part 1: {d} time: {d}\n", .{ sum, time_end - time_start });
}

fn test_data2(data: std.ArrayList(std.ArrayList(i32))) !void {
    const time_start = std.time.milliTimestamp();

    var sum: i32 = 0;
    for (data.items) |row| {
        if (rec_compare(row, 0, 0)) {
            sum += 1;
        } else {
            var i: usize = 0;
            while (i < row.items.len) : (i += 1) {
                var clone = try row.clone();
                _ = clone.orderedRemove(i);
                if (rec_compare(clone, 0, 0)) {
                    sum += 1;
                    break;
                }
            }
        }
    }

    const time_end = std.time.milliTimestamp();
    std.debug.print("part 2: {d} time: {d}\n", .{ sum, time_end - time_start });
}

fn rec_compare(row_: std.ArrayList(i32), index_: usize, inc_: i32) bool {
    if (row_.items.len == index_ + 1) {
        return true;
    }

    const front = row_.items[index_];
    const next = row_.items[index_ + 1];

    const diff: i32 = front - next;
    const s: i32 = if (diff < 0) -1 else if (diff > 0) 1 else 0;
    const a: u32 = @abs(diff);

    if (s == 0) {
        return false;
    }
    if (s != inc_ and inc_ != 0) {
        return false;
    }
    if (a < 1 or 3 < a) {
        return false;
    }

    return rec_compare(row_, index_ + 1, s);
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("\nHello, Day 02!\n\n", .{});

    var data = try loadData(allocator, DATA_FILE);
    defer {
        for (data.items) |row| {
            row.deinit();
        }
        data.deinit();
    }

    try test_data1(data);
    try test_data2(data);

    std.debug.print("\nfin\n", .{});
}
