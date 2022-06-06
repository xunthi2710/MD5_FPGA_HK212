//=========================================================
//
// MD5_core.v
//
// The MD5 hash function core.
//=========================================================
//
//---------------------------------------------------------
module MD5_core(
    input wire clk,
    input wire reset_n,

    input wire init,
    input wire next,
    
    input wire [511:0] block,
    output wire [127:0] digest,
    output wire ready
);

//---------------------------------------------------------
// Internal constant and parameter definitions.
//---------------------------------------------------------
localparam A0 = 32'h67452301;
localparam B0 = 32'hefcdab89;
localparam C0 = 32'h98badcfe;
localparam D0 = 32'h10325476;

localparam CTRL_IDLE = 3'h0;
localparam CTRL_PIPE = 3'h1;
localparam CTRL_LOOP = 3'h2;
localparam CTRL_FINISH = 3'h3;

localparam NUM_ROUNDS = 64;

//---------------------------------------------------------
// Register including update variables and write enable.
//---------------------------------------------------------
reg [31:0] h0_reg;
reg [31:0] h0_new;
reg [31:0] h1_reg;
reg [31:0] h1_new;
reg [31:0] h2_reg;
reg [31:0] h2_new;
reg [31:0] h3_reg;
reg [31:0] h3_new;
reg h_we;

reg [31:0] a_reg;
reg [31:0] a_new;
reg [31:0] b_reg;
reg [31:0] b_new;
reg [31:0] c_reg;
reg [31:0] c_new;
reg [31:0] d_reg;
reg [31:0] d_new;
reg a_d_we;

reg [31:0] pipe_b_reg;
reg [31:0] pipe_b_new;

reg ready_reg;
reg ready_new;
reg ready_we;

reg [31:0] block_reg [0:15];
reg block_we;

reg [6:0] round_ctr_reg;
reg [6:0] round_ctr_new;
reg round_ctr_inc;
reg round_ctr_rst;
reg round_ctr_we;

reg [2:0] MD5_core_ctrl_reg;
reg [2:0] MD5_core_ctrl_new;
reg MD5_core_ctrl_we;

//---------------------------------------------------------
// Wires.
//---------------------------------------------------------
reg init_state;
reg update_state;
reg init_round;
reg update_round;

//---------------------------------------------------------
// Function declarations.
//---------------------------------------------------------
// F non-linear functions.
function [31:0] F(
    input [31:0] b,
    input [31:0] c,
    input [31:0] d,
    input [5:0] round
);
    begin
        if (round < 16)
            F = (b & c) | ((~b) & d);
        else if ((round >= 16) && (round < 32))
            F = (d & b) | ((~d) & c);
        else if ((round >= 32) && (round < 48))
            F = b ^ c ^ d;
        else // (round >= 48)
            F = c ^ (b | (~d));
    end
endfunction

