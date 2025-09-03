
module one_in_one_out_fifo_lib(
    clk,
    rst_n,
    in_vld,
    in_data,
    out_vld,
    out_data,
    fifo_full,
    pick_rdy
);
    //one in one out fifo with overwrite allowed
    //need to implement qualify logic if do not want overwrite occur
    //parameter
    parameter ENT_NUM = 4;
    parameter ENT_NUM_WIDTH = $clog2(ENT_NUM);
    parameter DATA_SIZE = 32;

    //inout
    input clk;
    input rst_n;
    input in_vld;
    input [DATA_SIZE-1:0] in_data;
    output out_vld;
    output [DATA_SIZE-1:0] out_data;
    output fifo_full;
    input pick_rdy;

    //alloc logic
    wire [ENT_NUM-1:0] alloc_ptr_oh;
    wire [ENT_NUM-1:0] alloc_ptr_oh_nxt;
    wire [ENT_NUM-1:0] alloc_ptr_oh_qual;
    //pick logic
    wire [ENT_NUM-1:0] pick_ptr_oh;
    wire [ENT_NUM-1:0] pick_ptr_oh_nxt;
    wire [ENT_NUM_WIDTH-1:0] pick_ptr;
    wire [ENT_NUM_WIDTH-1:0] pick_ptr_nxt;
    wire ent_out;
    wire pick_ptr_oh_update_en;

    //vld logic
    wire [ENT_NUM-1:0] ent_vld;
    wire [ENT_NUM-1:0] ent_vld_nxt;
    wire ent_update;
    wire [DATA_SIZE-1:0] ent_data [ENT_NUM-1:0];

    //alloc logic
    assign alloc_ptr_oh_nxt = {alloc_ptr_oh[ENT_NUM-2:0], alloc_ptr_oh[ENT_NUM-1]}; //rr alloc
    DFFRE #(.WIDTH(ENT_NUM-1)) ff_alloc_ptr_oh_hi (.clk(clk), .rst_n(rst_n), .en(in_vld),.d(alloc_ptr_oh_nxt[ENT_NUM-1:1]), .q(alloc_ptr_oh[ENT_NUM-1:1]));
    DFFSE ff_alloc_ptr_oh_lo (.clk(clk), .rst_n(rst_n), .en(in_vld), .d(alloc_ptr_oh_nxt[0]), .q(alloc_ptr_oh[0]));
    assign alloc_ptr_oh_qual = alloc_ptr_oh & {ENT_NUM{in_vld}};
    //pick logic
    assign ent_out = out_vld & pick_rdy;
    assign pick_ptr_oh_update_en = out_en | in_vld & (|(alloc_ptr_oh & pick_ptr_oh & ent_vld)); //overwrite on vld ent
    assign pick_ptr_oh_nxt = {pick_ptr_oh[ENT_NUM-2:0], pick_ptr_oh[ENT_NUM-1]}; //rr pick
    assign pick_ptr_nxt = pick_ptr + 'b1 ;
    DFFRE #(.WIDTH(ENT_NUM-1)) ff_pick_ptr_oh_hi (.clk(clk), .rst_n(rst_n), .en(ent_out),.d(pick_ptr_oh_nxt[ENT_NUM-1:1]), .q(pick_ptr_oh[ENT_NUM-1:1]));
    DFFSE ff_alloc_ptr_oh_lo (.clk(clk), .rst_n(rst_n), .en(pick_ptr_oh_update_en), .d(pick_ptr_oh_nxt[0]), .q(pick_ptr_oh[0]));
    DFFRE #(.WDATA_WIDTH(ENT_NUM_WIDTH)) ff_pick_ptr (.clk(clk), .rst_n(rst_n), .en(pick_ptr_oh_update_en), .d(pick_ptr_nxt), .pick_ptr(pick_ptr)); 
    //vld logic
    assign ent_update = in_vld | ent_out;
    assign ent_vld_nxt = alloc_ptr_oh_qual | ent_vld & ~(pick_ptr_oh & {ENT_NUM{pick_rdy}});
    DFFRE #(.WIDTH(ENT_NUM)) ff_ent_vld(.clk(clk), .rst_n(rst_n), .en(ent_update), .d(ent_vld_nxt), .q(ent_vld));
    //out logic 
    assign out_vld = |ent_vld;

    genvar i;
    generate
        for (i = 0; i < ENT_NUM ;i=i+1) begin
            DFFE #(.WIDTH(DATA_SIZE)) ff_ent_data
            (
                .clk(clk), 
                .rst_n(rst_n), 
                .en(alloc_ptr_oh_qual[i]), 
                .d(in_data), 
                .q(ent_data[i])
            );
        end
    endgenerate

    assign out_data = ent_data[pick_ptr];



     

endmodule