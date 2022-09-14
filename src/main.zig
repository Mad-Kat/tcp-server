const std = @import("std");
const network = @import("network");

const buffer_size = 1000;

pub fn main() !void {
    var args_iter = std.process.args();

    _ = args_iter.next() orelse return error.MissingArgument;
    const port_name = args_iter.next() orelse return error.MissingArgument;

    const port_number = try std.fmt.parseInt(u16, port_name, 10);

    var sock = try network.Socket.create(.ipv4, .tcp);
    defer sock.close();

    try sock.bindToPort(port_number);

    try sock.listen();

    while (true) {
        var client = try sock.accept();
        defer client.close();

        std.debug.print("Client connected from {}.\n", .{
            try client.getLocalEndPoint(),
        });

        runEchoClient(client) catch |err| {
            std.debug.print("Client disconnected with msg {s}.\n", .{
                @errorName(err),
            });
            continue;
        };
        std.debug.print("Client disconnected.\n", .{});
    }
}

fn runEchoClient(client: network.Socket) !void {
    while (true) {
        var buffer: [buffer_size]u8 = undefined;

        const len = try client.receive(&buffer);
        if (len == 0)
            break;
        // we ignore the amount of data sent.
        _ = try client.send(buffer[0..len]);
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
