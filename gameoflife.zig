const uefi = @import("std").os.uefi;

const World = struct {
    buf: [24][80]bool,

    fn init() World {
        return World{
            .buf = [_][80]bool{[_]bool{false} ** 80} ** 24,
        };
    }

    fn neighs(self: World, row: u8, col: u8) u8 {
        var count: u8 = 0;
        for ([_]bool{
            self.buf[@mod(row + 24 - 1, 24)][@mod(col + 80 - 1, 80)],
            self.buf[@mod(row + 24 - 1, 24)][col],
            self.buf[@mod(row + 24 - 1, 24)][@mod(col + 80 + 1, 80)],
            self.buf[row][@mod(col + 80 - 1, 80)],
            self.buf[row][@mod(col + 80 + 1, 80)],
            self.buf[@mod(row + 24 + 1, 24)][@mod(col + 80 - 1, 80)],
            self.buf[@mod(row + 24 + 1, 24)][col],
            self.buf[@mod(row + 24 + 1, 24)][@mod(col + 80 + 1, 80)],
        }) |a| {
            if (a) {
                count += 1;
            }
        }
        return count;
    }

    fn step(self: *World) void {
        var tmp = [_][80]bool{[_]bool{false} ** 80} ** 24;
        var row: u8 = 0;
        var col: u8 = 0;
        while (row < 24) {
            while (col < 80) {
                if (self.buf[row][col]) {
                    switch (self.neighs(row, col)) {
                        2, 3 => {
                            tmp[row][col] = true;
                        },
                        else => {},
                    }
                } else {
                    if (self.neighs(row, col) == 3) {
                        tmp[row][col] = true;
                    }
                }
                col += 1;
            }
            col = 0;
            row += 1;
        }

        self.buf = tmp;
    }
};

pub fn main() noreturn {
    const con_out = uefi.system_table.getConOut().?;
    const stall = uefi.system_table.getBootServices().?.getStall().?;
    const reset_system = uefi.system_table.getRuntimeServices().?.getResetSystem().?;
    var world = World.init();
    world.buf[8][21] = true;
    world.buf[9][23] = true;
    world.buf[10][20] = true;
    world.buf[10][21] = true;
    world.buf[10][24] = true;
    world.buf[10][25] = true;
    world.buf[10][26] = true;
    _ = con_out.reset(false);
    var i: u16 = 0;
    while (i < 360) {
        _ = con_out.setCursorPosition(0, 0);
        for (world.buf) |row| {
            for (row) |c| {
                if (c) {
                    _ = con_out.outputString(&[_]u16{ '#', 0 });
                } else {
                    _ = con_out.outputString(&[_]u16{ ' ', 0 });
                }
            }
        }
        world.step();
        _ = stall(100000);
        i += 1;
    }
    reset_system(uefi.tables.ResetType.ResetShutdown, 0, 0, @intToPtr(*allowzero c_void, 0));
    unreachable;
}
