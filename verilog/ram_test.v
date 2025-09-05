module ram_test ();

    reg clk;
    reg rst_n;

    //for AXI address
    reg[7:0]  awid;
    reg[10:0] awaddr;
    reg[7:0]  awlen;
    reg[2:0]  awsize;
    reg[1:0]  awburst;
    reg[3:0]  awregion;
    reg awvalid;
    wire awready;

    //for burst 
    reg bready;
    wire[7:0] bid;
    wire[1:0] bresp;
    wire bvalid;

    //for write
    reg[31:0] wdata;
    reg[8:0]  wstrb;
    reg wlast;
    reg wvalid;
    reg wlast;
    wire wready;

    reg fifo_wr_done;
    reg fifo_err;
    reg iram_wr_done;
    reg wram_wr_done;

    wire axi_wr_vld;
    wire[10:0] axi_wr_addr;
    wire[31:0] axi_wr_data;
    wire[31:0] axi_wr_strb;
    wire[1:0]  axi_wr_region;
    
    //bram
    reg[10:0] ram_addr;
    reg ram_ena;
    reg [15:0] ram_wea;
    reg[31:0] ram_in;
    wire[31:0] ram_out;
    wire awready_nxt;
    wire axi_wr_done;
    wire axi_wr_begin;
    wire bvld_nxt;
    wire axi_wr_finish_status;
    wire axi_transfer_done;
    wire axi_wr_finish_status_nxt;
    
    
    AXI_WRITE_INFT ram_connect1( 
        .clk(clk),
        .rst_n(rst_n),
        // waddr interface
        .AWID(awid),
        .AWADDR(awaddr),
        .AWLEN(awlen),
        .AWSIZE(awsize),
        .AWBURST(awburst),
        .AWREGION(awregion),
        .AWVALID(awvalid),
        .AWREADY(awready),
        // wdata interface
        .WDATA(wdata),
        .WSTRB(wstrb),
        .WLAST(wlast),
        .WVLID(wvalid),
        .WREADY(wready),
        // wresp interface
        .BID(bid),
        .BRESP(bresp),
        .BVALID(bvalid),
        .BREADY(bready),
        // internal interfaces
        .axi_wr_vld(axi_wr_vld),
        .axi_wr_addr(axi_wr_addr),
        .axi_wr_data(axi_wr_data),
        .axi_wr_strb(axi_wr_strb),
        .axi_wr_region(axi_wr_region),
        .fifo_wr_done(fifo_wr_done),
        .fifo_err(fifo_err),
        .iram_wr_done(iram_wr_done),
        .wram_wr_done(wram_wr_done),
        .axi_wr_done(axi_wr_done),
        .axi_wr_begin(axi_wr_begin),
        .awready_nxt(awready_nxt),
        .bvld_nxt(bvld_nxt),
        .axi_wr_finish_status(axi_wr_finish),
        .axi_transfer_done(axi_transfer_done),
        .axi_wr_finish_status_nxt(axi_wr_finish_status_nxt) 
                                                          
    );
    
    //assign ram_addr = 'b0;
    //assign ram_in = axi_wr_data;
    
    //Let this is update for wram
    blk_mem_gen_0 readinit1 (.clka (clk),
		                     .ena  (ram_ena),
			                 .wea  (ram_wea),
			                 .addra(ram_addr),
			                 .dina (ram_in),
			                 //.dina (0),
			                 .douta(ram_out));
    
    
    
    always #5 clk = ~clk;
    always #10 ram_ena = ~ram_ena;
    initial begin
        clk=1'b1;
        rst_n = 1'b0;
        #20;
        rst_n = 1'b1;
        //address related input
        awid = 'b1;
        awaddr = 'b0;
        awlen = 8'b0011;
        awsize = 3'b010;
        awregion = 4'b0001;
        awvalid = 1'b1;
        // WRAP
        awburst = 2'b10;

        //burst related input
        bready = 1'b1;

        //write related input
        wdata = 'd10;
        wstrb = {4{1'b1}};
        wlast = 1'b1;
        wvalid = 1'b1;
        ram_wea = {16{1'b0}};
        ram_ena = 1'b0;
        #20;
        ram_wea = {16{1'b1}};
        ram_in = axi_wr_data;
        ram_addr = axi_wr_addr;
        #10;
        ram_wea = 'b0;
        #10;
        ram_wea = {16{1'b1}};
        ram_in = axi_wr_data;
        ram_addr = axi_wr_addr;
        #10;
        ram_wea = 'b0;
        #50;
        ram_addr='d4;
        
        
    end
    always #10 awaddr=awaddr+ 'd4;  
    always #10 wdata = wdata + 'd1;
    always #10 ram_addr = ram_addr + 'd4;
    
    always #20 awid = awid + 'd1;
    always #80 ram_wea = 'b0; 
    
   

    
endmodule