// ============================================================================
// ibex_soc_top.sv - v6
//
// KEY FIX: Use PL-side 50MHz oscillator (Y14) instead of PS FCLK_CLK0
// Reason: Programming PL via JTAG does NOT initialize PS, so FCLK is dead
//
// LED[3] = hardware heartbeat (1Hz)
// LED[2:0] = Ibex CPU GPIO
// ============================================================================

module ibex_soc_top (
    // Zynq PS DDR (keep connected so PS pins aren't floating)
    inout  [14:0] DDR_addr,
    inout  [ 2:0] DDR_ba,
    inout         DDR_cas_n,
    inout         DDR_ck_n,
    inout         DDR_ck_p,
    inout         DDR_cke,
    inout         DDR_cs_n,
    inout  [ 3:0] DDR_dm,
    inout  [31:0] DDR_dq,
    inout  [ 3:0] DDR_dqs_n,
    inout  [ 3:0] DDR_dqs_p,
    inout         DDR_odt,
    inout         DDR_ras_n,
    inout         DDR_reset_n,
    inout         DDR_we_n,
    inout         FIXED_IO_ddr_vrn,
    inout         FIXED_IO_ddr_vrp,
    inout  [53:0] FIXED_IO_mio,
    inout         FIXED_IO_ps_clk,
    inout         FIXED_IO_ps_porb,
    inout         FIXED_IO_ps_srstb,

    // PL clock input (50MHz oscillator on core board, active clock!)
    input         pl_clk,

    // LEDs
    output [3:0]  led
);

    // ========================================================================
    // Use PL oscillator as system clock (always running, no PS needed)
    // ========================================================================
    wire clk = pl_clk;

    // ========================================================================
    // Power-on reset (no dependency on PS reset)
    // Hold reset for ~1ms after FPGA config (50000 cycles @ 50MHz)
    // ========================================================================
    reg [15:0] por_cnt = 16'd0;
    reg        por_done = 1'b0;
    wire       rst_n = por_done;

    always @(posedge clk) begin
        if (!por_done) begin
            if (por_cnt == 16'hFFFF)
                por_done <= 1'b1;
            else
                por_cnt <= por_cnt + 1'b1;
        end
    end

    // ========================================================================
    // Heartbeat: LED[3] blinks 1Hz (purely hardware, proves clock works)
    // ========================================================================
    reg [25:0] hb_cnt;
    reg        hb_led;
    always @(posedge clk) begin
        if (!rst_n) begin
            hb_cnt <= 0;
            hb_led <= 1'b1;  // OFF (active low)
        end else if (hb_cnt == 26'd24_999_999) begin
            hb_cnt <= 0;
            hb_led <= ~hb_led;
        end else begin
            hb_cnt <= hb_cnt + 1;
        end
    end

    // ========================================================================
    // Zynq PS - keep instantiated so DDR/MIO pins don't float
    // We ignore its clock and reset outputs
    // ========================================================================
    wire ps_fclk_unused;
    wire ps_reset_unused;
    wire uart_txd_unused;

    zynq_ps_bd_wrapper u_zynq_ps (
        .DDR_addr(DDR_addr), .DDR_ba(DDR_ba), .DDR_cas_n(DDR_cas_n),
        .DDR_ck_n(DDR_ck_n), .DDR_ck_p(DDR_ck_p), .DDR_cke(DDR_cke),
        .DDR_cs_n(DDR_cs_n), .DDR_dm(DDR_dm), .DDR_dq(DDR_dq),
        .DDR_dqs_n(DDR_dqs_n), .DDR_dqs_p(DDR_dqs_p), .DDR_odt(DDR_odt),
        .DDR_ras_n(DDR_ras_n), .DDR_reset_n(DDR_reset_n), .DDR_we_n(DDR_we_n),
        .FIXED_IO_ddr_vrn(FIXED_IO_ddr_vrn), .FIXED_IO_ddr_vrp(FIXED_IO_ddr_vrp),
        .FIXED_IO_mio(FIXED_IO_mio), .FIXED_IO_ps_clk(FIXED_IO_ps_clk),
        .FIXED_IO_ps_porb(FIXED_IO_ps_porb), .FIXED_IO_ps_srstb(FIXED_IO_ps_srstb),
        .FCLK_CLK0_0(ps_fclk_unused), .FCLK_RESET0_N_0(ps_reset_unused),
        .UART_0_0_rxd(1'b1), .UART_0_0_txd(uart_txd_unused)
    );

    // ========================================================================
    // Ibex CPU
    // ========================================================================
    wire        instr_req, instr_gnt, instr_rvalid;
    wire [31:0] instr_addr, instr_rdata;
    wire        data_req, data_gnt, data_rvalid, data_we;
    wire [ 3:0] data_be;
    wire [31:0] data_addr, data_wdata, data_rdata;
    wire        mem_data_req, mem_data_gnt, mem_data_rvalid;
    wire [31:0] mem_data_rdata;
    wire        gpio_req, gpio_gnt, gpio_rvalid;
    wire [31:0] gpio_rdata, gpio_out;

    ibex_top #(
        .PMPEnable(0), .PMPGranularity(0), .PMPNumRegions(4),
        .MHPMCounterNum(0), .MHPMCounterWidth(40),
        .RV32E(0), .RV32M(ibex_pkg::RV32MFast), .RV32B(ibex_pkg::RV32BNone),
        .WritebackStage(0), .ICache(0), .ICacheECC(0),
        .DbgTriggerEn(0), .SecureIbex(0),
        .DmHaltAddr(32'h00000000), .DmExceptionAddr(32'h00000000)
    ) u_ibex (
        .clk_i(clk), .rst_ni(rst_n),
        .test_en_i(1'b0), .scan_rst_ni(1'b1),
        .instr_req_o(instr_req), .instr_gnt_i(instr_gnt),
        .instr_rvalid_i(instr_rvalid), .instr_addr_o(instr_addr),
        .instr_rdata_i(instr_rdata), .instr_rdata_intg_i(7'h0), .instr_err_i(1'b0),
        .data_req_o(data_req), .data_gnt_i(data_gnt),
        .data_rvalid_i(data_rvalid), .data_we_o(data_we),
        .data_be_o(data_be), .data_addr_o(data_addr),
        .data_wdata_o(data_wdata), .data_rdata_i(data_rdata),
        .data_rdata_intg_i(7'h0), .data_err_i(1'b0),
        .irq_software_i(1'b0), .irq_timer_i(1'b0), .irq_external_i(1'b0),
        .irq_fast_i(15'b0), .irq_nm_i(1'b0),
        .debug_req_i(1'b0), .crash_dump_o(), .double_fault_seen_o(),
        .fetch_enable_i(ibex_pkg::IbexMuBiOn),
        .alert_minor_o(), .alert_major_internal_o(),
        .alert_major_bus_o(), .core_sleep_o()
    );

    // ========================================================================
    // BRAM
    // ========================================================================
    bram_mem #(
        .ADDR_WIDTH(14),
        .MEM_FILE("E:/vivadoprojects/ibex_soc/firmware.hex")
    ) u_bram (
        .clk_i(clk),
        .a_req_i(instr_req), .a_addr_i(instr_addr), .a_wdata_i(32'h0),
        .a_we_i(1'b0), .a_be_i(4'hF),
        .a_gnt_o(instr_gnt), .a_rvalid_o(instr_rvalid), .a_rdata_o(instr_rdata),
        .b_req_i(mem_data_req), .b_addr_i(data_addr), .b_wdata_i(data_wdata),
        .b_we_i(data_we), .b_be_i(data_be),
        .b_gnt_o(mem_data_gnt), .b_rvalid_o(mem_data_rvalid), .b_rdata_o(mem_data_rdata)
    );

    // ========================================================================
    // Bus + GPIO
    // ========================================================================
    soc_bus u_bus (
        .clk_i(clk), .rst_ni(rst_n),
        .cpu_req_i(data_req), .cpu_addr_i(data_addr),
        .cpu_gnt_o(data_gnt), .cpu_rvalid_o(data_rvalid), .cpu_rdata_o(data_rdata),
        .mem_req_o(mem_data_req), .mem_gnt_i(mem_data_gnt),
        .mem_rvalid_i(mem_data_rvalid), .mem_rdata_i(mem_data_rdata),
        .gpio_req_o(gpio_req), .gpio_gnt_i(gpio_gnt),
        .gpio_rvalid_i(gpio_rvalid), .gpio_rdata_i(gpio_rdata)
    );

    simple_gpio u_gpio (
        .clk_i(clk), .rst_ni(rst_n),
        .req_i(gpio_req), .addr_i(data_addr[7:0]),
        .wdata_i(data_wdata), .we_i(data_we), .be_i(data_be),
        .gnt_o(gpio_gnt), .rvalid_o(gpio_rvalid), .rdata_o(gpio_rdata),
        .gpio_o(gpio_out), .gpio_i(32'h0)
    );

    // ========================================================================
    // LED output
    // ========================================================================
    assign led[2:0] = gpio_out[2:0];
    assign led[3]   = hb_led;

endmodule
