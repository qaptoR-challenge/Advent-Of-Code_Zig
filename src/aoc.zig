pub const search = @import("search.zig");
pub const functional = @import("functional.zig");
pub const AutoHashSet = @import("auto_hash_set.zig").AutoHashSet;

test "AOC Tests" {
    _ = AutoHashSet(u32);
}
