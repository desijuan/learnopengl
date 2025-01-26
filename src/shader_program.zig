const std = @import("std");
const utils = @import("utils.zig");
const c = @import("c.zig");

const INFO_LOG_SIZE = 512;

id: c.GLuint,

const Self = @This();

pub fn compile(src: struct { vertex_path: [:0]const u8, fragment_path: [:0]const u8 }) !Self {
    var success: c.GLint = undefined;
    var info_log: [INFO_LOG_SIZE]c.GLchar = undefined;

    var gpa = std.heap.GeneralPurposeAllocator(.{ .safety = true }){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const vertex_source: [:0]const u8 = try utils.readFileZ(allocator, src.vertex_path);
    defer allocator.free(vertex_source);

    const vertexShader: c.GLuint = c.glCreateShader(c.GL_VERTEX_SHADER);
    c.glShaderSource(vertexShader, 1, @ptrCast(&vertex_source), &[1]c.GLint{@intCast(vertex_source.len)});
    c.glCompileShader(vertexShader);
    defer c.glDeleteShader(vertexShader);

    success = c.GL_FALSE;
    c.glGetShaderiv(vertexShader, c.GL_COMPILE_STATUS, &success);
    if (success != c.GL_TRUE) {
        c.glGetShaderInfoLog(vertexShader, 512, null, &info_log);
        std.log.err("ERROR::SHADER::VERTEX::COMPILATION_FAILED\n{s}", .{info_log});
        return error.VertexShaderCompilationFailed;
    }

    const fragment_source: [:0]const u8 = try utils.readFileZ(allocator, src.fragment_path);
    defer allocator.free(fragment_source);

    const fragmentShader: c.GLuint = c.glCreateShader(c.GL_FRAGMENT_SHADER);
    c.glShaderSource(fragmentShader, 1, @ptrCast(&fragment_source), &[1]c.GLint{@intCast(fragment_source.len)});
    c.glCompileShader(fragmentShader);
    defer c.glDeleteShader(fragmentShader);

    success = c.GL_FALSE;
    c.glGetShaderiv(fragmentShader, c.GL_COMPILE_STATUS, &success);
    if (success != c.GL_TRUE) {
        c.glGetShaderInfoLog(fragmentShader, INFO_LOG_SIZE, null, &info_log);
        std.log.err("ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n{s}", .{info_log});
        return error.FragmentShaderCompilationFailed;
    }

    const programId: c.GLuint = c.glCreateProgram();
    c.glAttachShader(programId, vertexShader);
    c.glAttachShader(programId, fragmentShader);
    c.glLinkProgram(programId);

    success = c.GL_FALSE;
    c.glGetProgramiv(programId, c.GL_LINK_STATUS, &success);
    if (success != c.GL_TRUE) {
        c.glGetProgramInfoLog(programId, INFO_LOG_SIZE, null, &info_log);
        std.log.err("ERROR::SHADER::PROGRAM::LINKING_FAILED\n{s}", .{info_log});
        return error.ProgramLinkingFailed;
    }

    return Self{ .id = programId };
}

pub fn delete(self: Self) void {
    c.glDeleteProgram(self.id);
}

pub fn use(self: Self) void {
    c.glUseProgram(self.id);
}

pub fn setBool(self: Self, name: [:0]const u8, value: bool) void {
    c.glUniform1i(c.glGetUniformLocation(self.id, name), if (value) 1 else 0);
}

pub fn setInt(self: Self, name: [:0]const u8, value: i32) void {
    c.glUniform1i(c.glGetUniformLocation(self.id, name), value);
}

pub fn setFloat(self: Self, name: [:0]const u8, value: f32) void {
    c.glUniform1f(c.glGetUniformLocation(self.id, name), value);
}
