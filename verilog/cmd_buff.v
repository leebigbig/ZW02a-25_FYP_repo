module CMD_BUFF(
    clk,
    rst_n,
    //axi inpui
    axi_wr_vld,
    axi_wr_addr,
    axi_wr_data,
    axi_wr_strb,
    axi_wr_region,
    //done siganl
    fifo_wr_done,
    //ctrl signal
    cmd_buff_ctrl_out_vld,
    cmd_buff_ctrl_out_data,
    ctrl_cmd_buff_rdy
);

    input clk;
    input rst_n; 
    //axi input
    input axi_wr_vld;
    input [AWARRD_WIDTH-1:0]axi_wr_addr;
    input [WDATA_WIDTH-1:0]axi_wr_data;
    input [WDATA_WIDTH-1:0]axi_wr_strb;
    input [1:0]axi_wr_region;
    //done siganl
    output fifo_wr_done;
    //ctrl siganl
    output cmd_buff_ctrl_out_vld;
    output [WDATA_WIDTH-1:0] cmd_buff_ctrl_out_data;
    input ctrl_cmd_buff_rdy;

    //write qual
    wire fifo_wr_qual;
    wire in0_vld_qual;
    wire fifo_wr_hang;
    wire fifo_wr_hang_nxt;
    wire [WDATA_WIDTH-1:0] in0_data;
    wire [WDATA_WIDTH-1:0] in0_data_qual;
    wire [WDATA_WIDTH-1:0] in0_data_nxt;
    //write status
    wire fifo_wr_received;
    wire fifo_wr_received_nxt;
    //fifo output
    wire cmd_buff_full;

    assign fifo_wr_qual = axi_wr_vld & (axi_wr_region == `AXI_CMD_FIFO_REGION);

    assign fifo_wr_hang_nxt = fifo_wr_qual & cmd_buff_full | fifo_wr_hang & ~cmd_buff_full;
    DFFR ff_cmd_buff_hang (.clk(clk), .rst_n(rst_n), .d(fifo_wr_qual), .q(fifo_wr_hang)); 

    assign in0_data_nxt = fifo_wr_qual ? axi_wr_data : in0_data;
    DFFRE #(.WIDTH(WDATA_WIDTH)) ff_in_data (.clk(clk), .rst_n(rst_n), .en(fifo_wr_qual), .d(in0_data_nxt), .q(in0_data));

    assign in0_vld_qual = (fifo_wr_qual | fifo_wr_hang) & ~cmd_buff_full;
    assign in0_data_qual = fifo_wr_hang ? in0_data : axi_wr_data;

    one_in_one_out_fifo_lib
    #(
        .ENT_NUM(4),
        .DATA_SIZE(WDATA_WIDTH)
    )
    cmd_fifo(
        .clk(clk),
        .rst_n(rst_n),
        .in_vld(in0_vld_qual),
        .in_data(in0_data_qual),
        .out_vld(cmd_buff_ctrl_out_vld),
        .out_data(cmd_buff_ctrl_out_data),
        .fifo_full(cmd_buff_full),
        .pick_rdy(ctrl_cmd_buff_rdy)
    );

    DFFR ff_fifo_wr_done (.clk(clk), .rst_n(rst_n), .en(fifo_wr_qual), .d(in0_vld_qual), .q(fifo_wr_done));

endmodule