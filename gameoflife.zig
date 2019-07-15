const uefi = @import("zig-uefi/uefi.zig");

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

export fn EfiMain(handle: uefi.types.Handle, system_table: *uefi.tables.SystemTable) noreturn {
    _ = system_table.conOut().?.reset(false);
    const on = [_]uefi.types.Char16{ '#', 0 };
    const off = [_]uefi.types.Char16{ ' ', 0 };
    var world = World.init();
    world.buf[8][21] = true;
    world.buf[9][23] = true;
    world.buf[10][20] = true;
    world.buf[10][21] = true;
    world.buf[10][24] = true;
    world.buf[10][25] = true;
    world.buf[10][26] = true;
    while (true) {
        _ = system_table.conOut().?.setCursorPosition(0, 0);
        for (world.buf) |row| {
            for (row) |c| {
                if (c) {
                    _ = system_table.conOut().?.outputString(&on);
                } else {
                    _ = system_table.conOut().?.outputString(&off);
                }
            }
        }
        world.step();
    }
}