//---------------------------
// K constants
function [31:0] K(
    input [5:0] round
);
    begin
        case (round)
            6'h00: K = 32'hd76aa478;
            6'h01: K = 32'he8c7b756;
            6'h02: K = 32'h242070db;
            6'h03: K = 32'hc1bdceee;
            6'h04: K = 32'hf57c0faf;
            6'h05: K = 32'h4787c62a;
            6'h06: K = 32'ha8304613;
            6'h07: K = 32'hfd469501;
            6'h08: K = 32'h698098d8;
            6'h09: K = 32'h8b44f7af;
            6'h0a: K = 32'hffff5bb1;
            6'h0b: K = 32'h895cd7be;
            6'h0c: K = 32'h6b901122;
            6'h0d: K = 32'hfd987193;
            6'h0e: K = 32'ha679438e;
            6'h0f: K = 32'h49b40821;
            6'h10: K = 32'hf61e2562;
            6'h11: K = 32'hc040b340;
            6'h12: K = 32'h265e5a51;
            6'h13: K = 32'he9b6c7aa;
            6'h14: K = 32'hd62f105d;
            6'h15: K = 32'h02441453;
            6'h16: K = 32'hd8a1e681;
            6'h17: K = 32'he7d3fbc8;
            6'h18: K = 32'h21e1cde6;
            6'h19: K = 32'hc33707d6;
            6'h1a: K = 32'hf4d50d87;
            6'h1b: K = 32'h455a14ed;
            6'h1c: K = 32'ha9e3e905;
            6'h1d: K = 32'hfcefa3f8;
            6'h1e: K = 32'h676f02d9;
            6'h1f: K = 32'h8d2a4c8a;
            6'h20: K = 32'hfffa3942;
            6'h21: K = 32'h8771f681;
            6'h22: K = 32'h6d9d6122;
            6'h23: K = 32'hfde5380c;
            6'h24: K = 32'ha4beea44;
            6'h25: K = 32'h4bdecfa9;
            6'h26: K = 32'hf6bb4b60;
            6'h27: K = 32'hbebfbc70;
            6'h28: K = 32'h289b7ec6;
            6'h29: K = 32'heaa127fa;
            6'h2a: K = 32'hd4ef3085;
            6'h2b: K = 32'h04881d05;
            6'h2c: K = 32'hd9d4d039;
            6'h2d: K = 32'he6db99e5;
            6'h2e: K = 32'h1fa27cf8;
            6'h2f: K = 32'hc4ac5665;
            6'h30: K = 32'hf4292244;
            6'h31: K = 32'h432aff97;
            6'h32: K = 32'hab9423a7;
            6'h33: K = 32'hfc93a039;
            6'h34: K = 32'h655b59c3;
            6'h35: K = 32'h8f0ccc92;
            6'h36: K = 32'hffeff47d;
            6'h37: K = 32'h85845dd1;
            6'h38: K = 32'h6fa87e4f;
            6'h39: K = 32'hfe2ce6e0;
            6'h3a: K = 32'ha3014314;
            6'h3b: K = 32'h4e0811a1;
            6'h3c: K = 32'hf7537e82;
            6'h3d: K = 32'hbd3af235;
            6'h3e: K = 32'h2ad7d2bb;
            6'h3f: K = 32'heb86d391;
        endcase
    end
endfunction

//---------------------------
// Round based shift amount.
function [31:0] rotate(
    input [31:0] x,
    input [5:0] round
);
    begin
        if (round < 16)
            case (round[1:0])
                0: rotate = {x[24:0], x[31:25]};    // 7
                1: rotate = {x[19:0], x[31:20]};    // 12
                2: rotate = {x[14:0], x[31:15]};    // 17
                3: rotate = {x[09:0], x[31:10]};    // 22
            endcase
        else if ((round >= 16) && (round < 32))
            case (round[1:0])
                0: rotate = {x[26:0], x[31:27]};    // 5
                1: rotate = {x[22:0], x[31:23]};    // 9
                2: rotate = {x[17:0], x[31:18]};    // 14
                3: rotate = {x[11:0], x[31:12]};    // 20
            endcase
        else if ((round >= 32) && (round < 48))
            case (round[1:0])
                0: rotate = {x[27:0], x[31:28]};    // 4
                1: rotate = {x[20:0], x[31:21]};    // 11
                2: rotate = {x[15:0], x[31:16]};    // 16
                3: rotate = {x[08:0], x[31:09]};    // 23
            endcase
        else  // (round >= 48)
            case (round[1:0])
                0: rotate = {x[25:0], x[31:26]};    // 6
                1: rotate = {x[21:0], x[31:22]};    // 10
                2: rotate = {x[16:0], x[31:17]};    // 15
                3: rotate = {x[10:0], x[31:11]};    // 21
            endcase
    end
endfunction

