const std = @import("std");
const qp = @import("qpEngine");

const Allocator = std.mem.Allocator;
const SHMap = std.StringHashMap;
const AList = std.array_list.Managed;
const MAList = @import("orcz").ManagedArrayList;

const Regex = qp.re.Regex;
const RegexMatch = qp.re.RegexMatch;

const DATA_FILE = ( // zig fmt: off
    "/home/qaptor/Programming/zig/aoc_z/2024/day03/data.txt"
    // "/Users/rocco/Programming/advent_zig/2024/day03/data.txt"
); // zig fmt: on

fn loadData(allocator: Allocator, filename: []const u8) !MAList([]const u8) {
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
    const content = try file.readToEndAlloc(allocator, std.math.maxInt(u64));

    var data = MAList([]const u8).init(allocator);

    // var rows = std.mem.splitSequence(u8, content, "\r\n");
    var rows = std.mem.splitSequence(u8, content, "\n");
    while (rows.next()) |row| {
        if (row.len == 0) continue;
        try data.append(row);
    }

    return data;
}

fn test_data1(alloc_: Allocator, data_: MAList([]const u8)) !void {
    const time_start = std.time.milliTimestamp();

    var mulreg: Regex = try Regex.from(
        \\mul\(\d{1,3},\d{1,3}\)
    , false, alloc_);

    var numreg: Regex = try Regex.from(
        \\\d{1,3}
    , false, alloc_);

    var sum: u32 = 0;
    for (data_.list.items) |row_| {
        const matches: AList(RegexMatch) = mulreg.searchAll(row_, null, null);
        for (matches.items) |match| {
            const nums = numreg.searchAll(match.getStringAt(0), null, null);
            const num1 = try std.fmt.parseInt(u32, nums.items[0].getStringAt(0), 10);
            const num2 = try std.fmt.parseInt(u32, nums.items[1].getStringAt(0), 10);
            sum += num1 * num2;
        }
    }

    const time_end = std.time.milliTimestamp();
    std.debug.print("part 1: {d} time: {d}\n", .{ sum, time_end - time_start });
}

fn test_data2(alloc_: Allocator, data_: MAList([]const u8)) !void {
    const time_start = std.time.milliTimestamp();

    var mulreg = try Regex.from(
        \\mul\(\d{1,3},\d{1,3}\)|do\(\)|don't\(\)
    , false, alloc_);

    var numreg = try Regex.from(
        \\\d{1,3}
    , false, alloc_);

    var sum: u32 = 0;
    var flag: bool = false;
    for (data_.list.items) |row_| {
        const matches = mulreg.searchAll(row_, null, null);
        for (matches.items) |match| {
            if (std.mem.eql(u8, match.getStringAt(0), "do()")) {
                flag = false;
                continue;
            } else if (std.mem.eql(u8, match.getStringAt(0), "don't()")) {
                flag = true;
                continue;
            }
            if (flag) continue;

            var nums = numreg.searchAll(match.getStringAt(0), null, null);
            const num1 = try std.fmt.parseInt(u32, nums.items[0].getStringAt(0), 10);
            const num2 = try std.fmt.parseInt(u32, nums.items[1].getStringAt(0), 10);
            sum += num1 * num2;
        }
    }

    const time_end = std.time.milliTimestamp();
    std.debug.print("part 2: {d} time: {d}\n", .{ sum, time_end - time_start });
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("\nHello, Day 03!\n\n", .{});

    const data = try loadData(allocator, DATA_FILE);

    try test_data1(allocator, data);
    try test_data2(allocator, data);

    std.debug.print("\nfin\n", .{});
}
