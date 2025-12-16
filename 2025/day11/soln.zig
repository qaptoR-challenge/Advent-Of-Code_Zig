const std = @import("std");

const Allocator = std.mem.Allocator;
const SHMap = std.StringHashMap;
const AList = @import("orcz").ManagedArrayList;
const BS = std.BufSet;

const input: []const u8 = @embedFile("data.txt");
const Data = struct {
    graph: SHMap(AList([]const u8)),
};

fn loadData(alloc_: Allocator) !Data {
    const time_start = std.time.nanoTimestamp();
    const content = std.mem.trimRight(u8, input, "\n");

    var data: Data = .{
        .graph = .init(alloc_),
    };
    var rows = std.mem.splitSequence(u8, content, "\n");
    while (rows.next()) |row| {
        const split: usize = std.mem.indexOf(u8, row, ": ").?;
        var values = std.mem.tokenizeScalar(u8, row[split + 2 ..], ' ');
        var vals: AList([]const u8) = .init(alloc_);
        while (values.next()) |value| {
            try vals.append(value);
        }
        try data.graph.put(row[0..split], vals);
    }

    // try printData(data);

    const time_end = std.time.nanoTimestamp();
    std.debug.print("load data time: {D}\n", .{@as(i64, @intCast(time_end - time_start))});
    return data;
}

fn printData(data_: Data) !void {
    var it = data_.graph.iterator();
    while (it.next()) |entry| {
        std.debug.print("{s}: ", .{entry.key_ptr.*});
        for (entry.value_ptr.*.items()) |val| {
            std.debug.print("{s} ", .{val});
        }
        std.debug.print("\n", .{});
    }
}

const Node1 = struct {
    name: []const u8,
    pop: bool,
};

fn puzzle1(alloc_: Allocator, data_: Data) !void {
    const time_start = std.time.nanoTimestamp();

    var sum: u64 = 0;

    const start: []const u8 = "you";
    const goal: []const u8 = "out";

    var stack: AList(Node1) = .init(alloc_);
    try stack.append(.{ .name = start, .pop = false });

    while (stack.pop()) |node| {
        if (node.pop) {
            continue;
        }

        if (std.mem.eql(u8, node.name, goal)) {
            sum += 1;
            continue;
        }

        try stack.append(.{ .name = node.name, .pop = true });
        const vals = data_.graph.get(node.name).?;
        for (vals.items()) |val| {
            try stack.append(.{ .name = val, .pop = false });
        }
    }

    const time_end = std.time.nanoTimestamp();
    std.debug.print("part 1: {d} time: {D}\n", .{ sum, @as(i64, @intCast(time_end - time_start)) });
}

const Node2 = struct {
    name: []const u8,
    pop: bool,
    state: State,
};

const Memo = struct {
    name: u64,
    state: State,
};

const State = struct {
    fft: bool,
    dac: bool,
};

fn puzzle2(alloc_: Allocator, data_: Data) !void {
    const time_start = std.time.nanoTimestamp();

    const start: []const u8 = "svr";
    const goal: []const u8 = "out";

    var stack: AList(Node2) = .init(alloc_);
    var memo: std.AutoHashMap(Memo, u64) = .init(alloc_);
    var sum_stack: AList(u64) = .init(alloc_);

    try stack.append(.{ .name = start, .state = .{ .fft = false, .dac = false }, .pop = false });
    try sum_stack.append(0);

    while (stack.pop()) |node| {
        var current_state = node.state;
        current_state.fft = current_state.fft or std.mem.eql(u8, node.name, "fft");
        current_state.dac = current_state.dac or std.mem.eql(u8, node.name, "dac");

        var hasher = std.hash.Wyhash.init(0);
        std.hash.autoHashStrat(&hasher, node.name, .Deep);
        const key: Memo = .{ .name = hasher.final(), .state = current_state };

        if (node.pop) {
            const subtree_sum = sum_stack.pop().?;
            try memo.put(key, subtree_sum);
            sum_stack.items()[sum_stack.len() - 1] += subtree_sum;
            continue;
        }

        if (std.mem.eql(u8, node.name, goal)) {
            if (current_state.fft and current_state.dac) {
                sum_stack.items()[sum_stack.len() - 1] += 1;
            }
            continue;
        }

        if (memo.get(key)) |cached| {
            sum_stack.items()[sum_stack.len() - 1] += cached;
            continue;
        }

        try stack.append(.{ .name = node.name, .state = node.state, .pop = true });
        try sum_stack.append(0);

        const vals = data_.graph.get(node.name).?;
        for (vals.items()) |val| {
            try stack.append(.{ .name = val, .state = current_state, .pop = false });
        }
    }

    const sum = sum_stack.pop().?;
    const time_end = std.time.nanoTimestamp();
    std.debug.print("part 2: {d} time: {D}\n", .{ sum, @as(i64, @intCast(time_end - time_start)) });
}

pub fn main() !void {
    const time_start = std.time.nanoTimestamp();
    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("\nHello, 2025 Day 11!\n\n", .{});

    const data = try loadData(allocator);

    try puzzle1(allocator, data);
    try puzzle2(allocator, data);

    const time_end = std.time.nanoTimestamp();
    std.debug.print("overall time: {D}\n", .{@as(i64, @intCast(time_end - time_start))});
    std.debug.print("\nfin\n", .{});
}
