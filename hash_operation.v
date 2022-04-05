module hash_op(
    input wire clk,
    input wire [31:0] a, b, c, d,
    input wire [511:0] m,
    output reg [31:0] a_out, b_out, c_out, d_out,
    output reg [511:0] m_out
);

parameter index = 0;
parameter s = 0;
parameter k = 0;

// --------------------------
function [31:0] f; // Round 1

input [31:0] b, c, d;

begin
    f = (b & c) | ((~b) & d);
end
endfunction
// --------------------------
function [31:0] g; // Round 2

input [31:0] b, c, d;

begin
    g = (b & c) | (c & (~d));
end
endfunction
// --------------------------
function [31:0] h; // Round 3

input [31:0] b, c, d;

begin
    h = b ^ c ^ d;
end
endfunction
// --------------------------
function [31:0] i; // Round 4

input [31:0] b, c, d;

begin
    i = c ^ (b | (~d));
end
endfunction
// --------------------------
function [31:0] little_endian_32b;

input [31:0] in;

begin
    little_endian_32b = {in[0 +: 8], in[8 +: 8], in[16 +: 8], in[24 +: 8]};
end
endfunction
// --------------------------
function [31:0] big_endian_32b;

input [31:0] in;

begin
    big_endian_32b = {in[24 +: 8], in[16 +: 8], in[8 +: 8], in[0 +: 8]};
end
endfunction
// --------------------------

reg [31:0] debug;

always @(posedge clk)
begin
    if (index < 16) begin
        debug <= little_endian_32b(m[512 - 32 - 32*(index%16) +: 32]);
        b_out <= b + ((((a + f(b, c, d) + debug) + k) << s) | (((a + f(b, c, d) + debug) + k) >> (32 - s)));
    end
    else if (index < 32) begin
        debug <= little_endian_32b(m[512 - 32 - 32*((5*index + 1)%16) +: 32]);
        b_out <= b + ((((a + g(b, c, d) + debug) + k) << s) | (((a + g(b, c, d) + debug) + k) >> (32 - s)));
    end
    else if (index < 48) begin
        debug <= little_endian_32b(m[512 - 32 - 32*((3*index + 5)%16) +: 32]);
        b_out <= b + ((((a + h(b, c, d) + debug) + k) << s) | (((a + h(b, c, d) + debug) + k) >> (32 - s)));
    end
    else begin
        debug <= little_endian_32b(m[512 - 32 - 32*((7*index)%16) +: 32]);
        b_out <= b + ((((a + i(b, c, d) + debug) + k) << s) | (((a + i(b, c, d) + debug) + k) >> (32 - s)));
    end

    a_out <= d;
    c_out <= b;
    d_out <= c;
    m_out <= m;
end
endmodule