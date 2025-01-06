## Base64 Encoder-Decoder in Zig
This is a simple base64 encoder-decoder I built in the process of learning Zig. The test vectors are directly picked from the [RFC](https://datatracker.ietf.org/doc/html/rfc4648#section-10)

To run the code:
```
git clone https://github.com/siddharth-reddy-1607/base64-encoder-decoder-zig.git
cd base64-encoder-decoder-zig 
zig test src/root.zig
```
Test results
```
Original Message -> f, Expected Encoding -> Zg==
Encoded Message -> Zg==
Decoded message -> f
Original Message -> fo, Expected Encoding -> Zm8=
Encoded Message -> Zm8=
Decoded message -> fo
Original Message -> foo, Expected Encoding -> Zm9v
Encoded Message -> Zm9v
Decoded message -> foo
Original Message -> foob, Expected Encoding -> Zm9vYg==
Encoded Message -> Zm9vYg==
Decoded message -> foob
Original Message -> fooba, Expected Encoding -> Zm9vYmE=
Encoded Message -> Zm9vYmE=
Decoded message -> fooba
Original Message -> foobar, Expected Encoding -> Zm9vYmFy
Encoded Message -> Zm9vYmFy
Decoded message -> foobar
```
