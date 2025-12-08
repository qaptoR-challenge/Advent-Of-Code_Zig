pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var regex = try Regex.from("a(b|c)d", true, allocator);
    defer regex.deinit();

    std.debug.print("Pattern: {s}\n", .{regex.getPattern().?});

    const subject = "abd acd";
    var matches: AList(RegexMatch) = regex.searchAll(subject, 0, -1);
    defer regex.deinitMatchList(&matches);

    try tests.expectEqual(2, matches.items.len);

    try tests.expect(std.mem.eql(u8, "abd", matches.items[0].getStringAt(0)));
    try tests.expectEqual(0, matches.items[0].getStartAt(0));
    try tests.expectEqual(3, matches.items[0].getEndAt(0));

    try tests.expect(std.mem.eql(u8, "b", matches.items[0].getStringAt(1)));
    try tests.expectEqual(1, matches.items[0].getStartAt(1));
    try tests.expectEqual(2, matches.items[0].getEndAt(1));

    try tests.expect(std.mem.eql(u8, "acd", matches.items[1].getStringAt(0)));
    try tests.expectEqual(4, matches.items[1].getStartAt(0));
    try tests.expectEqual(7, matches.items[1].getEndAt(0));

    try tests.expect(std.mem.eql(u8, "c", matches.items[1].getStringAt(1)));
    try tests.expectEqual(5, matches.items[1].getStartAt(1));
    try tests.expectEqual(6, matches.items[1].getEndAt(1));

    std.debug.print("Hello, qpEngine!\n", .{});
}

const std = @import("std");
const qp = @import("qpEngine");

const AList = std.ArrayList;
const Regex = qp.util.Regex;
const RegexMatch = qp.util.RegexMatch;

const tests = std.testing;
