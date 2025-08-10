module AXI_WRITE_INFT(
    clk,
    rst_n,
    // waddr interface
    AWID,
    AWADDR,
    AWLEN,
    AWSIZE,
    AWBURST,
    AWLOCK,
    AWCACHAE,
    AWPROT,
    AWQOS,
    AWREGION,
    AWUSER,
    AWVALID,
    AWREADY,
    // wdata interface
    WID,
    WDATA,
    WSTRB,
    WLAST,
    WUSER,
    WVLID,
    WREADY,
    // wresp interface
    BID,
    BRESP,
    BUSER,
    BVALID,
    BREADY

);
    //parameter
    AWID_WIDTH = 4;
    AWARRD_WIDTH = 11;
    WDATA_WIDTH = 32;
    WSTRB_WIDTH = 4; // should be WDATA_WIDTH/4
    //inout bus
    input wire clk;
    input wire rst_n;
    
    input wire[AWID_WIDTH-1:0] AWID;
    input wire[AWARRD_WIDTH-1:0] AWADDR;
    input wire[7:0] AWLEN;
    input wire[2:0] AWSIZE;
    input wire[1:0] AWBURST;
    input wire AWLOCK;
    input wire[3:0] AWCACHAE;
    input wire[2:0] AWPROT;
    input wire[3:0] AWQOS;
    input wire[3:0] AWREGION;
    input wire AWUSER;
    input wire AWVALID;
    output wire AWREADY;
    
    input wire [AWID_WIDTH-1:0] WID;
    input wire [WDATA_WIDTH-1:0] WDATA;
    input wire [WSTRB_WIDTH-1:0] WSTRB;
    input wire WLAST;
    input wire WUSER;
    input wire WVLID;
    output wire WREADY;

    output wire [AWID_WIDTH-1:0] BID;
    output wire [1:0] BRESP;
    output wire BUSER;
    output wire BVALID;
    input wire BREADY;

endmodule