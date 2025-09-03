module ram_buffer_ent(
    clk,
    rst_n,
    alloc_en,
    alloc_data,
    alloc_addr,
    alloc_byte,
    axi_rd_addr,
    ram_update,
    ent_cnt_dec,
    ent_cnt_inc,
    buff_start_byte,
    buff_end_byte,
    addr_match,
    ent_vld,
    ent_data,
    ent_addr,
    ent_age,
    ent_free,
    ent_vld_1_in_16
);

    input clk;
    input rst_n;
    input alloc_en;
    input [127:0] alloc_data;
    input [7:0] alloc_addr;
    input [3:0] alloc_byte;
    input [7:0] axi_rd_addr;
    input ram_update;
    input ent_cnt_dec;
    input ent_cnt_inc;
    input [3:0] buff_start_byte;
    input [3:0] buff_end_byte;

    output addr_match;
    output ent_vld;
    output [127:0] ent_data;
    output [7:0] ent_addr;
    output ent_age;
    output ent_free;
    output [15:0] ent_vld_1_in_16;

    wire ent_vld_nxt;
    wire [2:0] ent_cnt;
    wire [2:0] ent_cnt_nxt;
    wire ent_cnt_upd_conflict;
    wire ent_cnt_upd_en;
    wire ent_cur_nxt;
    wire ent_cur_upd_en;
    wire ent_vld_ptr;
    wire ent_vld_ptr_nxt;
    wire ent_vld_ptr_en;
    wire [3:0] ent_cur_byte;
    wire [3:0] ent_cur_byte_nxt;
    wire ent_cur_byte_en;
    wire [127:0] ent_data_pre;
    wire [127:0] ent_data_invert;
    wire [127:0] ent_data_shifted_pos;
    wire [127:0] ent_data_shifted_neg;
    wire ent_read_dir;
    wire [127:0] ent_data_msk;

    assign ent_cnt_upd_conflict = ent_cnt_dec & ent_cnt_inc;
    assign ent_cnt_nxt = alloc_en ? 3'b001 :
                         ent_cnt_upd_conflict ? ent_cnt :
                         ent_cnt_dec ? ent_cnt - 3'b1 : ent_cnt + 3'b1;
    assign ent_cnt_upd_en = alloc_en | ent_cnt_dec | ent_cnt_inc;
    assign ent_free = ~(ent_cnt);

    assign ent_cur_upd_en = alloc_en | ram_update;
    assign ent_cur_nxt = alloc_en ? 1'b1 : 1'b0;

    //ent vld logic
    assign ent_vld_nxt = alloc_en | ent_vld & ~(ent_cur_byte == buff_end_byte); //read out all required byte, invld ent
    DFFR ff_ent_vld (.clk(clk), .rst_n(rst_n), .d(ent_vld_nxt), .q(ent_vld));
    //
    //ent read byte
    assign ent_cur_byte_en = alloc_en | ent_vld;
    assign ent_cur_byte_nxt = alloc_en ? buff_start_byte
                            : (ent_cur_byte > buff_end_byte) ? ent_cur_byte - 4'b1 
                            : (ent_cur_byte < buff_end_byte) ? ent_cur_byte + 4'b1
                            : ent_cur_byte;
    DFFE #(.WIDTH(4)) ff_ent_cur_byte (.clk(clk), .en(ent_cur_byte_en), .d(ent_cur_byte_nxt), .q(ent_cur_byte));
    //
    DFFE #(.WIDTH(3)) ff_ent_cnt  (.clk(clk), .en(ent_cnt_nxt), .d(ent_cnt_upd_en), .q(ent_cnt));
    DFFE #(.WIDTH(8)) ff_ent_addr (.clk(clk), .en(alloc_en), .d(alloc_addr), .q(ent_cnt));
    DFFE #(.WIDTH(128)) ff_ent_data_pre (.clk(clk), .en(alloc_en), .d(alloc_data), .q(ent_data_pre));
    DFFE ff_ent_cur (.clk(clk), .en(ent_cur_upd_en), .d(ent_cur_nxt), .q(ent_cur));

    assign addr_match = ent_vld & (ent_addr == axi_rd_addr);

    //to mxu output logic
    assign ent_vld_ptr_en = alloc_en | ent_vld;
    assign ent_vld_ptr_nxt = alloc_en ? 16'h0001 : {ent_vld_ptr[14:0], ent_vld_ptr[15]};

    DFFRE #(.WIDTH(ENT_NUM-1)) 
    ff_ent_vld_ptr_hi( 
        .clk(clk), 
        .rst_n(rst_n), 
        .en(ent_vld_ptr_en), 
        .d(ent_vld_ptr_nxt[15:1]), 
        .q(ent_vld_ptr[15:1])
    );

    DFFSE #(.WIDTH(1)) 
    ff_ent_vld_ptr_lo( 
        .clk(clk), 
        .rst_n(rst_n), 
        .en(ent_vld_ptr_en), 
        .d(ent_vld_ptr_nxt[0]), 
        .q(ent_vld_ptr[0])
    );

    assign ent_vld_1_in_16 = {16{ent_vld}} & ent_vld_ptr;   
    
    //ent data shifting
    genvar i;
    generate
        for (i = 0;i < 16;i=i+1) begin
            assign ent_data_invert[7+i*8:i*8] = ent_data_pre[127-i*8:120-i*8];
        end
    endgenerate

    data_byte_shifter pos_shifter(.in(ent_data_pre), .offset(buff_start_byte), .out(ent_data_shifted_pos));
    data_byte_shifter neg_shifter(.in(ent_data_pre), .offset(buff_start_byte), .out(ent_data_shifted_neg));
    //
    
    //output data mux
    genvar i;
    generate
        for (i = 0;i < 16;i=i+1) begin
            assign ent_data_msk[7+i*8:0+i*8] = {8{ent_vld_1_in_16[i]}};
        end
    endgenerate

    assign ent_read_dir = buff_start_byte >= buff_end_byte;
    assign ent_data = ({128{ent_read_dir}} & ent_data_shifted_pos | ~{128{ent_read_dir}} & ent_data_shifted_neg) & ent_data_msk;
    //

    //
    

endmodule