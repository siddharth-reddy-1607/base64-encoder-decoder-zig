//References
//https://pedropark99.github.io/zig-book/Chapters/01-base64.html
//https://datatracker.ietf.org/doc/html/rfc4648

const std = @import("std");
const testing = std.testing;

const bitwiseAndError = error{stringLengthNotEqualError};
const mapSearchError = error{encodedLetterNotFoundError};
const inputLenghtError = error{inputLengthZeroError};

fn bitwiseAndBinaryStrings(a: []const u8, b: []const u8) bitwiseAndError!u8 {
    //We will be adding a with "111111". In our case, both must of the length 6 (Base64)
    if (a.len != b.len) {
        return bitwiseAndError.stringLengthNotEqualError;
    }
    var val: u8 = 0;
    for (0..a.len) |idx| {
        const shift: u3 = @intCast(a.len - idx - 1);
        if (a[idx] == '0' or b[idx] == '0') {
            continue;
        }
        val |= @as(u8, 1) << shift;
    }
    return val;
}

const base64_encoder_decoder = struct {
    map: *const [64]u8 = "ABCDEFGHIJKLMNOPQRSTUVWXYZ" ++ "abcdefghijklmnopqrstuvwxyz" ++ "0123456789+/",

    fn getIndexForEncodedLetter(self: *const base64_encoder_decoder, encodedLetter: u8) mapSearchError!u6 {
        var idx: u7 = 0;
        for (self.map) |letter| {
            if (letter == encodedLetter) {
                return @intCast(idx);
            }
            idx += 1;
        }
        std.debug.print("Letter {c} not found in {s}\n", .{ encodedLetter, self.map });
        return mapSearchError.encodedLetterNotFoundError;
    }

    fn encode(self: *const base64_encoder_decoder, allocator: std.mem.Allocator, input: []const u8) ![]u8 {
        if (input.len == 0) return inputLenghtError.inputLengthZeroError;
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

        //If the last quantum has 1 byte, we add xxxxxx xx0000 + 2 Padding
        //If the last quantum has 2 byte, we add xxxxxx xxxxxx xxxx00 + 1 Padding
        const inputBin = try allocator.alloc(u8, input.len * 8 + (2 * padding)); //Size of the input after padding with 0s described above
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

        const encodedMsg = try allocator.alloc(u8, encodedMsgSize);
        inputIdx = 0;
        var idx: usize = 0;
        while (inputIdx < inputBin.len) : (inputIdx += 6) {
            const val = try bitwiseAndBinaryStrings(inputBin[inputIdx .. inputIdx + 6], "111111"[0..]);
            encodedMsg[idx] = self.map[val];
            idx += 1;
        }
        for (0..padding) |_| {
            encodedMsg[idx] = '=';
            idx += 1;
        }
        std.debug.print("Encoded Message -> {s}\n", .{encodedMsg});
        return encodedMsg;
    }

    fn decode(self: *const base64_encoder_decoder, allocator: std.mem.Allocator, input: []const u8) ![]u8 {
        if (input.len == 0) return inputLenghtError.inputLengthZeroError;
        var padding: usize = 0;
        if (input[input.len - 1] == '=') {
            padding += 1;
        }
        if (input[input.len - 2] == '=') {
            padding += 1;
        }

        var inputBin = try allocator.alloc(u8, (input.len - padding) * 6);
        var idx: usize = 0;
        for (input) |letter| {
            if (letter == '=') {
                padding += 1;
                continue;
            }
            const encodedLetterIdx = try self.getIndexForEncodedLetter(letter);
            var shift: u3 = 5;
            while (true) {
                inputBin[idx] = if ((encodedLetterIdx >> shift) & 1 == 1) '1' else '0';
                idx += 1;
                if (shift == 0) break;
                shift -= 1;
            }
        }

        //Remove the last two zeros in xxxxxx xxxxxx xxxx00 when there is 1 padding and last 4 zeros in xxxxxx xx00000 when there is 2 padding
        const decodedMsg = try allocator.alloc(u8, inputBin.len / 8);
        idx = 0;
        var decodedMsgIdx: usize = 0;
        while (idx + 7 < inputBin.len) : (idx += 8) {
            const val = try bitwiseAndBinaryStrings(inputBin[idx .. idx + 8], "11111111");
            decodedMsg[decodedMsgIdx] = val;
            decodedMsgIdx += 1;
        }
        std.debug.print("Decoded message -> {s}\n", .{decodedMsg});
        return decodedMsg;
    }
};

test "base64_encoder_decoder_test" {
    const b64_encoder_decoder = &base64_encoder_decoder{};

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const aa = arena.allocator();

    const file = try std.fs.cwd().openFile("testVectors", .{});
    defer file.close();

    while (try file.reader().readUntilDelimiterOrEofAlloc(aa, '\n', std.math.maxInt(u64))) |line| {
        var it = std.mem.splitScalar(u8, line, ' ');
        const originalMessage = it.next().?;
        const expectedEncoding = it.next().?;
        std.debug.print("Original Message -> {s}, Expected Encoding -> {s}\n", .{ originalMessage, expectedEncoding });
        const encodedMessage = try b64_encoder_decoder.encode(aa, originalMessage);
        try std.testing.expectEqualStrings(expectedEncoding, encodedMessage);
        const decodedMessage = try b64_encoder_decoder.decode(aa, encodedMessage);
        try std.testing.expectEqualStrings(originalMessage, decodedMessage);
    }
}