//---------------------------
// Schedule of words in the message block.
function [3:0] G(
    input [5:0] round
);
    begin
        case (round)
            6'h00: G = 0;
            6'h01: G = 1;
            6'h02: G = 2;
            6'h03: G = 3;
            6'h04: G = 4;
            6'h05: G = 5;
            6'h06: G = 6;
            6'h07: G = 7;
            6'h08: G = 8;
            6'h09: G = 9;
            6'h0a: G = 10;
            6'h0b: G = 11;
            6'h0c: G = 12;
            6'h0d: G = 13;
            6'h0e: G = 14;
            6'h0f: G = 15;
            6'h10: G = 1;
            6'h11: G = 6;
            6'h12: G = 11;
            6'h13: G = 0;
            6'h14: G = 5;
            6'h15: G = 10;
            6'h16: G = 15;
            6'h17: G = 4;
            6'h18: G = 9;
            6'h19: G = 14;
            6'h1a: G = 3;
            6'h1b: G = 8;
            6'h1c: G = 13;
            6'h1d: G = 2;
            6'h1e: G = 7;
            6'h1f: G = 12;
            6'h20: G = 5;
            6'h21: G = 8;
            6'h22: G = 11;
            6'h23: G = 14;
            6'h24: G = 1;
            6'h25: G = 4;
            6'h26: G = 7;
            6'h27: G = 10;
            6'h28: G = 13;
            6'h29: G = 0;
            6'h2a: G = 3;
            6'h2b: G = 6;
            6'h2c: G = 9;
            6'h2d: G = 12;
            6'h2e: G = 15;
            6'h2f: G = 2;
            6'h30: G = 0;
            6'h31: G = 7;
            6'h32: G = 14;
            6'h33: G = 5;
            6'h34: G = 12;
            6'h35: G = 3;
            6'h36: G = 10;
            6'h37: G = 1;
            6'h38: G = 8;
            6'h39: G = 15;
            6'h3a: G = 6;
            6'h3b: G = 13;
            6'h3c: G = 4;
            6'h3d: G = 11;
            6'h3e: G = 2;
            6'h3f: G = 9;
        endcase
    end
endfunction

//---------------------------
// little edian 32-bit
function [31:0] byteflip(
    input [31:0] w
);
    begin
        byteflip = {w[7:0], w[15:8], w[23:16], w[31:24]};
    end
endfunction

//---------------------------------------------------------
// Concurrent connectivity for ports etc.
//---------------------------------------------------------
assign ready = ready_reg;

assign digest = {byteflip(h0_reg), byteflip(h1_reg),
                 byteflip(h2_reg), byteflip(h3_reg)};

//---------------------------------------------------------
// reg_update
//
// Update functionality for all registers in the core.
// All registers are positive edge triggered with asynchronous
// active low reset.
//---------------------------------------------------------
always @(posedge clk or negedge reset_n) begin: reg_update
    integer i;

    if (!reset_n) begin
        for (i = 0; i < 16; i = i + 1) 
            block_reg[i] <= 32'h0;
        
        h0_reg <= 32'h0;
        h1_reg <= 32'h0;
        h2_reg <= 32'h0;
        h3_reg <= 32'h0;
        a_reg <= 32'h0;
        b_reg <= 32'h0;
        c_reg <= 32'h0;
        d_reg <= 32'h0;
        pipe_b_reg <= 32'h0;
        ready_reg <= 1'h1;
        round_ctr_reg <= 7'h0;
        MD5_core_ctrl_reg <= CTRL_IDLE;
    end
    else begin
        pipe_b_reg <= pipe_b_new;

        if (ready_we)
            ready_reg <= ready_new;
        
        if (block_we) begin
            block_reg[00] <= block[511:480];
            block_reg[01] <= block[479:448];
            block_reg[02] <= block[447:416];
            block_reg[03] <= block[415:384];
            block_reg[04] <= block[383:352];
            block_reg[05] <= block[351:320];
            block_reg[06] <= block[319:288];
            block_reg[07] <= block[287:256];
            block_reg[08] <= block[255:224];
            block_reg[09] <= block[223:192];
            block_reg[10] <= block[191:160];
            block_reg[11] <= block[159:128];
            block_reg[12] <= block[127:096];
            block_reg[13] <= block[095:064];
            block_reg[14] <= block[063:032];
            block_reg[15] <= block[031:000];
        end

        if (h_we) begin
            h0_reg <= h0_new;
            h1_reg <= h1_new;
            h2_reg <= h2_new;
            h3_reg <= h3_new;
        end
        
        if (a_d_we) begin
            a_reg <= a_new;
            b_reg <= b_new;
            c_reg <= c_new;
            d_reg <= d_new;
        end

        if (round_ctr_we)
            round_ctr_reg <= round_ctr_new;

        if (MD5_core_ctrl_we)
            MD5_core_ctrl_reg <= MD5_core_ctrl_new;
    end
end

