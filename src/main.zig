const std = @import("std");
const buffer_size = 1000;

pub fn main() !void {

    // var args_iter = std.process.args();
    // _ = args_iter.next() orelse return error.MissingArgument;
    // const port_name = args_iter.next() orelse return error.MissingArgument;

    // const port_number = try std.fmt.parseInt(u16, port_name, 10);
    const port_number: u16 = 3000;

    const socket_type = std.os.SOCK.STREAM | std.os.SOCK.CLOEXEC;
    var sock_fn = try std.os.socket(std.os.AF.INET, socket_type, 0);
    defer std.os.close(sock_fn);

    var address = comptime std.net.Address.parseIp("127.0.0.1", port_number) catch unreachable;
    try std.os.bind(sock_fn, &address.any, address.getOsSockLen());

    try std.os.listen(sock_fn, 0);

    while (true) {
        var addr: std.os.sockaddr.in6 = undefined;
        var addr_size: std.os.socklen_t = @sizeOf(std.os.sockaddr.in6);
        var addr_ptr = @ptrCast(*std.os.sockaddr, &addr);
        var client = try std.os.accept(sock_fn, addr_ptr, &addr_size, 0);
        errdefer std.os.close(client);

        std.debug.print("Client connected", .{});

        runEchoClient(&client) catch |err| {
            std.debug.print("Client disconnected with msg {s}.\n", .{
                @errorName(err),
            });
            continue;
        };
        std.debug.print("Client disconnected.\n", .{});
    }
}

fn runEchoClient(client: *std.os.socket_t) !void {
    while (true) {
        var buffer: [buffer_size]u8 = undefined;

        const len = try std.os.recvfrom(client.*, &buffer, std.os.linux.MSG.NOSIGNAL, null, null);

        if (len == 0)
            break;
        // we ignore the amount of data sent.
        _ = try std.os.send(client.*, buffer[0..len], std.os.linux.MSG.NOSIGNAL);
    }
}
