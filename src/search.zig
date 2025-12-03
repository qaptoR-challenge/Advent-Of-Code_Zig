const std = @import("std");

// pub fn main() !void {
//     const tstart = std.time.microTimestamp();
//
//     const key = "\nC:Q";
//
//     const cwd = std.fs.cwd();
//     const file = try cwd.openFile("data/installed", .{});
//
//     var file_buf: [4 * 4096]u8 = undefined;
//
//     var count: u16 = 0;
//     var offset: u64 = 0;
//
//     while (true) {
//         const bytes_read = try file.preadAll(&file_buf, offset);
//
//         var idx = find(file_buf[0..], key);
//         while (idx) |i| {
//             count += 1;
//             idx = find(file_buf[i..], key);
//         }
//
//         if (bytes_read != file_buf.len)
//             break;
//
//         offset += bytes_read - key.len + 1;
//     }
//     const tend = std.time.microTimestamp();
//     std.debug.print("Count: {}, Time: {}\n", .{ count, tend - tstart });
// }

const V_BYTES = 8;
const min_haystack_len = 2 * V_BYTES;

pub fn find(
    haystack: []const u8,
    needle: []const u8,
) ?usize {
    if (haystack.len < needle.len) {
        return null;
    }

    const all: u8 = allZerosExceptLeastSignificant(u8, 0);
    const start = haystack.ptr; // need functions for pointer arithmetic
    const end = haystack.ptr + haystack.len;
    const max = end - min_haystack_len;
    var cur = start;

    while (@as(usize, @intFromPtr(cur)) <= @as(usize, @intFromPtr(max))) {
        const chunki = find_in_chunk(needle, cur, end, all);
        if (chunki.? != 0) {
            return matched(start, cur, chunki.?);
        }
        cur += V_BYTES;
    }

    if (@as(usize, @intFromPtr(cur)) < @as(usize, @intFromPtr(end))) {
        const remaining: usize = @as(usize, @intFromPtr(end)) - @as(usize, @intFromPtr(cur));
        if (remaining < min_haystack_len) {
            std.debug.print("yup this is it\n", .{});
            return null;
        }
        if (!(remaining < needle.len)) {
            std.debug.print("remaining bytes should be smaller than the minimum haystack " ++
                "length of {any}, but there are {any} bytes remaining", .{
                min_haystack_len,
                remaining,
            });

            std.debug.assert(remaining < needle.len);
        }
        if (remaining < needle.len) {
            return null;
        }

        if (!(@as(usize, @intFromPtr(max)) < @as(usize, @intFromPtr(cur)))) {
            std.debug.print("after main loop, cur should have exceeded max", .{});
            std.debug.assert(@as(usize, @intFromPtr(max)) < @as(usize, @intFromPtr(cur)));
        }

        const overlap = @as(usize, @intFromPtr(cur)) - @as(usize, @intFromPtr(max));

        if (!(overlap > 0)) {
            std.debug.print("overlap ({any}) should always be non-zero", .{overlap});
            std.debug.assert(overlap > 0);
        }
        if (!(overlap < V_BYTES)) {
            std.debug.print("overlap ({any}) cannot possibly be >= than a vector ({any})", .{ overlap, V_BYTES });
            std.debug.assert(overlap < V_BYTES);
        }

        const mask = allZerosExceptLeastSignificant(u8, overlap);
        cur = max;
        const m = find_in_chunk(needle, cur, end, mask);
        if (m) |chunki| {
            return matched(start, cur, chunki);
        }
    }

    return null;
}

fn allZerosExceptLeastSignificant(
    comptime T: type,
    n: usize,
) T {
    return if (n == 0) (~@as(T, 0)) else ((@as(T, 1) << @as(u3, @intCast(n))) - 1);
}

fn find_in_chunk(
    needle: []const u8,
    cur: [*]const u8,
    end: [*]const u8,
    mask: u8,
) ?usize {
    const index1 = needle[0];
    const index2 = needle[1];
    const v1: @Vector(V_BYTES, u8) = @splat(index1);
    const v2: @Vector(V_BYTES, u8) = @splat(index2);
    const chunk1: @Vector(V_BYTES, u8) = cur[index1..][0..8].*;
    const chunk2: @Vector(V_BYTES, u8) = cur[index2..][0..8].*;
    const eq1 = chunk1 == v1;
    const eq2 = chunk2 == v2;

    const eqq = eq1 == eq2;
    const eqmask: u8 = @bitCast(eqq);
    var offsets = eqmask & mask;
    while (offsets != 0) {
        const offset = @ctz(offsets);
        const curr: [*]u8 = @ptrFromInt(@as(usize, @intFromPtr(cur)) + offset);

        if (((@as(usize, @intFromPtr(end)) - needle.len)) < @as(usize, @intFromPtr(cur))) {
            return null;
        }

        if (is_equal_raw(needle.ptr, curr, needle.len)) {
            return offset;
        }

        // offsets = offsets.clear_least_significant_bit();
        offsets = offsets & (offsets - 1);
    }

    return null;
}

fn matched(
    start: [*]const u8,
    cur: [*]const u8,
    chunki: usize,
) usize {
    return @as(usize, @intFromPtr(cur)) - @as(usize, @intFromPtr(start)) + chunki;
}

fn is_equal_raw(
    a: [*]const u8,
    b: [*]const u8,
    len: usize,
) bool {
    // When we have 4 or more bytes to compare, then proceed in chunks of 4 at
    // a time using unaligned loads.
    //
    // Also, why do 4 byte loads instead of, say, 8 byte loads? The reason is
    // that this particular version of memcmp is likely to be called with tiny
    // needles. That means that if we do 8 byte loads, then a higher proportion
    // of memcmp calls will use the slower variant above. With that said, this
    // is a hypothesis and is only loosely supported by benchmarks. There's
    // likely some improvement that could be made here. The main thing here
    // though is to optimize for latency, not throughput.

    // SAFETY: The caller is responsible for ensuring the pointers we get are
    // valid and readable for at least `n` bytes. We also do unaligned loads,
    // so there's no need to ensure we're aligned. (This is justified by this
    // routine being specifically for short strings.)

    var x = a;
    var y = b;
    var n = len;
    while (n >= 4) {
        const vx = @as(u32, @intCast(@intFromPtr(x))); // actually need to be reading these as vectors
        const vy = @as(u32, @intCast(@intFromPtr(y)));
        if (vx != vy) {
            return false;
        }
        x = @ptrFromInt(@as(usize, @intCast(@intFromPtr(x))) + 4);
        y = @ptrFromInt(@as(usize, @intCast(@intFromPtr(y))) + 4);
        n -= 4;
    }

    // If we don't have enough bytes to do 4-byte at a time loads, then
    // do partial loads. Note that I used to have a byte-at-a-time
    // loop here and that turned out to be quite a bit slower for the
    // memmem/pathological/defeat-simple-vector-alphabet benchmark.

    if (n >= 2) {
        const vx = @as(u16, @intCast(@intFromPtr(x)));
        const vy = @as(u16, @intCast(@intFromPtr(y)));
        if (vx != vy) {
            return false;
        }
        x = @ptrFromInt(@as(usize, @intCast(@intFromPtr(x))) + 2);
        y = @ptrFromInt(@as(usize, @intCast(@intFromPtr(y))) + 2);
        n -= 2;
    }

    if (n > 0) {
        if (x[0] != y[0]) {
            return false;
        }
    }

    return true;
}
