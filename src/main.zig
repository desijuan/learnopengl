const std = @import("std");
const c = @import("c.zig");
const zm = @import("zmath");
const ShaderProgram = @import("shader_program.zig");

const math = std.math;

const SCR_WIDTH: u16 = 800;
const SCR_HEIGHT: u16 = 600;

var scr_width: c_int = 800;
var scr_height: c_int = 600;

fn framebufferSizeCallback(_: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    scr_width = width;
    scr_height = height;
    c.glViewport(0, 0, width, height);
}

var yaw: f64 = -90.0;
var pitch: f64 = 0.0;

const sensitivity: f64 = 0.1;

var last_x: f64 = SCR_WIDTH / 2;
var last_y: f64 = SCR_HEIGHT / 2;

var cp_first_call: bool = true;

fn cursorPosCallback(_: ?*c.GLFWwindow, xpos: f64, ypos: f64) callconv(.C) void {
    if (cp_first_call) {
        cp_first_call = false;
        last_x = xpos;
        last_y = ypos;
    }

    var xoffset: f64 = xpos - last_x;
    var yoffset: f64 = last_y - ypos;
    last_x = xpos;
    last_y = ypos;

    xoffset *= sensitivity;
    yoffset *= sensitivity;

    yaw += xoffset;
    pitch += yoffset;

    if (pitch < -89.0)
        pitch = -89.0
    else if (pitch > 89.0)
        pitch = 89.0;

    const direction = zm.Vec{
        @floatCast(math.cos(math.degreesToRadians(yaw)) * math.cos(math.degreesToRadians(pitch))),
        @floatCast(math.sin(math.degreesToRadians(pitch))),
        @floatCast(math.sin(math.degreesToRadians(yaw)) * math.cos(math.degreesToRadians(pitch))),
        0.0,
    };

    camera_front = zm.normalize3(direction);
}

var fov: f32 = 45.0;

fn scrollCallback(_: ?*c.GLFWwindow, _: f64, yoffset: f64) callconv(.C) void {
    fov -= @floatCast(yoffset);
    if (fov < 1.0)
        fov = 1.0
    else if (fov > 80.0)
        fov = 80.0;
}

var delta_time: f32 = 0.0;
var last_frame: f32 = 0.0;

var camera_pos = zm.Vec{ 0.0, 0.0, 3.0, 1.0 };
var camera_front = zm.Vec{ 0.0, 0.0, -1.0, 0.0 };
var camera_up = zm.Vec{ 0.0, 1.0, 0.0, 0.0 };

inline fn splat4f(k: f32) @Vector(4, f32) {
    return @splat(k);
}

