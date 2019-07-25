const Builder = @import("std").build.Builder;
const builtin = @import("builtin");

pub fn build(b: *Builder) void {
    const exe = b.addExecutable("bootx64", "gameoflife.zig");
    exe.setBuildMode(b.standardReleaseOptions());
    exe.setTarget(builtin.Arch.x86_64, builtin.Os.uefi, builtin.Abi.none);
    exe.setOutputDir("EFI/Boot");
    b.default_step.dependOn(&exe.step);
}
