const std = @import("std");
const c = @import("c.zig");
const zm = @import("zmath");
const ShaderProgram = @import("shader_program.zig");

const SCR_WIDTH: u32 = 800;
const SCR_HEIGHT: u32 = 600;

fn framebufferSizeCallback(_: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    c.glViewport(0, 0, width, height);
}

fn processInput(window: ?*c.GLFWwindow) callconv(.C) void {
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
        0.5,   0.5, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0, // top right
        0.5,  -0.5, 0.0, 0.0, 1.0, 0.0, 1.0, 0.0, // bottom right
        -0.5, -0.5, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, // bottom left
        -0.5,  0.5, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0, // top left
    };
    // zig fmt: on

    const indices = [_]c_uint{
        0, 1, 3, // first Triangle
        1, 2, 3, // second Triangle
    };

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
    c.glBufferData(c.GL_ELEMENT_ARRAY_BUFFER, indices.len * @sizeOf(c_uint), &indices, c.GL_STATIC_DRAW);

    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 8 * @sizeOf(f32), @ptrFromInt(0));
    c.glVertexAttribPointer(1, 3, c.GL_FLOAT, c.GL_FALSE, 8 * @sizeOf(f32), @ptrFromInt(3 * @sizeOf(f32)));
    c.glVertexAttribPointer(2, 2, c.GL_FLOAT, c.GL_FALSE, 8 * @sizeOf(f32), @ptrFromInt(6 * @sizeOf(f32)));
    c.glEnableVertexAttribArray(0);
    c.glEnableVertexAttribArray(1);
    c.glEnableVertexAttribArray(2);

    c.stbi_set_flip_vertically_on_load(1);

    var texture1: c.GLuint = undefined;
    c.glGenTextures(1, &texture1);
    defer c.glDeleteTextures(1, &texture1);

    c.glBindTexture(c.GL_TEXTURE_2D, texture1);

    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_REPEAT);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_T, c.GL_REPEAT);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);

    const texture1_path = "res/img/container.jpg";
    var width1: c_int = undefined;
    var height1: c_int = undefined;
    var n_channels1: c_int = undefined;
    const texture1_data: [*c]c.stbi_uc = c.stbi_load(texture1_path, &width1, &height1, &n_channels1, 0);
    if (texture1_data == null) {
        std.log.err("Failed to load texture from: {s}", .{texture1_path});
        return 1;
    }

    c.glTexImage2D(c.GL_TEXTURE_2D, 0, c.GL_RGB, width1, height1, 0, c.GL_RGB, c.GL_UNSIGNED_BYTE, texture1_data);
    c.glGenerateMipmap(c.GL_TEXTURE_2D);

    c.stbi_image_free(texture1_data);

    var texture2: c.GLuint = undefined;
    c.glGenTextures(1, &texture2);
    defer c.glDeleteTextures(1, &texture2);

    c.glBindTexture(c.GL_TEXTURE_2D, texture2);

    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_REPEAT);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_T, c.GL_REPEAT);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_LINEAR);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);

    const texture2_path = "res/img/awesomeface.png";
    var width2: c_int = undefined;
    var height2: c_int = undefined;
    var n_channels2: c_int = undefined;
    const texture2_data: [*c]c.stbi_uc = c.stbi_load(texture2_path, &width2, &height2, &n_channels2, 0);
    if (texture2_data == null) {
        std.log.err("Failed to load texture from: {s}", .{texture2_path});
        return 1;
    }

    c.glTexImage2D(c.GL_TEXTURE_2D, 0, c.GL_RGBA, width2, height2, 0, c.GL_RGBA, c.GL_UNSIGNED_BYTE, texture2_data);
    c.glGenerateMipmap(c.GL_TEXTURE_2D);

    c.stbi_image_free(texture2_data);

    program.use();
    program.setInt("texture1", 0);
    program.setInt("texture2", 1);

    const translation: zm.Mat = zm.translation(0.25, -0.25, 0.0);

    while (c.glfwWindowShouldClose(window) != c.GL_TRUE) {
        processInput(window);

        c.glClearColor(0.2, 0.3, 0.3, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        c.glActiveTexture(c.GL_TEXTURE0);
        c.glBindTexture(c.GL_TEXTURE_2D, texture1);
        c.glActiveTexture(c.GL_TEXTURE1);
        c.glBindTexture(c.GL_TEXTURE_2D, texture2);

        const time: f32 = @floatCast(c.glfwGetTime());
        const rotation: zm.Mat = zm.rotationZ(time);
        const transform: zm.Mat = zm.mul(rotation, translation);

        program.use();
        const transformLoc = c.glGetUniformLocation(program.id, "transform");
        c.glUniformMatrix4fv(transformLoc, 1, c.GL_FALSE, zm.arrNPtr(&transform));

        c.glBindVertexArray(VAO);
        c.glDrawElements(c.GL_TRIANGLES, 6, c.GL_UNSIGNED_INT, @ptrFromInt(0));

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }

    return 0;
}
