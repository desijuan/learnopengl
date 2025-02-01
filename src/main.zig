const std = @import("std");
const c = @import("c.zig");
const zm = @import("zmath");

const math = std.math;

const ShaderProgram = @import("shader_program.zig");
const Camera = @import("camera.zig");

const SCR_WIDTH: u16 = 800;
const SCR_HEIGHT: u16 = 600;

var camera = Camera.init(
    .{ -2.0, 0.0, 3.0, 1.0 },
    .{ 2.0, 0.0, -3.0, 0.0 },
    .{ 0.0, 1.0, 0.0, 0.0 },
);

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

    // zig fmt: off

    const vertices = [_]f32{
       -0.5, -0.5, -0.5,
        0.5, -0.5, -0.5,
        0.5,  0.5, -0.5,
        0.5,  0.5, -0.5,
       -0.5,  0.5, -0.5,
       -0.5, -0.5, -0.5,

       -0.5, -0.5,  0.5,
        0.5, -0.5,  0.5,
        0.5,  0.5,  0.5,
        0.5,  0.5,  0.5,
       -0.5,  0.5,  0.5,
       -0.5, -0.5,  0.5,

       -0.5,  0.5,  0.5,
       -0.5,  0.5, -0.5,
       -0.5, -0.5, -0.5,
       -0.5, -0.5, -0.5,
       -0.5, -0.5,  0.5,
       -0.5,  0.5,  0.5,

        0.5,  0.5,  0.5,
        0.5,  0.5, -0.5,
        0.5, -0.5, -0.5,
        0.5, -0.5, -0.5,
        0.5, -0.5,  0.5,
        0.5,  0.5,  0.5,

       -0.5, -0.5, -0.5,
        0.5, -0.5, -0.5,
        0.5, -0.5,  0.5,
        0.5, -0.5,  0.5,
       -0.5, -0.5,  0.5,
       -0.5, -0.5, -0.5,

       -0.5,  0.5, -0.5,
        0.5,  0.5, -0.5,
        0.5,  0.5,  0.5,
        0.5,  0.5,  0.5,
       -0.5,  0.5,  0.5,
       -0.5,  0.5, -0.5,
    };

    // zig fmt: on

    const cubeSP: ShaderProgram = try ShaderProgram.compile(.{
        .vertex_path = "res/shaders/cube_vs.glsl",
        .fragment_path = "res/shaders/cube_fs.glsl",
    });
    defer cubeSP.delete();

    const lightSP: ShaderProgram = try ShaderProgram.compile(.{
        .vertex_path = "res/shaders/cube_vs.glsl",
        .fragment_path = "res/shaders/light_fs.glsl",
    });
    defer lightSP.delete();

    var cubeVAO: c.GLuint = undefined;
    c.glGenVertexArrays(1, &cubeVAO);
    defer c.glDeleteVertexArrays(1, &cubeVAO);

    var lightVAO: c.GLuint = undefined;
    c.glGenVertexArrays(1, &lightVAO);
    defer c.glDeleteVertexArrays(1, &lightVAO);

    var VBO: c.GLuint = undefined;
    c.glGenBuffers(1, &VBO);
    defer c.glDeleteBuffers(1, &VBO);

    c.glBindVertexArray(cubeVAO);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, VBO);
    c.glBufferData(c.GL_ARRAY_BUFFER, vertices.len * @sizeOf(f32), &vertices, c.GL_STATIC_DRAW);

    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 3 * @sizeOf(f32), @ptrFromInt(0));
    c.glEnableVertexAttribArray(0);

    c.glBindVertexArray(lightVAO);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, VBO);
    c.glBufferData(c.GL_ARRAY_BUFFER, vertices.len * @sizeOf(f32), &vertices, c.GL_STATIC_DRAW);

    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 3 * @sizeOf(f32), @ptrFromInt(0));
    c.glEnableVertexAttribArray(0);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);
    c.glBindVertexArray(0);

    while (c.glfwWindowShouldClose(window) != c.GL_TRUE) {
        const current_frame: f32 = @floatCast(c.glfwGetTime());
        delta_time = current_frame - last_frame;
        last_frame = current_frame;

        processInput(window);

        c.glClearColor(0.1, 0.1, 0.1, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);

        const projection: zm.Mat = zm.perspectiveFovRh(
            math.degreesToRadians(fov),
            @as(f32, @floatFromInt(scr_width)) / @as(f32, @floatFromInt(scr_height)),
            0.1,
            100.0,
        );
        const view: zm.Mat = camera.viewMat();

        const object_color = @Vector(3, f32){ 1.0, 0.5, 0.3 };
        const light_color = @Vector(3, f32){ 1.0, 1.0, 1.0 };

        const cube_model: zm.Mat = zm.scaling(0.5, 0.5, 0.5);

        cubeSP.use();
        cubeSP.setMat("model", &cube_model);
        cubeSP.setMat("view", &view);
        cubeSP.setMat("projection", &projection);
        cubeSP.setVec3("objectColor", &object_color);
        cubeSP.setVec3("lightColor", &light_color);

        c.glBindVertexArray(cubeVAO);
        c.glDrawArrays(c.GL_TRIANGLES, 0, 36);

        const light_model: zm.Mat = zm.mul(
            zm.translation(1.5, 1.5, 3.0),
            zm.scaling(0.2, 0.2, 0.2),
        );

        lightSP.use();
        lightSP.setMat("model", &light_model);
        lightSP.setMat("view", &view);
        lightSP.setMat("projection", &projection);
        lightSP.setVec3("lightColor", &light_color);

        c.glBindVertexArray(lightVAO);
        c.glDrawArrays(c.GL_TRIANGLES, 0, 36);

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }

    return 0;
}

var scr_width: c_int = SCR_WIDTH;
var scr_height: c_int = SCR_HEIGHT;

fn framebufferSizeCallback(_: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    scr_width = width;
    scr_height = height;
    c.glViewport(0, 0, width, height);
}

var cp_first_call: bool = true;

var last_x: f64 = SCR_WIDTH / 2;
var last_y: f64 = SCR_HEIGHT / 2;

var yaw: f64 = -90.0;
var pitch: f64 = 0.0;

const sensitivity: f64 = 0.1;

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

    camera.front = zm.normalize3(direction);
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

const speed: f32 = 2.5;

fn processInput(window: ?*c.GLFWwindow) void {
    const amount: f32 = speed * delta_time;

    if (c.glfwGetKey(window, c.GLFW_KEY_Q) == c.GLFW_PRESS)
        c.glfwSetWindowShouldClose(window, c.GL_TRUE)
    else if (c.glfwGetKey(window, c.GLFW_KEY_W) == c.GLFW_PRESS)
        camera.moveForward(amount)
    else if (c.glfwGetKey(window, c.GLFW_KEY_S) == c.GLFW_PRESS)
        camera.moveBackward(amount)
    else if (c.glfwGetKey(window, c.GLFW_KEY_A) == c.GLFW_PRESS)
        camera.moveLeft(amount)
    else if (c.glfwGetKey(window, c.GLFW_KEY_D) == c.GLFW_PRESS)
        camera.moveRight(amount);
}
