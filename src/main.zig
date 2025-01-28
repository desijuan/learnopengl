const std = @import("std");
const c = @import("c.zig");
const ShaderProgram = @import("shader_program.zig");

const SCR_WIDTH: i32 = 1024;
const SCR_HEIGHT: i32 = 1024;

var scr_width: i32 = SCR_WIDTH;
var scr_height: i32 = SCR_HEIGHT;

fn framebufferSizeCallback(_: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    scr_width = width;
    scr_height = height;

    c.glViewport(0, 0, width, height);
}

inline fn processInput(window: ?*c.GLFWwindow) void {
    if (c.glfwGetKey(window, c.GLFW_KEY_Q) == c.GLFW_PRESS)
        c.glfwSetWindowShouldClose(window, c.GL_TRUE);
}

pub fn main() !u8 {
    if (c.glfwInit() != c.GL_TRUE) {
        std.log.err("Failed to initialize GLFW", .{});
        return 1;
    }
    defer c.glfwTerminate();

    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);

    const window: *c.GLFWwindow = c.glfwCreateWindow(SCR_WIDTH, SCR_HEIGHT, "LearnOpenGl", null, null) orelse {
        std.log.err("Failed to create GLFW window", .{});
        return 1;
    };
    c.glfwMakeContextCurrent(window);
    _ = c.glfwSetFramebufferSizeCallback(window, framebufferSizeCallback);

    if (c.gladLoadGLLoader(@ptrCast(&c.glfwGetProcAddress)) != c.GL_TRUE) {
        std.log.err("Failed to initialize GLAD", .{});
        return 1;
    }

    std.log.info("OpenGL {s}", .{c.glGetString(c.GL_VERSION)});

    const program: ShaderProgram = try ShaderProgram.compile(.{
        .vertex_path = "res/shaders/vertex_shader.glsl",
        .fragment_path = "res/shaders/fragment_shader.glsl",
    });
    defer program.delete();

    // zig fmt: off

    const vertices = [_]f32{
        -1, -1, // bottom-left
         1, -1, // bottom-right
         1,  1, // top-right
        -1,  1, // top-left
    };

    const indices = [_]u8{
        0, 1, 2,
        2, 3, 0,
    };

    // zig fmt: on

    var VAO: c.GLuint = undefined;
    c.glGenVertexArrays(1, &VAO);
    defer c.glDeleteVertexArrays(1, &VAO);

    var VBO: c.GLuint = undefined;
    c.glGenBuffers(1, &VBO);
    defer c.glDeleteBuffers(1, &VBO);

    var EBO: c.GLuint = undefined;
    c.glGenBuffers(1, &EBO);
    defer c.glDeleteBuffers(1, &EBO);

    c.glBindVertexArray(VAO);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, VBO);
    c.glBufferData(c.GL_ARRAY_BUFFER, vertices.len * @sizeOf(f32), &vertices, c.GL_STATIC_DRAW);

    c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, EBO);
    c.glBufferData(c.GL_ELEMENT_ARRAY_BUFFER, indices.len * @sizeOf(u8), &indices, c.GL_STATIC_DRAW);

    c.glVertexAttribPointer(0, 2, c.GL_FLOAT, c.GL_FALSE, 2 * @sizeOf(f32), @ptrFromInt(0));
    c.glEnableVertexAttribArray(0);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);
    c.glBindVertexArray(0);

    while (c.glfwWindowShouldClose(window) != c.GL_TRUE) {
        processInput(window);

        c.glClearColor(0.2, 0.3, 0.3, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        const t: f32 = @floatCast(c.glfwGetTime());

        program.use();
        program.setFloat("time", t);
        program.setFloat("width", @floatFromInt(scr_width));
        program.setFloat("height", @floatFromInt(scr_height));
        c.glBindVertexArray(VAO);

        c.glDrawElements(c.GL_TRIANGLES, 6, c.GL_UNSIGNED_BYTE, @ptrFromInt(0));

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }

    return 0;
}
