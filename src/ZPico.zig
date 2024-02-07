pub const c = @cImport(@cInclude("picohttpparser.h"));

pub const CHeader = extern struct {
    name: [*c]const u8 = undefined,
    name_len: usize = undefined,
    value: [*c]const u8 = undefined,
    value_len: usize = undefined,

    pub fn ToHeader(self: CHeader) Header {
        return .{
            .name = if (self.name != null) self.name[0..self.name_len] else "",
            .value = if (self.value != null) self.value[0..self.value_len] else "",
        };
    }
};

pub const Header = struct {
    name: []const u8 = undefined,
    value: []const u8 = undefined,
};

pub const Error = error{
    Incomplete, // The Request/Reponse/Headers is incomplete, you have to retry after receiving more data
    NotEnoughHeaders, // Need to allocate more headers and redo parsing
    ParsingError, // drop connection
};

pub const RequestResult = struct {
    method: []const u8 = undefined,
    path: []const u8 = undefined,
    minorVersion: u8 = undefined,
    headers: []CHeader = undefined,
    bufferLenParsed: u32 = undefined,
};

pub fn ParseRequest(buffer: []const u8, headers: []CHeader, previousLenParsed: usize) Error!RequestResult {
    var method: [*c]const u8 = undefined;
    var methodLen: usize = undefined;
    var path: [*c]const u8 = undefined;
    var pathLen: usize = undefined;
    var minorVersion: c_int = undefined;
    var headerLen: usize = headers.len;

    const ret = c.phr_parse_request(
        buffer.ptr,
        buffer.len,
        &method,
        &methodLen,
        &path,
        &pathLen,
        &minorVersion,
        @ptrCast(headers.ptr),
        &headerLen,
        previousLenParsed,
    );

    if (ret == -2)
        return error.Incomplete
    else if (ret == -1)
        return if (headerLen == headers.len) error.NotEnoughHeaders else error.ParsingError;

    return .{
        .bufferLenParsed = @intCast(ret),
        .headers = headers[0..headerLen],
        .minorVersion = @intCast(minorVersion),
        .path = path[0..pathLen],
        .method = method[0..methodLen],
    };
}

pub const ResponseResult = struct {
    message: []const u8 = undefined,
    minorVersion: u8 = undefined,
    headers: []CHeader = undefined,
    bufferLenParsed: u32 = undefined,
    status: u16 = undefined,
};

pub fn ParseResponse(buffer: []const u8, headers: []CHeader, previousLenParsed: usize) Error!ResponseResult {
    var message: [*c]const u8 = undefined;
    var messageLen: usize = undefined;
    var minorVersion: c_int = undefined;
    var headerLen: usize = headers.len;
    var status: c_int = undefined;

    const ret = c.phr_parse_response(
        buffer.ptr,
        buffer.len,
        &minorVersion,
        &status,
        &message,
        &messageLen,
        @ptrCast(headers.ptr),
        &headerLen,
        previousLenParsed,
    );

    if (ret == -2)
        return error.Incomplete
    else if (ret == -1)
        return if (headerLen == headers.len) error.NotEnoughHeaders else error.ParsingError;

    return .{
        .message = message[0..messageLen],
        .bufferLenParsed = @intCast(ret),
        .headers = headers[0..headerLen],
        .minorVersion = @intCast(minorVersion),
        .status = @intCast(status),
    };
}

pub const HeaderResult = struct {
    headers: []CHeader = undefined,
    bufferLenParsed: u32 = undefined,
};

pub fn ParseHeader(buffer: []const u8, headers: []CHeader, previousLenParsed: usize) Error!HeaderResult {
    var headerLen: usize = headers.len;

    const ret = c.phr_parse_headers(
        buffer.ptr,
        buffer.len,
        @ptrCast(headers.ptr),
        &headerLen,
        previousLenParsed,
    );

    if (ret == -2)
        return error.Incomplete
    else if (ret == -1)
        return if (headerLen == headers.len) error.NotEnoughHeaders else error.ParsingError;

    return .{
        .headers = headers[0..headerLen],
        .bufferLenParsed = @intCast(ret),
    };
}
