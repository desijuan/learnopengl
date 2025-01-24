const std = @import("std");

const FileBufferedReader = std.io.BufferedReader(4096, std.fs.File.Reader);

pub fn readFileZ(allocator: std.mem.Allocator, path: []const u8) ![:0]const u8 {
    const file: std.fs.File = std.fs.cwd().openFile(path, .{ .mode = .read_only }) catch |err| {
        std.debug.print("Error opening file: {s}\n", .{path});
        return err;
    };
    defer file.close();

    var file_br: FileBufferedReader = std.io.bufferedReader(file.reader());
    const reader: FileBufferedReader.Reader = file_br.reader();

    const size: u64 = try file.getEndPos();
    const buffer: []u8 = try allocator.alloc(u8, size + 1);
    errdefer allocator.free(buffer);

    const nread: usize = try reader.readAll(buffer);
    if (nread != size) return error.ReadError;

    buffer[size] = 0;

    return @as([:0]const u8, buffer[0..size :0]);
}
