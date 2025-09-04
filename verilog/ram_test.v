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
    reg[3:0]  wstrb;
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
    wire ram_ena;
    wire[10:0] ram_addr;
    reg [15:0] ram_wea;
    wire[31:0] ram_in;
    wire[31:0] ram_out;
    wire ram_rsta;
    
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
        .wram_wr_done(wram_wr_done)                                                       
    );
    
    assign ram_ena = 1'b1;
    assign ram_addr = 'b0;
    assign ram_in = axi_wr_data;
    
    //Let this is update for wram
    blk_mem_gen_0 readinit1 (.clka (clk),
		                     .ena  (ram_ena),
			                 .wea  (ram_wea),
			                 .addra(ram_addr),
			                 .dina (ram_in),
			                 .douta(ram_out),
			                 .rsta_busy(ram_rstb));
    
    
    
    always #5 clk = ~clk;
    initial begin
        clk=1'b0;
        rst_n = 1'b1;
        #5;
        rst_n = 1'b0;
        #20;
        rst_n = 1'b1;
        //address related input
        awid = 'b1;
        awaddr = 'b0;
        awlen = 8'b10000;
        awsize = 3'b100;
        awregion = 4'b0001;
        awvalid = 1'b1;
        // WRAP
        awburst = 2'b10;

        //burst related input
        bready = 1'b1;

        //write related input
        wdata = 'd404;
        wstrb = {8{1'b1}};
        wlast = 1'b1;
        wvalid = 1'b1;
        ram_wea = {16{1'b1}};
        
    end
    always #60 awaddr=awaddr+ 'd4;
    always #60 wdata = wdata + 'd1;
    always #120 awid = awid + 'd1;
    always #160 ram_wea = 'b0; 
    
   

    
endmodule