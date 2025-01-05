const std = @import("std");
const testing = std.testing;

const bitwiseAndError = error{stringLengthNotEqualError};

fn bitwiseAndBinaryStrings(a: []const u8, b: []const u8) bitwiseAndError!u8 {
    //We will be adding a with "111111". In our case, both must of the length 6 (Base64)
    if (a.len != b.len) {
        return bitwiseAndError.stringLengthNotEqualError;
    }
    // std.debug.print("a = {s},b = {s}\n", .{ a, b });
    var val: u8 = 0;
    for (0..a.len) |idx| {
        const shift: u3 = @intCast(a.len - idx - 1);
        // std.debug.print("Shift = {d}\n", .{shift});
        if (a[idx] == '0' or b[idx] == '0') {
            continue;
        }
        val |= @as(u8, 1) << shift;
    }
    return val;
}

const base64_encoder_decoder = struct {
    map: *const [64]u8 = "ABCDEFGHIJKLMNOPQRSTUVWXYZ" ++ "abcdefghijklmnopqrstuvwxyz" ++ "0123456789+-",
    // fn init(self: *const base64_encoder_decoder) void {
    //     self.map = "ABCDEFGHJKLMNOPQRSTUVWZYZ" ++ "abcdefghijklmnopqrstuvwxyz" ++ "0123456789+-";
    // }
    fn encode(self: *const base64_encoder_decoder, allocator: std.mem.Allocator, input: []const u8) !void {
        //3 Bytes in input message correspond to 4 Bytes in the encoded message
        var padding: usize = 0;
        var encodedMsgSize: usize = ((input.len / 3) * 4);
        switch (input.len % 3) {
            //Need 2 more byte to make input a multiple of size 24, with padding of 2
            1 => {
                encodedMsgSize += 4;
                padding = 2;
            },
            //Need 1 more byte to make input a multiple of size 24, with padding of 1
            2 => {
                encodedMsgSize += 4;
                padding = 1;
            },
            else => {},
        }
        const encodedMsg = try allocator.alloc(u8, encodedMsgSize);
        defer allocator.free(encodedMsg);
        //If the last quantum has 1 byte, we add xxxxxx xx0000 + 2 Padding
        //If the last quantum has 2 byte, we add xxxxxx xxxxxx xxxx00 + 1 Padding
        const inputBin = try allocator.alloc(u8, input.len * 8 + (2 * padding)); //Size of the input after padding with 0s described above
        defer allocator.free(inputBin);
        var inputIdx: usize = 0;
        for (input) |letter| {
            var shift: u3 = 7;
            while (true) {
                if (letter >> shift & 1 == 1) {
                    inputBin[inputIdx] = '1';
                } else {
                    inputBin[inputIdx] = '0';
                }
                inputIdx += 1;
                if (shift == 0) {
                    break;
                }
                shift -= 1;
            }
        }
        for (0..padding * 2) |_| {
            inputBin[inputIdx] = '0';
            inputIdx += 1;
        }
        std.debug.print("{s},{d}\n", .{ inputBin, inputBin.len });
        inputIdx = 0;
        var idx: usize = 0;
        while (inputIdx < inputBin.len) : (inputIdx += 6) {
            std.debug.print("String length = {d}, at inputIdx = {d}", .{ inputBin.len, inputIdx });
            const val = bitwiseAndBinaryStrings(inputBin[inputIdx .. inputIdx + 6], "111111"[0..]) catch |err| {
                std.debug.print("String length = {d}, at inputIdx = {d} - {any}", .{ inputBin.len, inputIdx, err });
                return;
            };
            std.debug.print("Encoding Char = {c},{b}\n", .{ self.map[val], val });
            encodedMsg[idx] = self.map[val];
            idx += 1;
        }
        for (0..padding) |_| {
            encodedMsg[idx] = '=';
            idx += 1;
        }
        std.debug.print("Encoded Message -> {s}\n", .{encodedMsg});
    }
};

test "base64_encoder_decoder_test" {
    const b64_encoder_decoder = &base64_encoder_decoder{};
    std.debug.print("{s}\n", .{b64_encoder_decoder.map});
    try b64_encoder_decoder.encode(std.testing.allocator, "dafgxvsabsdfag"[0..]);
}
