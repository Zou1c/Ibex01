// ============================================================================
// soc_bus.sv — 简单总线解码器
//
// 根据地址高位把 Ibex 的数据访问路由到不同外设:
//   地址 0x0000_0000 ~ 0x0FFF_FFFF → BRAM 存储器
//   地址 0x1000_0000 ~ 0x1FFF_FFFF → GPIO 外设
//
// 协议: Ibex 的 req/gnt/rvalid 存储器接口
// ============================================================================

module soc_bus (
    input  logic        clk_i,
    input  logic        rst_ni,

    // 来自 Ibex CPU 数据端口
    input  logic        cpu_req_i,
    input  logic [31:0] cpu_addr_i,
    output logic        cpu_gnt_o,
    output logic        cpu_rvalid_o,
    output logic [31:0] cpu_rdata_o,

    // 到 BRAM 存储器
    output logic        mem_req_o,
    input  logic        mem_gnt_i,
    input  logic        mem_rvalid_i,
    input  logic [31:0] mem_rdata_i,

    // 到 GPIO 外设
    output logic        gpio_req_o,
    input  logic        gpio_gnt_i,
    input  logic        gpio_rvalid_i,
    input  logic [31:0] gpio_rdata_i
);

    // ==============================
    // 地址解码
    // ==============================
    // 用地址的 bit[28] 来区分:
    //   0x0xxx_xxxx → BRAM  (bit[28] = 0)
    //   0x1xxx_xxxx → GPIO  (bit[28] = 1)

    wire sel_mem  = cpu_req_i && !cpu_addr_i[28];
    wire sel_gpio = cpu_req_i &&  cpu_addr_i[28];

    // 路由请求
    assign mem_req_o  = sel_mem;
    assign gpio_req_o = sel_gpio;

    // Grant: 选中谁就用谁的 gnt
    assign cpu_gnt_o = sel_mem  ? mem_gnt_i  :
                       sel_gpio ? gpio_gnt_i :
                       cpu_req_i;  // 无效地址也 grant (避免死锁)

    // ==============================
    // 记住上一周期选择了谁 (用于路由 rvalid 和 rdata)
    // ==============================
    logic sel_mem_q, sel_gpio_q;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            sel_mem_q  <= 1'b0;
            sel_gpio_q <= 1'b0;
        end else begin
            if (cpu_req_i) begin
                sel_mem_q  <= sel_mem;
                sel_gpio_q <= sel_gpio;
            end
        end
    end

    // 路由返回数据
    assign cpu_rvalid_o = sel_mem_q  ? mem_rvalid_i  :
                          sel_gpio_q ? gpio_rvalid_i :
                          1'b0;

    assign cpu_rdata_o  = sel_mem_q  ? mem_rdata_i  :
                          sel_gpio_q ? gpio_rdata_i :
                          32'hDEAD_BEEF;  // 无效地址返回标记值

endmodule
