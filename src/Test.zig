pub const ZPico = @import("ZPico");
pub const Expect = @import("std").testing.expect;

pub fn StrEql(a: []const u8, b: []const u8) bool {
    return @import("std").mem.eql(u8, a, b);
}

pub fn main() !void {
    const header: ZPico.Header = .{
        .name = "hola guapa",
    };

    @import("std").debug.print("{s}", .{header.name});
}

test "ParseRequest" {
    const buffer = "GET /hoge HTTP/1.1\r\nHost: example.com\r\nUser-Agent: \\343\\201\\262\\343/1.0\r\n\r\n";
    var headers: [100]ZPico.CHeader = undefined;

    const res = try ZPico.ParseRequest(buffer, &headers, 0);

    try Expect(res.headers.len == 2);
    try Expect(StrEql(res.path, "/hoge"));
    try Expect(StrEql(res.method, "GET"));
    try Expect(res.minorVersion == 1);
    try Expect(StrEql(res.headers[0].ToHeader().name, "Host"));
    try Expect(StrEql(res.headers[0].ToHeader().value, "example.com"));
    try Expect(StrEql(res.headers[1].ToHeader().name, "User-Agent"));
    try Expect(StrEql(res.headers[1].ToHeader().value, "\\343\\201\\262\\343/1.0"));

    @import("std").debug.print("size : {d}\n", .{res.bufferLenParsed});
}

test "ParseResponse" {
    const buffer = "HTTP/1.0 200 OK\r\nfoo: \r\nfoo: b\r\n  \tc\r\n\r\n";
    var headers: [100]ZPico.CHeader = undefined;

    const res = try ZPico.ParseResponse(buffer, &headers, 0);

    try Expect(res.headers.len == 3);
    try Expect(res.minorVersion == 0);
    try Expect(res.status == 200);
    try Expect(StrEql(res.message, "OK"));
    try Expect(StrEql(res.headers[0].ToHeader().name, "foo"));
    try Expect(StrEql(res.headers[0].ToHeader().value, ""));
    try Expect(StrEql(res.headers[1].ToHeader().name, "foo"));
    try Expect(StrEql(res.headers[1].ToHeader().value, "b"));
    try Expect(StrEql(res.headers[2].ToHeader().name, ""));
    try Expect(StrEql(res.headers[2].ToHeader().value, "  \tc"));

    @import("std").debug.print("size : {d}\n", .{res.bufferLenParsed});
}

test "ParseHeaders" {
    const buffer = "Host: example.com\r\nCookie: \r\n\r\n";
    var headers: [100]ZPico.CHeader = undefined;

    const res = try ZPico.ParseHeader(buffer, &headers, 0);

    try Expect(res.headers.len == 2);

    try Expect(StrEql(res.headers[0].ToHeader().name, "Host"));
    try Expect(StrEql(res.headers[0].ToHeader().value, "example.com"));
    try Expect(StrEql(res.headers[1].ToHeader().name, "Cookie"));
    try Expect(StrEql(res.headers[1].ToHeader().value, ""));
}
