// ============================================================================
// simple_gpio.sv — 最简 GPIO 外设
//
// 寄存器映射 (基地址 0x1000_0000):
//   偏移 0x00: GPIO 输出寄存器 (读写，直接驱动 LED)
//   偏移 0x04: GPIO 输入寄存器 (只读，读取按键等外部输入)
//
// 协议: Ibex 的 req/gnt/rvalid 存储器接口
// ============================================================================

module simple_gpio (
    input  logic        clk_i,
    input  logic        rst_ni,

    // 存储器接口
    input  logic        req_i,
    input  logic [ 7:0] addr_i,     // 低8位地址 (偏移量)
    input  logic [31:0] wdata_i,
    input  logic        we_i,
    input  logic [ 3:0] be_i,
    output logic        gnt_o,
    output logic        rvalid_o,
    output logic [31:0] rdata_o,

    // GPIO 引脚
    output logic [31:0] gpio_o,     // 输出 (连 LED)
    input  logic [31:0] gpio_i      // 输入 (连按键)
);

    // ==============================
    // 寄存器
    // ==============================
    logic [31:0] gpio_out_reg;

    // Grant: 同周期应答
    assign gnt_o = req_i;

    // 读数据和 rvalid: 下一周期返回
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            rvalid_o    <= 1'b0;
            rdata_o     <= 32'h0;
            gpio_out_reg <= 32'h0;
        end else begin
            rvalid_o <= req_i;

            if (req_i) begin
                if (we_i) begin
                    // 写操作
                    case (addr_i[3:2])
                        2'b00: begin  // 偏移 0x00: GPIO 输出
                            if (be_i[0]) gpio_out_reg[ 7: 0] <= wdata_i[ 7: 0];
                            if (be_i[1]) gpio_out_reg[15: 8] <= wdata_i[15: 8];
                            if (be_i[2]) gpio_out_reg[23:16] <= wdata_i[23:16];
                            if (be_i[3]) gpio_out_reg[31:24] <= wdata_i[31:24];
                        end
                        // 偏移 0x04 (GPIO 输入) 是只读的，写入忽略
                        default: ;
                    endcase
                end

                // 读操作 (读和写可以同时进行，读返回写入前的值)
                case (addr_i[3:2])
                    2'b00:   rdata_o <= gpio_out_reg;   // 读回输出寄存器当前值
                    2'b01:   rdata_o <= gpio_i;         // 读取外部输入
                    default: rdata_o <= 32'h0;
                endcase
            end
        end
    end

    // 输出连接
    assign gpio_o = gpio_out_reg;

endmodule
