module AXI_WRITE_INFT(
    clk,
    rst_n,
    // waddr interface
    AWID,
    AWADDR,
    AWLEN,
    AWSIZE,
    AWBURST,
    AWREGION,
    AWVALID,
    AWREADY,
    // wdata interface
    WDATA,
    WSTRB,
    WLAST,
    WVLID,
    WREADY,
    // wresp interface
    BID,
    BRESP,
    BUSER,
    BVALID,
    BREADY,
    // internal interfaces
    axi_wr_doing,
    axi_wr_addr,
    axi_wr_busrt,
    axi_wr_size,
    axi_wr_len,
    axi_transfer_done,
    axi_wr_vld,
    axi_wr_data,
    axi_wr_strb,

);
    //parameter
    parameter AWID_WIDTH = 8;
    parameter AWARRD_WIDTH = 11;
    parameter WDATA_WIDTH = 32;
    parameter WSTRB_WIDTH = 4; // should be WDATA_WIDTH/4
    //inout bus
    input clk;
    input rst_n;
    
    input [AWID_WIDTH-1:0] AWID;
    input [AWARRD_WIDTH-1:0] AWADDR;
    input [7:0] AWLEN;
    input [2:0] AWSIZE;
    input [1:0] AWBURST;
    input [3:0] AWREGION;
    input  AWVALID;
    output AWREADY;
    
    input [WDATA_WIDTH-1:0] WDATA;
    input [WSTRB_WIDTH-1:0] WSTRB;
    input WLAST;
    input WUSER;
    input WVLID;
    output WREADY;

    output [AWID_WIDTH-1:0] BID;
    output [1:0] BRESP;
    output BUSER;
    output BVALID;
    input BREADY;

    output axi_wr_doing;
    wire axi_wr_doing_nxt;
    wire axi_wr_doing_en;

    output [AWARRD_WIDTH-1:0] axi_wr_addr;
    output [1:0] axi_wr_burst;
    output [2:0] axi_wr_size;
    output [7:0] axi_wr_len;

    input axi_transfer_done;
    output axi_wr_vld;
    output [WDATA_WIDTH-1:0] axi_wr_data;
    output [WSTRB_WIDTH-1:0] axi_wr_strb;

    wire awready_nxt;
    wire awid_match;
    wire axi_wr_done;
    wire axi_wr_begin;
    wire axi_wr_finish;

    assign axi_wr_begin = awid_match & AWREADY & AWVALID;
    assign awid_match = ~(|(AWID ^ `TPU_ID));

    assign awready_nxt = ~axi_wr_begin | axi_wr_done;
    DFFS ff_awready (.clk(clk), .rst_n(rst_n), .d(awready_nxt), .q(AWREADY));

    assign axi_wr_doing_nxt = axi_wr_begin | ~axi_wr_finish;
    assign axi_wr_doing_en = axi_wr_begin | axi_wr_finish;
    DFFRE ff_axi_wr_doing(.clk(clk), .rst_n(rst_n), ,en(axi_wr_doing_en), .d(axi_wr_doing_nxt), .q(axi_wr_doing));

    DFFE  #(.WIDTH(AWARRD_WIDTH)) ff_axi_wr_addr (.clk(clk), .en(AWVALID), .d(AWADDR), .q(axi_wr_addr));
    DFFE  #(.WIDTH(2)) ff_axi_wr_burst (.clk(clk), .en(AWVALID), .d(AWBURST), .q(axi_wr_burst));
    DFFE  #(.WIDTH(3)) ff_axi_wr_size  (.clk(clk), .en(AWVALID), .d(AWSIZE), .q(axi_wr_size));
    DFFE  #(.WIDTH(8)) ff_axi_wr_len   (.clk(clk), .en(AWVALID), .d(AWLEN), .q(axi_wr_len));

    // wdata related
    wire wready_nxt;
    wire axi_wr_received;
    assign axi_wr_received = (WREADY & WVLID & axi_wr_doing);
    assign wready_nxt = ~axi_wr_received | axi_transfer_done;
    DFFS ff_wready (.clk(clk), .rst_n(rst_n), .d(wready_nxt), .q(WREADY));
    DFFR ff_wready (.clk(clk), .rst_n(rst_n), .d(axi_wr_received), .q(axi_wr_vld));
    DFFE  #(.WIDTH(WDATA_WIDTH)) ff_axi_wr_len   (.clk(clk), .en(WVLID), .d(WDATA), .q(axi_wr_data));
    DFFE  #(.WIDTH(WSTRB_WIDTH)) ff_axi_wr_len   (.clk(clk), .en(WVLID), .d(WSTRB), .q(axi_wr_strb));

    // wresp related 
    assign BID = `TPU_ID;

endmodule