`include "io_def.vh"

module mig_example_top(
    input CLK100MHZ,
    input CPU_RESETN,
    
    output[15:0] LED,

    //RAM Interface
    inout [15:0] ddr2_dq,
    inout[1:0] ddr2_dqs_n,
    inout[1:0] ddr2_dqs_p,
    output[12:0] ddr2_addr,
    output[2:0] ddr2_ba,
    output ddr2_ras_n,
    output ddr2_cas_n,
    output ddr2_we_n,
    output ddr2_ck_p,
    output ddr2_ck_n,
    output ddr2_cke,
    output ddr2_cs_n,
    output[1:0] ddr2_dm,
    output ddr2_odt
    );

    //////////  Clock Generation  //////////
    wire clk_cpu, clk_mem;
    wire pll_locked;

    pll pll1(
        .locked(pll_locked),
        .clk_in(CLK100MHZ),
        .clk_mem(clk_mem), //200MHz Memory Reference Clock
        .clk_cpu(clk_cpu)  //Clock used for traffic generator
        );

    //////////  Reset Sync/Stretch  //////////
    reg[31:0] rst_stretch = 32'hFFFFFFFF;
    wire reset_req_n, rst_n;

    assign reset_req_n = CPU_RESETN & pll_locked;

    always @(posedge clk_cpu) rst_stretch = {reset_req_n,rst_stretch[31:1]};
    assign rst_n = reset_req_n & &rst_stretch;

    //////////  DUT  //////////
    wire[63:0] mem_d_from_ram;
    wire mem_transaction_complete;
    wire mem_ready;
    
    reg[27:0] mem_addr;
    reg[63:0] mem_d_to_ram;
    reg[1:0] mem_transaction_width;
    reg mem_wstrobe, mem_rstrobe;
    
    mem_example mem_ex(
        .clk_mem(clk_mem),
        .rst_n(rst_n),

        .ddr2_addr(ddr2_addr),
        .ddr2_ba(ddr2_ba),
        .ddr2_cas_n(ddr2_cas_n),
        .ddr2_ck_n(ddr2_ck_n),
        .ddr2_ck_p(ddr2_ck_p),
        .ddr2_cke(ddr2_cke),
        .ddr2_ras_n(ddr2_ras_n),
        .ddr2_we_n(ddr2_we_n),
        .ddr2_dq(ddr2_dq),
        .ddr2_dqs_n(ddr2_dqs_n),
        .ddr2_dqs_p(ddr2_dqs_p),
        .ddr2_cs_n(ddr2_cs_n),
        .ddr2_dm(ddr2_dm),
        .ddr2_odt(ddr2_odt),

        .cpu_clk(clk_cpu),
        .addr(mem_addr), //write address
        .read_addr(mem_addr), 
        .width(mem_transaction_width),
        .data_in(mem_d_to_ram),
        .data_out(mem_d_from_ram),
        .rstrobe(mem_rstrobe),
        .wstrobe(mem_wstrobe),
        .transaction_complete(mem_transaction_complete),
        .ready(mem_ready)
        );

    //////////  Traffic Generator  //////////
    /* 
        get rid of this because we know what is being written and read
    */
    reg[31:0] lfsr;
    reg[31:0] t_data;

    always @(posedge clk_cpu or negedge rst_n) begin
        if(~rst_n) lfsr <= 32'h0;
        else begin
            lfsr[31:1] <= lfsr[30:0];
            lfsr[0] <= ~^{lfsr[31], lfsr[21], lfsr[1:0]};
        end
    end

    localparam TGEN_GEN_AD = 3'h0; 
    localparam TGEN_WRITE  = 3'h1;
    localparam TGEN_WWAIT  = 3'h2;
    localparam TGEN_READ   = 3'h3;
    localparam TGEN_RWAIT  = 3'h4;
    
    reg[2:0] tgen_state;
    reg dequ; //Data read from RAM equals data written
        
    always @(posedge clk_cpu or negedge rst_n) begin
        if(~rst_n) begin
            tgen_state <= TGEN_GEN_AD;
            mem_rstrobe <= 1'b0;
            mem_wstrobe <= 1'b0;
            mem_addr <= 64'h0;
            mem_d_to_ram <= 28'h0;
            mem_transaction_width <= 3'h0;
            dequ <= 1'b0;
        end else begin
            case(tgen_state)
            TGEN_GEN_AD: begin
                    /* random number as mem address
                    */
                    mem_addr <= 64'd28; // make this the different addresses for the different parts of the system
                    // what is this 
                    mem_d_to_ram <= {4'hA, 60'h0};
                    tgen_state <= TGEN_WRITE;
                end
            TGEN_WRITE: begin
                    //when is mem ready? what triggers that?
                    if(mem_ready) begin
                        // this is set to 1 to write
                        mem_wstrobe <= 1;
                        //Write the entire 64-bit word
                        mem_transaction_width <= `RAM_WIDTH64;
                        tgen_state <= TGEN_WWAIT;
                    end
                end
            TGEN_WWAIT: begin
                    mem_wstrobe <= 0;
                    if(mem_transaction_complete) begin
                        // change this to an in between so its not being read and written
                        // at the same time
                        tgen_state <= TGEN_READ;
                    end
                end
            TGEN_READ: begin
                    if(mem_ready) begin
                        // this is set to 1 to read 
                        mem_rstrobe <= 1;
                        //Load only the single byte at that address
                        
                        // how do specify where the RAM data is coming from?
                        mem_transaction_width <= `RAM_WIDTH16;
                        tgen_state <= TGEN_RWAIT;
                    end
                end
            TGEN_RWAIT: begin
                    mem_rstrobe <= 0;
                    if(mem_transaction_complete) begin
                        // goes to idle state
                        tgen_state <= TGEN_GEN_AD; 
                        // compares data written to ram and data from ram
                        if(mem_d_from_ram[63:48] == mem_d_to_ram[63:48]) dequ <= 1;
                        else dequ <= 0;
                    end
                end
            endcase
        end
    end
    
    assign LED[0] = dequ;
    assign LED[15:1] = mem_d_from_ram[63:49];

endmodule