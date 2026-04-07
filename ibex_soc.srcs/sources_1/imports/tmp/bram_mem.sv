// ============================================================================
// bram_mem.sv - Dual-port BRAM with hardcoded firmware
// Values taken directly from firmware.hex (56 words)
// ============================================================================

module bram_mem #(
    parameter ADDR_WIDTH = 14,
    parameter MEM_FILE   = ""
) (
    input  logic        clk_i,

    input  logic        a_req_i,
    input  logic [31:0] a_addr_i,
    input  logic [31:0] a_wdata_i,
    input  logic        a_we_i,
    input  logic [ 3:0] a_be_i,
    output logic        a_gnt_o,
    output logic        a_rvalid_o,
    output logic [31:0] a_rdata_o,

    input  logic        b_req_i,
    input  logic [31:0] b_addr_i,
    input  logic [31:0] b_wdata_i,
    input  logic        b_we_i,
    input  logic [ 3:0] b_be_i,
    output logic        b_gnt_o,
    output logic        b_rvalid_o,
    output logic [31:0] b_rdata_o
);

    localparam WORD_ADDR_WIDTH = ADDR_WIDTH - 2;
    localparam MEM_DEPTH       = 2 ** WORD_ADDR_WIDTH;

    (* ram_style = "block" *) reg [31:0] mem [0:MEM_DEPTH-1];

    logic [WORD_ADDR_WIDTH-1:0] addr_a, addr_b;
    assign addr_a = a_addr_i[ADDR_WIDTH-1:2];
    assign addr_b = b_addr_i[ADDR_WIDTH-1:2];

    assign a_gnt_o = a_req_i;
    assign b_gnt_o = b_req_i;

    // Port A: instruction read
    always_ff @(posedge clk_i) begin
        a_rvalid_o <= a_req_i;
        if (a_req_i) begin
            a_rdata_o <= mem[addr_a];
        end
    end

    // Port B: data read/write with byte enables
    always_ff @(posedge clk_i) begin
        b_rvalid_o <= b_req_i;
        if (b_req_i) begin
            if (b_we_i) begin
                if (b_be_i[0]) mem[addr_b][ 7: 0] <= b_wdata_i[ 7: 0];
                if (b_be_i[1]) mem[addr_b][15: 8] <= b_wdata_i[15: 8];
                if (b_be_i[2]) mem[addr_b][23:16] <= b_wdata_i[23:16];
                if (b_be_i[3]) mem[addr_b][31:24] <= b_wdata_i[31:24];
            end
            b_rdata_o <= mem[addr_b];
        end
    end

    // ========================================================================
    // Firmware initialization - exact values from firmware.hex
    // ========================================================================
    integer init_i;
    initial begin
        // Clear entire memory
        for (init_i = 0; init_i < MEM_DEPTH; init_i = init_i + 1) begin
            mem[init_i] = 32'h00000000;
        end

        // Address 0x00: jump to _start at 0x80
        mem[  0] = 32'h0000A041;
        // mem[1] through mem[31] are already zero (padding to 0x80)

        // Address 0x80: _start
        mem[ 32] = 32'h00004137;  // lui   sp, 0x4
        mem[ 33] = 32'h00000297;  // auipc t0, 0x0
        mem[ 34] = 32'h04C28293;  // addi  t0, t0, 76
        mem[ 35] = 32'h30529073;  // csrw  mtvec, t0
        mem[ 36] = 32'h10000537;  // lui   a0, 0x10000
        mem[ 37] = 32'hC10C45B9;  // li a1,14; sw a1,0(a0)
        mem[ 38] = 32'h002DC637;  // lui   a2, 0x2DC
        mem[ 39] = 32'h6C060613;  // addi  a2, a2, 0x6C0

        // Address 0xA0: delay_loop
        mem[ 40] = 32'hFE7D167D;  // addi a2,-1; bnez a2,delay

        // Address 0xA4: shift + jump to rotate
        mem[ 41] = 32'h00159693;  // slli  a3, a1, 1
        mem[ 42] = 32'hE6938ABD;  // andi + ori (compressed)
        mem[ 43] = 32'hA0090016;  // ori + j rotate (compressed)

        // Address 0xB0: rotate
        mem[ 44] = 32'h00F5C713;  // xori  a4, a1, 15
        mem[ 45] = 32'h8B3D0706;  // slli + andi (compressed)
        mem[ 46] = 32'h4593C701;  // beqz + xori_lo (compressed)
        mem[ 47] = 32'hBFE100F7;  // xori_hi + j main_loop

        // Address 0xC0: wrap
        mem[ 48] = 32'hBFD145B9;  // li a1,14; j main_loop

        // Address 0xC4: padding
        mem[ 49] = 32'h00000013;  // nop
        mem[ 50] = 32'h00000013;  // nop
        mem[ 51] = 32'h00000013;  // nop

        // Address 0xD0: _trap_handler
        mem[ 52] = 32'h30200073;  // mret
        mem[ 53] = 32'h00130001;
        mem[ 54] = 32'h00130000;
        mem[ 55] = 32'h00000000;
    end

endmodule
