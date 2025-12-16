const std = @import("std");
const re = @import("qpEngine").re;

const Allocator = std.mem.Allocator;
const SHMap = std.StringHashMap;
const AList = @import("orcz").ManagedArrayList;
const DLL = std.DoublyLinkedList;

const Regex = re.Regex;
const RegexMatch = re.RegexMatch;
const Matches = std.array_list.Managed(RegexMatch);

const input: []const u8 = @embedFile("data.txt");
const Data = struct {
    lights: AList([]bool),
    buttons: AList([][]usize),
    jolts: AList([]u16),
};
var num_rows: usize = 0;

fn loadData(alloc_: Allocator) !Data {
    const time_start = std.time.nanoTimestamp();
    const content = std.mem.trimRight(u8, input, "\n");

    var data: Data = .{
        .lights = .init(alloc_),
        .buttons = .init(alloc_),
        .jolts = .init(alloc_),
    };

    var data_re: Regex = try .from(
        \\\[(.*)\] (\(.*\)) \{(.*)\}
    , false, alloc_);

    var button_re: Regex = try .from(
        \\(\(.*?\))
    , false, alloc_);

    var digit_re: Regex = try .from(
        \\(\d+)
    , false, alloc_);

    var rows = std.mem.splitSequence(u8, content, "\n");
    while (rows.next()) |row| {
        num_rows += 1;
        const data_match: RegexMatch = data_re.search(row, null, null).?;
        const light = data_match.getString(1);
        const button = data_match.getString(2);
        const jolt = data_match.getString(3);

        // parse lights
        var light_bools: []bool = try alloc_.alloc(bool, light.len);
        for (light, 0..) |l, i| {
            light_bools[i] = switch (l) {
                '.' => false,
                '#' => true,
                else => unreachable,
            };
        }
        try data.lights.append(light_bools);

        // parse buttons
        const button_matches: Matches = button_re.searchAll(button, null, null);
        var button_groups: [][]usize = try alloc_.alloc([]usize, button_matches.items.len);
        for (button_matches.items, 0..) |bm, i| {
            const digit_matches: Matches = digit_re.searchAll(bm.getString(0), null, null);
            button_groups[i] = try alloc_.alloc(usize, digit_matches.items.len);
            for (digit_matches.items, 0..) |dm, j| {
                button_groups[i][j] = try std.fmt.parseInt(usize, dm.getString(1), 10);
            }
        }
        try data.buttons.append(button_groups);

        // parse jolts
        const jolt_matches: Matches = digit_re.searchAll(jolt, null, null);
        var jolt_values: []u16 = try alloc_.alloc(u16, jolt_matches.items.len);
        for (jolt_matches.items, 0..) |jm, i| {
            jolt_values[i] = try std.fmt.parseInt(u16, jm.getString(1), 10);
        }
        try data.jolts.append(jolt_values);
    }

    // try printData(data);

    const time_end = std.time.nanoTimestamp();
    std.debug.print("load data time: {D}\n", .{@as(i64, @intCast(time_end - time_start))});
    return data;
}

fn printData(data_: Data) !void {
    _ = data_;
}

const BState = struct {
    parent: ?*BState,
    lights: []bool,
    node: DLL.Node,
};

fn puzzle1(alloc_: Allocator, data_: Data) !void {
    const time_start = std.time.nanoTimestamp();

    var sum: u32 = 0;

    for (0..num_rows) |row| {
        var queue = DLL{};
        const start_state = try alloc_.create(BState);
        const len = data_.lights.items()[row].len;
        start_state.* = BState{
            .parent = null,
            .lights = try alloc_.alloc(bool, len),
            .node = .{},
        };
        @memset(start_state.lights, false);
        queue.append(&start_state.node);

        while (queue.popFirst()) |current| {
            const current_state: *BState = @fieldParentPtr("node", current);
            // check if complete
            const is_complete = std.mem.eql(bool, current_state.lights, data_.lights.items()[row]);
            if (is_complete) {
                // count steps
                var steps: u32 = 0;
                var iter_state: ?*BState = current_state;
                while (iter_state) |s| {
                    steps += 1;
                    iter_state = s.parent;
                }
                sum += steps - 1; // don't count initial state
                break;
            }

            // append new states
            for (data_.buttons.items()[row]) |button| {
                const new_state = try alloc_.create(BState);
                new_state.* = BState{
                    .parent = current_state,
                    .lights = try alloc_.alloc(bool, len),
                    .node = .{},
                };
                @memcpy(new_state.lights, current_state.lights);
                for (button) |b| {
                    new_state.lights[b] = !new_state.lights[b];
                }
                queue.append(&new_state.node);
            }
        }
    }

    const time_end = std.time.nanoTimestamp();
    std.debug.print("part 1: {d} time: {D}\n", .{ sum, @as(i64, @intCast(time_end - time_start)) });
}

const UState = struct {
    parent: ?*UState,
    jolts: []u16,
    node: DLL.Node,
};

fn puzzle2(alloc_: Allocator, data_: Data) !void {
    const time_start = std.time.nanoTimestamp();

    var sum: u32 = 0;
    for (0..num_rows) |row| {
        var queue = DLL{};
        const start_state = try alloc_.create(UState);
        const len = data_.jolts.items()[row].len;
        start_state.* = UState{
            .parent = null,
            .jolts = try alloc_.alloc(u16, len),
            .node = .{},
        };
        @memset(start_state.jolts, 0);
        queue.append(&start_state.node);

        while (queue.popFirst()) |current| {
            const current_state: *UState = @fieldParentPtr("node", current);

            // check if complete
            const is_complete = std.mem.eql(u16, current_state.jolts, data_.jolts.items()[row]);
            if (is_complete) {
                var steps: u32 = 0;
                var iter_state: ?*UState = current_state;
                while (iter_state) |s| {
                    steps += 1;
                    iter_state = s.parent;
                }
                sum += steps - 1; // don't count initial state
                std.debug.print("one more down: {d}\n", .{row});
                break;
            }

            // append new states
            for (data_.buttons.items()[row]) |button| {
                const new_state = try alloc_.create(UState);
                new_state.* = UState{
                    .parent = current_state,
                    .jolts = try alloc_.alloc(u16, len),
                    .node = .{},
                };
                @memcpy(new_state.jolts, current_state.jolts);
                for (button) |b| {
                    new_state.jolts[b] += 1;
                }
                queue.append(&new_state.node);
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

    std.debug.print("\nHello, 2025 Day 10!\n\n", .{});

    const data = try loadData(allocator);

    try puzzle1(allocator, data);
    // try puzzle2(allocator, data); // does not complete in reasonable time

    const time_end = std.time.nanoTimestamp();
    std.debug.print("overall time: {D}\n", .{@as(i64, @intCast(time_end - time_start))});
    std.debug.print("\nfin\n", .{});
}
