`timescale 1 ns / 1 ps

module testbench;
    //=========================================================================
    // Clock & Reset
    //=========================================================================
    reg clk = 1;
    always #5 clk = ~clk;  // 100 MHz

    reg resetn = 0;
    initial begin
        #100;
        resetn <= 1;
    end

    //=========================================================================
    // Trap Detection
    //=========================================================================
    wire trap;
    always @(posedge clk) begin
        if (resetn && trap) begin
            $display("TRAP detected at time %0t", $time);
            #200;
            $finish;
        end
    end

    //=========================================================================
    // Timeout
    //=========================================================================
    initial begin
        #5000;
        $display("TIMEOUT - simulation ended");
        $finish;
    end

    //=========================================================================
    // Memory (4KB)
    //=========================================================================
    localparam MEM_SIZE = 4096;
    reg [31:0] memory [0:MEM_SIZE/4-1];

    initial begin
        $readmemh("firmware/firmware.hex", memory);
    end

    //=========================================================================
    // PicoRV32 Core Instantiation (AXI interface)
    //=========================================================================
    wire        mem_axi_awvalid;
    wire        mem_axi_awready;
    wire [31:0] mem_axi_awaddr;
    wire [2:0]  mem_axi_awprot;

    wire        mem_axi_wvalid;
    wire        mem_axi_wready;
    wire [31:0] mem_axi_wdata;
    wire [3:0]  mem_axi_wstrb;

    wire        mem_axi_bvalid;
    wire        mem_axi_bready;

    wire        mem_axi_arvalid;
    wire        mem_axi_arready;
    wire [31:0] mem_axi_araddr;
    wire [2:0]  mem_axi_arprot;

    wire        mem_axi_rvalid;
    wire        mem_axi_rready;
    wire [31:0] mem_axi_rdata;

    picorv32_axi #(
        .ENABLE_COUNTERS     (1),
        .ENABLE_COUNTERS64   (1),
        .ENABLE_REGS_16_31   (1),
        .ENABLE_REGS_DUALPORT(1),
        .TWO_STAGE_SHIFT     (1),
        .BARREL_SHIFTER      (1),
        .TWO_CYCLE_COMPARE   (0),
        .TWO_CYCLE_ALU       (0),
        .COMPRESSED_ISA      (0),
        .CATCH_MISALIGN      (1),
        .CATCH_ILLINSN       (1),
        .ENABLE_MUL          (1),
        .ENABLE_DIV          (1),
        .ENABLE_IRQ          (0),
        .ENABLE_TRACE        (0),
        .REGS_INIT_ZERO      (1),
        .PROGADDR_RESET      (32'h0000_0000),
        .STACKADDR           (32'h0000_0FFC)
    ) uut (
        .clk             (clk),
        .resetn          (resetn),
        .trap            (trap),
        .mem_axi_awvalid (mem_axi_awvalid),
        .mem_axi_awready (mem_axi_awready),
        .mem_axi_awaddr  (mem_axi_awaddr),
        .mem_axi_awprot  (mem_axi_awprot),
        .mem_axi_wvalid  (mem_axi_wvalid),
        .mem_axi_wready  (mem_axi_wready),
        .mem_axi_wdata   (mem_axi_wdata),
        .mem_axi_wstrb   (mem_axi_wstrb),
        .mem_axi_bvalid  (mem_axi_bvalid),
        .mem_axi_bready  (mem_axi_bready),
        .mem_axi_arvalid (mem_axi_arvalid),
        .mem_axi_arready (mem_axi_arready),
        .mem_axi_araddr  (mem_axi_araddr),
        .mem_axi_arprot  (mem_axi_arprot),
        .mem_axi_rvalid  (mem_axi_rvalid),
        .mem_axi_rready  (mem_axi_rready),
        .mem_axi_rdata   (mem_axi_rdata),
        .pcpi_wr         (1'b0),
        .pcpi_rd         (32'b0),
        .pcpi_wait       (1'b0),
        .pcpi_ready      (1'b0),
        .irq             (32'b0)
    );

    //=========================================================================
    // AXI Memory Slave
    //=========================================================================
    reg mem_axi_arready_r = 0;
    reg mem_axi_awready_r = 0;
    reg mem_axi_wready_r  = 0;
    reg mem_axi_rvalid_r  = 0;
    reg mem_axi_bvalid_r  = 0;
    reg [31:0] mem_axi_rdata_r;

    assign mem_axi_arready = mem_axi_arready_r;
    assign mem_axi_awready = mem_axi_awready_r;
    assign mem_axi_wready  = mem_axi_wready_r;
    assign mem_axi_rvalid  = mem_axi_rvalid_r;
    assign mem_axi_bvalid  = mem_axi_bvalid_r;
    assign mem_axi_rdata   = mem_axi_rdata_r;

    // Pending write state
    reg aw_pending = 0, w_pending = 0;
    reg [31:0] aw_addr;
    reg [31:0] w_data;
    reg [3:0]  w_strb;

    wire [31:0] word_addr_r = mem_axi_araddr >> 2;

    always @(posedge clk) begin
        mem_axi_arready_r <= 0;
        mem_axi_rvalid_r  <= 0;
        mem_axi_awready_r <= 0;
        mem_axi_wready_r  <= 0;
        mem_axi_bvalid_r  <= 0;

        // --- Read channel ---
        if (mem_axi_arvalid && !mem_axi_rvalid_r) begin
            mem_axi_arready_r <= 1;
            mem_axi_rvalid_r  <= 1;
            if (word_addr_r < MEM_SIZE/4)
                mem_axi_rdata_r <= memory[word_addr_r];
            else
                mem_axi_rdata_r <= 32'h0;
        end

        // --- Write address channel ---
        if (mem_axi_awvalid && !aw_pending) begin
            mem_axi_awready_r <= 1;
            aw_pending <= 1;
            aw_addr <= mem_axi_awaddr;
        end

        // --- Write data channel ---
        if (mem_axi_wvalid && !w_pending) begin
            mem_axi_wready_r <= 1;
            w_pending <= 1;
            w_data <= mem_axi_wdata;
            w_strb <= mem_axi_wstrb;
        end

        // --- Commit write ---
        if (aw_pending && w_pending) begin
            if ((aw_addr >> 2) < MEM_SIZE/4) begin
                if (w_strb[0]) memory[aw_addr >> 2][ 7: 0] <= w_data[ 7: 0];
                if (w_strb[1]) memory[aw_addr >> 2][15: 8] <= w_data[15: 8];
                if (w_strb[2]) memory[aw_addr >> 2][23:16] <= w_data[23:16];
                if (w_strb[3]) memory[aw_addr >> 2][31:24] <= w_data[31:24];
            end
            // Console output at address 0x1000_0000
            if (aw_addr == 32'h1000_0000) begin
                $write("%c", w_data[7:0]);
            end
            aw_pending <= 0;
            w_pending  <= 0;
            mem_axi_bvalid_r <= 1;
        end

        if (!resetn) begin
            aw_pending <= 0;
            w_pending  <= 0;
        end
    end

    //=========================================================================
    // CPU Register Monitoring (for waveform visibility)
    //=========================================================================
    wire [31:0] reg_pc  = uut.picorv32_core.reg_pc;
    wire [7:0]  cpu_st  = uut.picorv32_core.cpu_state;

    // Access register file - x1..x12
    wire [31:0] x1  = uut.picorv32_core.cpuregs[1];
    wire [31:0] x2  = uut.picorv32_core.cpuregs[2];
    wire [31:0] x3  = uut.picorv32_core.cpuregs[3];
    wire [31:0] x4  = uut.picorv32_core.cpuregs[4];
    wire [31:0] x5  = uut.picorv32_core.cpuregs[5];
    wire [31:0] x6  = uut.picorv32_core.cpuregs[6];
    wire [31:0] x7  = uut.picorv32_core.cpuregs[7];
    wire [31:0] x8  = uut.picorv32_core.cpuregs[8];
    wire [31:0] x9  = uut.picorv32_core.cpuregs[9];
    wire [31:0] x10 = uut.picorv32_core.cpuregs[10];
    wire [31:0] x11 = uut.picorv32_core.cpuregs[11];
    wire [31:0] x12 = uut.picorv32_core.cpuregs[12];
    wire [31:0] x13 = uut.picorv32_core.cpuregs[13];
    wire [31:0] x14 = uut.picorv32_core.cpuregs[14];
    wire [31:0] x15 = uut.picorv32_core.cpuregs[15];

    // ALU internal signals
    wire [31:0] alu_out_w    = uut.picorv32_core.alu_out;
    wire [31:0] alu_add_sub_w = uut.picorv32_core.alu_add_sub;
    wire [31:0] reg_op1_w    = uut.picorv32_core.reg_op1;
    wire [31:0] reg_op2_w    = uut.picorv32_core.reg_op2;

    // Instruction decode flags
    wire instr_add_w  = uut.picorv32_core.instr_add;
    wire instr_sub_w  = uut.picorv32_core.instr_sub;
    wire instr_sll_w  = uut.picorv32_core.instr_sll;
    wire instr_srl_w  = uut.picorv32_core.instr_srl;
    wire instr_sra_w  = uut.picorv32_core.instr_sra;
    wire instr_or_w   = uut.picorv32_core.instr_or;
    wire instr_and_w  = uut.picorv32_core.instr_and;
    wire instr_xor_w  = uut.picorv32_core.instr_xor;
    wire instr_slt_w  = uut.picorv32_core.instr_slt;
    wire instr_addi_w = uut.picorv32_core.instr_addi;
    wire instr_slli_w = uut.picorv32_core.instr_slli;
    wire instr_srli_w = uut.picorv32_core.instr_srli;
    wire instr_srai_w = uut.picorv32_core.instr_srai;

    //=========================================================================
    // Display ALU Results
    //=========================================================================
    always @(posedge clk) begin
        if (resetn && uut.picorv32_core.cpuregs_write && uut.picorv32_core.latched_rd != 0) begin
            $display("[%0t ns] x%-2d = 0x%08h (%0d)",
                $time,
                uut.picorv32_core.latched_rd,
                uut.picorv32_core.cpuregs_wrdata,
                uut.picorv32_core.cpuregs_wrdata);
        end
    end

endmodule
