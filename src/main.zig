const std = @import("std");
const c = @import("c.zig");

const SCR_WIDTH: u32 = 800;
const SCR_HEIGHT: u32 = 600;

fn framebufferSizeCallback(_: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    c.glViewport(0, 0, width, height);
    return;
}

fn processInput(window: ?*c.GLFWwindow) callconv(.C) void {
    if (c.glfwGetKey(window, c.GLFW_KEY_Q) == c.GLFW_PRESS)
        c.glfwSetWindowShouldClose(window, c.GL_TRUE);
}

const vertex_shader_source =
    \\#version 330 core
    \\layout (location = 0) in vec3 aPos;
    \\
    \\void main()
    \\{
    \\    gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
    \\}
;

const fragment_shader_source =
    \\#version 330 core
    \\out vec4 FragColor;
    \\
    \\void main()
    \\{
    \\    FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
    \\}
;

pub fn main() u8 {
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

    var success: c.GLint = c.GL_FALSE;
    var info_log: [512]u8 = undefined;

    const vertexShader: u32 = c.glCreateShader(c.GL_VERTEX_SHADER);
    c.glShaderSource(vertexShader, 1, @ptrCast(&vertex_shader_source), null);
    c.glCompileShader(vertexShader);

    success = c.GL_FALSE;
    c.glGetShaderiv(vertexShader, c.GL_COMPILE_STATUS, &success);
    if (success == c.GL_FALSE) {
        c.glGetShaderInfoLog(vertexShader, 512, null, &info_log);
        std.log.err("ERROR::SHADER::VERTEX::COMPILATION_FAILED\n{s}", .{info_log});
        return 1;
    }

    const fragmentShader: u32 = c.glCreateShader(c.GL_FRAGMENT_SHADER);
    c.glShaderSource(fragmentShader, 1, @ptrCast(&fragment_shader_source), null);
    c.glCompileShader(fragmentShader);

    success = c.GL_FALSE;
    c.glGetShaderiv(fragmentShader, c.GL_COMPILE_STATUS, &success);
    if (success == c.GL_FALSE) {
        c.glGetShaderInfoLog(fragmentShader, 512, null, &info_log);
        std.log.err("ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n{s}", .{info_log});
        return 1;
    }

    const shaderProgram: u32 = c.glCreateProgram();
    c.glAttachShader(shaderProgram, vertexShader);
    c.glAttachShader(shaderProgram, fragmentShader);
    c.glLinkProgram(shaderProgram);
    defer c.glDeleteProgram(shaderProgram);

    success = c.GL_FALSE;
    c.glGetProgramiv(shaderProgram, c.GL_LINK_STATUS, &success);
    if (success == c.GL_FALSE) {
        c.glGetProgramInfoLog(shaderProgram, 512, null, &info_log);
        std.log.err("ERROR::SHADER::PROGRAM::LINKING_FAILED\n{s}", .{info_log});
        return 1;
    }

    c.glDeleteShader(vertexShader);
    c.glDeleteShader(fragmentShader);

    const vertices = [12]f32{
        0.5, 0.5, 0.0, // top right
        0.5, -0.5, 0.0, // bottom right
        -0.5, -0.5, 0.0, // bottom left
        -0.5, 0.5, 0.0, // top left
    };
    const indices = [6]u32{
        0, 1, 3,
        1, 2, 3,
    };

    var VAO: u32 = undefined;
    c.glGenVertexArrays(1, &VAO);
    defer c.glDeleteVertexArrays(1, &VAO);

    var VBO: u32 = undefined;
    c.glGenBuffers(1, &VBO);
    defer c.glDeleteBuffers(1, &VBO);

    var EBO: u32 = undefined;
    c.glGenBuffers(1, &EBO);
    defer c.glDeleteBuffers(1, &EBO);

    c.glBindVertexArray(VAO);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, VBO);
    c.glBufferData(c.GL_ARRAY_BUFFER, vertices.len * @sizeOf(f32), &vertices, c.GL_STATIC_DRAW);

    c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, EBO);
    c.glBufferData(c.GL_ELEMENT_ARRAY_BUFFER, indices.len * @sizeOf(u32), &indices, c.GL_STATIC_DRAW);

    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 3 * @sizeOf(f32), null);
    c.glEnableVertexAttribArray(0);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);
    c.glBindVertexArray(0);

    // Uncomment to draw in wireframe polygons
    c.glPolygonMode(c.GL_FRONT_AND_BACK, c.GL_LINE);

    while (c.glfwWindowShouldClose(window) != c.GL_TRUE) {
        processInput(window);

        c.glClearColor(0.2, 0.3, 0.3, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        c.glUseProgram(shaderProgram);
        c.glBindVertexArray(VAO);
        // c.glDrawArrays(c.GL_TRIANGLES, 0, 3);
        c.glDrawElements(c.GL_TRIANGLES, 6, c.GL_UNSIGNED_INT, null);

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }

    return 0;
}
