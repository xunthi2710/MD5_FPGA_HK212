module md5_core_tb();

reg clk = 0;
reg [447:0] message;
reg [63:0] len;
wire [127:0] hash;
wire [511:0] message_out;

md5core dut(
    .clk(clk),
    .message(message),
    .length(len),
    .hash(hash),
    .message_out(message_out)
);

always begin
    #1 clk = !clk;
end

initial begin
    #10 
    message = 448'h54686579206172652064657465726D696E697374696380000000000000000000000000000000000000000000000000000000000000000000;
    len = 64'h00000000000000B0;
end

endmodule