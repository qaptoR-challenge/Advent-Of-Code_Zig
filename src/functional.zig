const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn map(comptime T: type, comptime R: type, allocator: Allocator, slice: []const T, func: fn (T) R) ![]R {
    const result = try allocator.alloc(R, slice.len);
    for (slice, 0..) |item, i| {
        result[i] = func(item);
    }
    return result;
}

pub fn filter(comptime T: type, allocator: Allocator, slice: []const T, predicate: fn (T) bool) ![]T {
    var list = std.ArrayList(T).init(allocator);
    for (slice) |item| {
        if (predicate(item)) {
            try list.append(item);
        }
    }
    return list.toOwnedSlice();
}

pub fn reduce(comptime T: type, comptime R: type, slice: []const T, initial: R, func: fn (R, T) R) R {
    var acc = initial;
    for (slice) |item| {
        acc = func(acc, item);
    }
    return acc;
}
