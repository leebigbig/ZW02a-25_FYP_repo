`include "define.vh"

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
    BVALID,
    BREADY,
    // internal interfaces
    axi_wr_vld,
    axi_wr_addr,
    axi_wr_data,
    axi_wr_strb,
    axi_wr_region,
    fifo_wr_done,
    fifo_err,
    iram_wr_done,
    wram_wr_done
);
    //parameter
    parameter AWID_WIDTH = 8;
    parameter AWARRD_WIDTH = 11;
    parameter WDATA_WIDTH = 32;
    parameter WSTRB_WIDTH = 4; // should be WDATA_WIDTH/4
    //inout bus
    input clk;
    input rst_n;
    //address write channel 
    input [AWID_WIDTH-1:0] AWID;
    input [AWARRD_WIDTH-1:0] AWADDR;
    input [7:0] AWLEN;
    input [2:0] AWSIZE;
    input [1:0] AWBURST;
    input [3:0] AWREGION;
    input  AWVALID;
    output AWREADY;
    //write data channel
    input [WDATA_WIDTH-1:0] WDATA;
    input [WSTRB_WIDTH-1:0] WSTRB;
    input WLAST;
    //FIXME WUSER not define signal 
    //input WUSER;
    input WVLID;
    output WREADY;
    //write response channel
    output [AWID_WIDTH-1:0] BID;
    output [1:0] BRESP;
    output BVALID;
    input BREADY;
    //internal interface
    output axi_wr_vld;
    output [AWARRD_WIDTH-1:0]axi_wr_addr;
    output [WDATA_WIDTH-1:0]axi_wr_data;
    output [WDATA_WIDTH-1:0]axi_wr_strb;
    output [1:0]axi_wr_region;
    input fifo_wr_done;
    input fifo_err;
    input iram_wr_done;
    input wram_wr_done;

    //address write related
    wire awready_nxt;
    wire awid_match;
    wire axi_wr_done;
    wire axi_wr_begin;
    wire axi_wr_finish;
    wire [AWARRD_WIDTH-1:0] axi_wr_init_addr;
    wire [AWARRD_WIDTH-1:0] axi_wr_init_addr_nxt;
    wire [1:0] axi_wr_burst;
    wire [1:0] axi_wr_burst_nxt;
    wire [2:0] axi_wr_size;
    wire [2:0] axi_wr_size_nxt;
    wire [7:0] axi_wr_len;
    wire [7:0] axi_wr_len_nxt;
    wire [AWID_WIDTH-1:0] axi_wr_id;
    wire [AWID_WIDTH-1:0] axi_wr_id_nxt;
    //status bit for burst write, pull high after received valid address write
    //pull low after receiving first data write
    wire axi_wr_init; 
    wire axi_wr_init_nxt; 
    wire axi_wr_init_en; 
    //write data related
    wire wready_nxt;
    //internal interface related
    wire axi_wr_received;
    wire axi_transfer_done;
    wire [7:0] axi_wr_cnt; //counter for write transfer in this burst
    wire [7:0] axi_wr_cnt_nxt;
    wire [WDATA_WIDTH-1:0] axi_wr_strb_nxt;
    wire [WDATA_WIDTH-1:0] axi_wr_data_nxt;
    wire [AWARRD_WIDTH-1:0] axi_wr_addr_nxt;
    wire [AWARRD_WIDTH-1:0] axi_wr_size_one_hot;
    //write response related
    wire bvld_nxt;
    wire [1:0] bresp_nxt;
    wire bresp_en;
    wire axi_wr_finish_status; //last wr is received
    wire axi_wr_finish_status_nxt; //last wr is received
    wire axi_wr_finish_status_en; //last wr is received
    wire slverr_allowed;

    assign axi_wr_begin = AWREADY & AWVALID; //receive awvalid with match awid
    assign awready_nxt = ~axi_wr_begin | axi_wr_done; //when a burst is done transfer, pull up awready
    DFFS ff_awready (.clk(clk), .rst_n(rst_n), .d(awready_nxt), .q(AWREADY));

    assign axi_wr_doing_nxt = axi_wr_begin | ~axi_wr_finish;
    assign axi_wr_doing_en = axi_wr_begin | axi_wr_finish;
    assign axi_wr_finish = (~(|axi_wr_cnt) | WLAST) & axi_wr_doing & axi_wr_received; //received last transaction
    assign axi_wr_finish_status_nxt = axi_wr_finish | axi_wr_finish_status & ~axi_transfer_done;
    assign axi_wr_finish_status_en = axi_wr_doing_en | axi_transfer_done;
    DFFRE ff_axi_wr_doing(.clk(clk), .rst_n(rst_n), .en(axi_wr_doing_en), .d(axi_wr_doing_nxt), .q(axi_wr_doing));
    DFFRE ff_axi_wr_doing2(.clk(clk), .rst_n(rst_n), .en(axi_wr_finish_status_en), .d(axi_wr_finish_status_nxt), .q(axi_wr_finish_status));

    assign axi_wr_len_nxt = axi_wr_doing? axi_wr_len: AWLEN;
    assign axi_wr_size_nxt = axi_wr_doing? axi_wr_size: AWSIZE;
    assign axi_wr_region_nxt = axi_wr_doing? axi_wr_region: AWREGION;
    assign axi_wr_init_addr_nxt = axi_wr_doing? axi_wr_init_addr : AWADDR;
    assign axi_wr_burst_nxt = axi_wr_doing? axi_wr_burst : (&AWBURST[1:0] | AWBURST[2]) ? `AWBURST_MAX : AWBURST;
    assign axi_wr_id_nxt = axi_wr_doing? axi_wr_id : AWID;

    DFFE  #(.WIDTH(AWARRD_WIDTH)) ff_axi_wr_addr (.clk(clk), .en(AWVALID), .d(axi_wr_init_addr_nxt), .q(axi_wr_init_addr));
    DFFE  #(.WIDTH(2)) ff_axi_wr_burst (.clk(clk), .en(AWVALID), .d(axi_wr_burst_nxt), .q(axi_wr_burst));
    DFFE  #(.WIDTH(3)) ff_axi_wr_size  (.clk(clk), .en(AWVALID), .d(axi_wr_size_nxt), .q(axi_wr_size));
    DFFE  #(.WIDTH(8)) ff_axi_wr_len   (.clk(clk), .en(AWVALID), .d(axi_wr_len_nxt), .q(axi_wr_len));
    DFFE  #(.WIDTH(2)) ff_axi_wr_region   (.clk(clk), .en(AWVALID), .d(axi_wr_region_nxt), .q(axi_wr_region));
    DFFE  #(.WIDTH(AWID_WIDTH)) ff_axi_wr_region2   (.clk(clk), .en(AWVALID), .d(axi_wr_id_nxt), .q(axi_wr_id));

    // wdata related
    assign axi_transfer_done = fifo_wr_done | iram_wr_done | wram_wr_done;
    assign axi_wr_received = (WREADY & WVLID & axi_wr_doing); //only receive write data when received valid address write
    assign wready_nxt = ~axi_wr_received | axi_transfer_done;
    assign axi_wr_init_nxt = axi_wr_begin | ~(axi_wr_init & axi_wr_received);
    assign axi_wr_init_en = AWVALID | WVLID;
    assign axi_wr_cnt_nxt = axi_wr_init  ? axi_wr_len :
                            (axi_wr_doing & (|axi_wr_cnt) ) ? axi_wr_cnt - 1 : axi_wr_cnt;
    assign axi_wr_size_one_hot = ({AWARRD_WIDTH{axi_wr_size == 3'b000}} & 'b001) |
                                 ({AWARRD_WIDTH{axi_wr_size == 3'b001}} & 'b010) |
                                 ({AWARRD_WIDTH{axi_wr_size == 3'b010}} & 'b100) ;
    assign axi_wr_addr_nxt = (axi_wr_init | axi_wr_burst == `AXI_WR_BURST_FIXED) ? axi_wr_init_addr :
                             (axi_wr_burst == `AXI_WR_BURST_INCR) ? axi_wr_addr + axi_wr_size_one_hot : axi_wr_addr;
    genvar i;
    generate
        for (i = 0;i<WDATA_WIDTH;i=i+1) begin
            assign axi_wr_strb_nxt[7+i*8:0+i*8] = axi_wr_received ? {8{WSTRB}} : axi_wr_strb[7+i*8:0+i*8];
        end
    endgenerate
    assign axi_wr_data_nxt = axi_wr_received ? WDATA : axi_wr_data;
    DFFS  ff_wready (.clk(clk), .rst_n(rst_n), .d(wready_nxt), .q(WREADY));
    DFFR  ff_wrvld (.clk(clk), .rst_n(rst_n), .d(axi_wr_received), .q(axi_wr_vld));
    DFFE  ff_axi_wr_init   (.clk(clk), .en(axi_wr_init_en), .d(axi_wr_init_nxt), .q(axi_wr_init));
    DFFE  #(.WIDTH(WDATA_WIDTH)) ff_axi_wr_dara   (.clk(clk), .en(WVLID), .d(axi_wr_data_nxt), .q(axi_wr_data));
    DFFE  #(.WIDTH(WDATA_WIDTH)) ff_axi_wr_strb   (.clk(clk), .en(WVLID), .d(axi_wr_strb_nxt), .q(axi_wr_strb));
    DFFE  #(.WIDTH(8))           ff_axi_wr_cnt    (.clk(clk), .en(WVLID), .d(axi_wr_cnt_nxt), .q(axi_wr_cnt));
    DFFE  #(.WIDTH(AWARRD_WIDTH)) ff_axi_wr_addr2 (.clk(clk), .en(AWVALID), .d(axi_wr_addr_nxt), .q(axi_wr_addr));

    // wresp related
    assign axi_wr_done = BVALID & BREADY; 
    assign bvld_nxt = ~axi_wr_done | axi_wr_finish_status & axi_transfer_done; 
    assign BID = axi_wr_id;
    //response logic
    assign slverr_allowed = ~BRESP[1] & fifo_err & fifo_wr_done;
    //
    assign bresp_nxt =  axi_wr_begin ? 2'b00
                     : slverr_allowed ? `AXI_SLVERR : BRESP;//TODO: axi_wr_stat;
    assign bresp_en = axi_transfer_done | axi_wr_begin;
    DFFR ff_wready2 (.clk(clk), .rst_n(rst_n), .d(bvld_nxt), .q(BVALID));
    DFFE #(.WIDTH(2)) ff_bresp (.clk(clk), .en(bresp_en), .d(bresp_nxt), .q(BRESP));
    

endmodule