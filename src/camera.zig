const std = @import("std");
const zm = @import("zmath");

pos: zm.Vec,
front: zm.Vec,
up: zm.Vec,
right: zm.Vec,

const Self = @This();

pub fn init(pos: zm.Vec, front: zm.Vec, world_up: zm.Vec) Self {
    const right: zm.Vec = zm.cross3(front, world_up);
    const up: zm.Vec = zm.cross3(right, front);

    return Self{
        .pos = pos,
        .front = zm.normalize3(front),
        .up = zm.normalize3(up),
        .right = zm.normalize3(right),
    };
}

pub fn viewMat(self: Self) zm.Mat {
    return zm.lookToRh(
        self.pos,
        self.front,
        self.up,
    );
}

pub fn moveForward(self: *Self, amount: f32) void {
    self.pos += act(amount, self.front);
}

pub fn moveBackward(self: *Self, amount: f32) void {
    self.pos -= act(amount, self.front);
}

pub fn moveLeft(self: *Self, amount: f32) void {
    // self.pos -= act(amount, self.right);
    self.pos -= act(amount, zm.normalize3(zm.cross3(self.front, self.up)));
}

pub fn moveRight(self: *Self, amount: f32) void {
    // self.pos += act(amount, self.right);
    self.pos += act(amount, zm.normalize3(zm.cross3(self.front, self.up)));
}

// Why isn this not working properly?
pub fn turn(self: *Self, right: f32, up: f32) void {
    const q: zm.Quat = zm.quatFromRollPitchYaw(up, -right, 0.0);

    self.front = zm.rotate(q, self.front);
    self.up = zm.rotate(q, self.up);
    self.right = zm.rotate(q, self.right);
}

pub fn print(self: Self) void {
    std.debug.print(
        "  pos: {d}\nfront: {d}\n   up: {d}\nright: {d}\n\n",
        .{ self.pos, self.front, self.up, self.right },
    );
}

inline fn act(k: f32, v: zm.Vec) zm.Vec {
    return @as(zm.Vec, @splat(k)) * v;
}