fn processInput(window: ?*c.GLFWwindow) void {
    const speed: f32 = 2.5 * delta_time;

    if (c.glfwGetKey(window, c.GLFW_KEY_Q) == c.GLFW_PRESS)
        c.glfwSetWindowShouldClose(window, c.GL_TRUE)
    else if (c.glfwGetKey(window, c.GLFW_KEY_W) == c.GLFW_PRESS)
        camera_pos += splat4f(speed) * camera_front
    else if (c.glfwGetKey(window, c.GLFW_KEY_S) == c.GLFW_PRESS)
        camera_pos -= splat4f(speed) * camera_front
    else if (c.glfwGetKey(window, c.GLFW_KEY_A) == c.GLFW_PRESS)
        camera_pos -= splat4f(speed) * zm.normalize3(zm.cross3(camera_front, camera_up))
    else if (c.glfwGetKey(window, c.GLFW_KEY_D) == c.GLFW_PRESS)
        camera_pos += splat4f(speed) * zm.normalize3(zm.cross3(camera_front, camera_up));
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

    c.glfwSetInputMode(window, c.GLFW_CURSOR, c.GLFW_CURSOR_DISABLED);

    _ = c.glfwSetFramebufferSizeCallback(window, framebufferSizeCallback);
    _ = c.glfwSetCursorPosCallback(window, cursorPosCallback);
    _ = c.glfwSetScrollCallback(window, scrollCallback);

    if (c.gladLoadGLLoader(@ptrCast(&c.glfwGetProcAddress)) != c.GL_TRUE) {
        std.log.err("Failed to initialize GLAD", .{});
        return 1;
    }

    std.log.info("OpenGL {s}", .{c.glGetString(c.GL_VERSION)});

    c.glEnable(c.GL_DEPTH_TEST);

    const program: ShaderProgram = try ShaderProgram.compile(.{
        .vertex_path = "res/shaders/vertex_shader.glsl",
        .fragment_path = "res/shaders/fragment_shader.glsl",
    });
    defer program.delete();

    // zig fmt: off

    const vertices = [_]f32{
       -0.5, -0.5, -0.5,  0.0, 0.0,
        0.5, -0.5, -0.5,  1.0, 0.0,
        0.5,  0.5, -0.5,  1.0, 1.0,
        0.5,  0.5, -0.5,  1.0, 1.0,
       -0.5,  0.5, -0.5,  0.0, 1.0,
       -0.5, -0.5, -0.5,  0.0, 0.0,

       -0.5, -0.5,  0.5,  0.0, 0.0,
        0.5, -0.5,  0.5,  1.0, 0.0,
        0.5,  0.5,  0.5,  1.0, 1.0,
        0.5,  0.5,  0.5,  1.0, 1.0,
       -0.5,  0.5,  0.5,  0.0, 1.0,
       -0.5, -0.5,  0.5,  0.0, 0.0,

       -0.5,  0.5,  0.5,  1.0, 0.0,
       -0.5,  0.5, -0.5,  1.0, 1.0,
       -0.5, -0.5, -0.5,  0.0, 1.0,
       -0.5, -0.5, -0.5,  0.0, 1.0,
       -0.5, -0.5,  0.5,  0.0, 0.0,
       -0.5,  0.5,  0.5,  1.0, 0.0,

        0.5,  0.5,  0.5,  1.0, 0.0,
        0.5,  0.5, -0.5,  1.0, 1.0,
        0.5, -0.5, -0.5,  0.0, 1.0,
        0.5, -0.5, -0.5,  0.0, 1.0,
        0.5, -0.5,  0.5,  0.0, 0.0,
        0.5,  0.5,  0.5,  1.0, 0.0,

       -0.5, -0.5, -0.5,  0.0, 1.0,
        0.5, -0.5, -0.5,  1.0, 1.0,
        0.5, -0.5,  0.5,  1.0, 0.0,
        0.5, -0.5,  0.5,  1.0, 0.0,
       -0.5, -0.5,  0.5,  0.0, 0.0,
       -0.5, -0.5, -0.5,  0.0, 1.0,

       -0.5,  0.5, -0.5,  0.0, 1.0,
        0.5,  0.5, -0.5,  1.0, 1.0,
        0.5,  0.5,  0.5,  1.0, 0.0,
        0.5,  0.5,  0.5,  1.0, 0.0,
       -0.5,  0.5,  0.5,  0.0, 0.0,
       -0.5,  0.5, -0.5,  0.0, 1.0,
    };

    const cube_positions = [_]@Vector(3, f32){
        .{  0.0,  0.0,  0.0  },
        .{  2.0,  5.0, -15.0 },
        .{ -1.5, -2.2, -2.5  },
        .{ -3.8, -2.0, -12.3 },
        .{  2.4, -0.4, -3.5  },
        .{ -1.7,  3.0, -7.5  },
        .{  1.3, -2.0, -2.5  },
        .{  1.5,  2.0, -2.5  },
        .{  1.5,  0.2, -1.5  },
        .{ -1.3,  1.0, -1.5  },
    };

    // zig fmt: on

    var VAO: c.GLuint = undefined;
    c.glGenVertexArrays(1, &VAO);
    defer c.glDeleteVertexArrays(1, &VAO);

    var VBO: c.GLuint = undefined;
    c.glGenBuffers(1, &VBO);
    defer c.glDeleteBuffers(1, &VBO);

    c.glBindVertexArray(VAO);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, VBO);
    c.glBufferData(c.GL_ARRAY_BUFFER, vertices.len * @sizeOf(f32), &vertices, c.GL_STATIC_DRAW);

    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 5 * @sizeOf(f32), @ptrFromInt(0));
    c.glVertexAttribPointer(1, 2, c.GL_FLOAT, c.GL_FALSE, 5 * @sizeOf(f32), @ptrFromInt(3 * @sizeOf(f32)));
    c.glEnableVertexAttribArray(0);
    c.glEnableVertexAttribArray(1);

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

    while (c.glfwWindowShouldClose(window) != c.GL_TRUE) {
        const current_frame: f32 = @floatCast(c.glfwGetTime());
        delta_time = current_frame - last_frame;
        last_frame = current_frame;

        processInput(window);

        c.glClearColor(0.2, 0.3, 0.3, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);

        c.glActiveTexture(c.GL_TEXTURE0);
        c.glBindTexture(c.GL_TEXTURE_2D, texture1);
        c.glActiveTexture(c.GL_TEXTURE1);
        c.glBindTexture(c.GL_TEXTURE_2D, texture2);

        const projection: zm.Mat = zm.perspectiveFovRh(
            math.degreesToRadians(fov),
            @as(f32, @floatFromInt(scr_width)) / @as(f32, @floatFromInt(scr_height)),
            0.1,
            100.0,
        );

        const view: zm.Mat = zm.lookAtRh(
            camera_pos,
            camera_pos + camera_front,
            camera_up,
        );

        program.use();
        program.setMat("projection", zm.arrNPtr(&projection));
        program.setMat("view", zm.arrNPtr(&view));

        c.glBindVertexArray(VAO);

        for (cube_positions, 0..) |v, i| {
            const translation: zm.Mat = zm.translation(v[0], v[1], v[2]);
            const angle: f32 = 20.0 * @as(f32, @floatFromInt(i));
            const rotation: zm.Mat = zm.matFromAxisAngle(zm.f32x4(1.0, 0.3, 0.5, 1.0), math.degreesToRadians(angle));
            const model: zm.Mat = zm.mul(rotation, translation);
            program.setMat("model", zm.arrNPtr(&model));

            c.glDrawArrays(c.GL_TRIANGLES, 0, 36);
        }

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }

    return 0;
}
