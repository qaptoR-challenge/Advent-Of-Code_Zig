const std = @import("std");

const Allocator = std.mem.Allocator;

const TEST_FILE = "D:/Files/advent/2024/day00/test00.txt";
const DATA_FILE = "D:/Files/advent/2024/day00/data00.txt";

fn loadData(allocator: Allocator, filename: []const u8) !std.ArrayList([]const u8) {
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
    const content = try file.readToEndAlloc(allocator, std.math.maxInt(u64));
    defer allocator.free(content);

    var data = std.ArrayList([]const u8).init(allocator);

    var rows = std.mem.splitSequence(u8, content, "\r\n");
    while (rows.next()) |row| {
        if (row.len == 0) continue;
        var row_data = try std.ArrayList(i32).initCapacity(allocator, 2);
        var cols = std.mem.splitSequence(u8, row, "   ");

        while (cols.next()) |col| {
            try row_data.append(try std.fmt.parseInt(i32, col, 10));
        }
        try data.append(row_data);
    }

    return data;
}

fn test_data1(allocator: Allocator, data: std.ArrayList([]const u8)) !void {
    const time_start = std.time.milliTimestamp();

    var sum: u32 = 0;

    const time_end = std.time.milliTimestamp();
    std.debug.print("part 1: {d} time: {d}\n", .{ sum, time_end - time_start });
}

fn test_data2(allocator: Allocator, data: std.ArrayList([]const u8)) !void {
    const time_start = std.time.milliTimestamp();

    var sum: i32 = 0;

    const time_end = std.time.milliTimestamp();
    std.debug.print("part 2: {d} time: {d}\n", .{ sum, time_end - time_start });
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("\nHello, Day 00!\n\n", .{});

    // var data = try loadData(allocator, TEST_FILE);
    var data = try loadData(allocator, DATA_FILE);
    defer {
        for (data.items) |row| {
            row.deinit();
        }
        data.deinit();
    }

    try test_data1(allocator, data);
    try test_data2(allocator, data);

    std.debug.print("\nfin\n", .{});
}
