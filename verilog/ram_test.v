module ram_test ();

    wire clk;
    wire rst_n;

    //for AXI address
    wire[7:0]  awid;
    wire[10:0] awaddr;
    wire[7:0]  awlen;
    wire[2:0]  awsize;
    wire[1:0]  awburst;
    wire[3:0]  awregion;
    wire awvalid;
    wire awready;

    //for burst 
    wire bready;
    wire[7:0] bid;
    wire[1:0] bresp;
    wire bvalid;

    //for write
    wire[31:0] wdata;
    wire[3:0]  wstrb;
    wire wlast;
    wire wvalid;
    wire wlast;
    wire wready;

    wire fifo_wr_done;
    wire fifo_err;
    wire iram_wr_done;
    wire wram_wr_done;

    wire axi_wr_vld;
    wire[10:0] axi_wr_addr;
    wire[31:0] axi_wr_data;
    wire[31:0] axi_wr_strb;
    wire[1:0]  axi_wr_region;

    //first similation 
    //basic ram write

    //address related input
    assign awid = 'b1;
    assign awaddr = 'b1;
    assign awlen = 8'b10000;
    assign awsize = 3'b100;
    assign awregion = 4'b0001;
    assign awvalid = 1'b1;
    assign awready = 1'b0;

    //burst related input
    assign bready = 1'b1;

    //write related input
    assign wdata = 'd404;
    assign wstrb = {8{1'b1}};
    assign wlast = 1'b1;
    assign wvalid = 1'b1;
    assign wready = 1'b1;

    AXI_WRITE_INTF ram_connect1( 
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
    
endmodule