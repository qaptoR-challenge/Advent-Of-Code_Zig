const std = @import("std");
const AutoHashMap = std.AutoHashMap;
const Allocator = std.mem.Allocator;
const testing = std.testing;

/// An AutoHashSet is a generic Set type backed by an AutoHashMap.
pub fn AutoHashSet(comptime V: type) type {
    return struct {
        const Self = @This();

        hash_map: std.AutoHashMap(V, void),

        const AHSHashMap = AutoHashMap(V, void);
        pub const Iterator = AHSHashMap.KeyIterator;

        /// Create an AutoHashSet using an allocator. The allocator will be used
        /// internally for both backing allocations.
        pub fn init(allocator_: Allocator) Self {
            return .{ .hash_map = AHSHashMap.init(allocator_) };
        }

        pub fn initContext(allocator_: Allocator, ctx: std.hash_map.AutoContext(V)) Self {
            return .{ .hash_map = AHSHashMap.initContext(allocator_, ctx) };
        }

        // Free an AutoHashSet.
        pub fn deinit(self: *Self) void {
            self.hash_map.deinit();
            self.* = undefined;
        }

        /// Adds a value to the set.
        pub fn insert(self: *Self, value: V) !bool {
            const gop = try self.hash_map.getOrPut(value);
            return gop.found_existing;
        }

        /// Returns true if the set contains the given value.
        pub fn contains(self: Self, value: V) bool {
            return self.hash_map.contains(value);
        }

        /// Removes a value from the set if present.
        pub fn remove(self: *Self, value: V) bool {
            return self.hash_map.remove(value);
        }

        /// Returns the number of values in the set.
        pub fn count(self: Self) usize {
            return self.hash_map.count();
        }

        /// Returns an iterator over the values in the set.
        pub fn iterator(self: *const Self) Iterator {
            return self.hash_map.keyIterator();
        }

        /// Removes all entries from the set but keeps the capacity.
        pub fn clearRetainingCapacity(self: *Self) void {
            self.hash_map.clearRetainingCapacity();
        }

        /// Removes all entries from the set and releases the capacity.
        pub fn clearAndFree(self: *Self) void {
            self.hash_map.clearAndFree();
        }

        /// Get the allocator used by this set.
        pub fn allocator(self: *const Self) Allocator {
            return self.hash_map.allocator();
        }
    };
}

test "AutoHashSet basic operations" {
    var set = AutoHashSet(i32).init(std.testing.allocator);
    defer set.deinit();

    _ = try set.insert(42);
    _ = try set.insert(100);
    _ = try set.insert(42); // duplicate

    try testing.expectEqual(@as(usize, 2), set.count());
    try testing.expect(set.contains(42));
    try testing.expect(set.contains(100));
    try testing.expect(!set.contains(999));

    try testing.expect(set.remove(42));
    try testing.expect(!set.contains(42));
    try testing.expectEqual(@as(usize, 1), set.count());

    try testing.expect(!set.remove(999));
}

test "AutoHashSet iterator" {
    var set = AutoHashSet(u8).init(std.testing.allocator);
    defer set.deinit();

    _ = try set.insert(1);
    _ = try set.insert(2);
    _ = try set.insert(3);

    var sum: u8 = 0;
    var it = set.iterator();
    while (it.next()) |value| {
        sum += value.*;
    }

    try std.testing.expectEqual(@as(u8, 6), sum);
}

test "AutoHashSet clear" {
    var set = AutoHashSet(i32).init(std.testing.allocator);
    defer set.deinit();

    _ = try set.insert(1);
    _ = try set.insert(2);

    var capacity = set.hash_map.capacity();
    set.clearRetainingCapacity();
    try testing.expectEqual(@as(usize, 0), set.count());
    try testing.expect(!set.contains(1));
    try testing.expectEqual(capacity, set.hash_map.capacity());

    _ = try set.insert(3);
    try testing.expectEqual(@as(usize, 1), set.count());

    capacity = set.hash_map.capacity();
    set.clearAndFree();
    try testing.expectEqual(@as(usize, 0), set.count());
    try testing.expect(capacity != set.hash_map.capacity());
}