//---------------------------------------------------------
// MD5_dp
//---------------------------------------------------------
always @(*) begin: MD5_dp
    reg [31:0] f;
    reg [31:0] k;
    reg [3:0] g;
    reg [31:0] w;
    reg [31:0] tmp_b0;
    reg [31:0] lr;
    reg [31:0] tmp_b2;

    h0_new = 32'h0;
    h1_new = 32'h0;
    h2_new = 32'h0;
    h3_new = 32'h0;
    h_we = 1'h0;

    a_new = 32'h0;
    b_new = 32'h0;
    c_new = 32'h0;
    d_new = 32'h0;
    a_d_we = 1'h0;

    f = F(b_reg, c_reg, d_reg, round_ctr_reg[5:0]);
    g = G(round_ctr_reg[5:0]);
    w = block_reg[g];
    k = K(round_ctr_reg[5:0]);

    tmp_b0 = a_reg + f + w + k;
    pipe_b_new = tmp_b0;

    lr = rotate(pipe_b_reg, round_ctr_reg[5:0]);
    tmp_b2 = lr + b_reg;

    if (init_state) begin
        h0_new = A0;
        h1_new = B0;
        h2_new = C0;
        h3_new = D0;
        h_we = 1'h1;
    end

    if (update_state) begin
        h0_new = h0_reg + a_reg;
        h1_new = h1_reg + b_reg;
        h2_new = h2_reg + c_reg;
        h3_new = h3_reg + d_reg;
        h_we = 1'h1;
    end

    if (init_round) begin
        a_new = h0_reg;
        b_new = h1_reg;
        c_new = h2_reg;
        d_new = h3_reg;
        a_d_we = 1'h1;
    end

    if (update_round) begin
        a_new = d_reg;
        b_new = tmp_b2;
        c_new = b_reg;
        d_new = c_reg;
        a_d_we = 1'h1;
    end
end

//---------------------------------------------------------
// round_ctr
//---------------------------------------------------------
always @(*) begin: round_ctr
    round_ctr_new = 7'h0;
    round_ctr_we = 1'h0;

    if (round_ctr_rst) begin
        round_ctr_new = 7'h0;
        round_ctr_we = 1'h1;
    end

    if (round_ctr_inc) begin
        round_ctr_new = round_ctr_reg + 1'h1;
        round_ctr_we = 1'h1;
    end
end

//---------------------------------------------------------
// MD5_core_ctrl
//---------------------------------------------------------
always @(*) begin: MD5_core_ctrl
    ready_new = 1'h0;
    ready_we = 1'h0;
    block_we = 1'h0;
    round_ctr_inc = 1'h0;
    round_ctr_rst = 1'h0;
    init_state = 1'h0;
    update_state = 1'h0;
    init_round = 1'h0;
    update_round = 1'h0;
    MD5_core_ctrl_new = CTRL_IDLE;
    MD5_core_ctrl_we = 1'h0;

    case (MD5_core_ctrl_reg) 
        CTRL_IDLE: begin
            if (init) begin
                init_state = 1'h1;
            end

            if (next) begin
                init_round = 1'h1;
                block_we = 1'h1;
                round_ctr_rst = 1'h1;
                ready_new = 1'h0;
                ready_we = 1'h1;
                MD5_core_ctrl_new = CTRL_PIPE;
                MD5_core_ctrl_we = 1'h1;
            end
        end

        CTRL_PIPE: begin
            MD5_core_ctrl_new = CTRL_LOOP;
            MD5_core_ctrl_we = 1'h1;
        end

        CTRL_LOOP: begin
            if (round_ctr_reg < 64) begin
                update_round = 1'h1;
                round_ctr_inc = 1'h1;
                MD5_core_ctrl_new = CTRL_PIPE;
                MD5_core_ctrl_we = 1'h1;
            end
            else begin
                update_state = 1'h1;
                ready_new = 1'h1;
                ready_we = 1'h1;
                MD5_core_ctrl_new = CTRL_IDLE;
                MD5_core_ctrl_we = 1'h1;
            end
        end
        
        default: begin
        end
    endcase
end

//---------------------------------------------------------
endmodule

//======================================================================
// EOF MD5_core.v
//======================================================================