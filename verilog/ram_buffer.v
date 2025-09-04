`include "define.vh"

module ram_buffer(
    clk,
    rst_n,
    //ram input
    ram_buff_alloc_vld,
    ram_buff_alloc_addr,
    ram_buff_alloc_data,
    //ctrl input
    ctrl_ram_buff_vld,
    ctrl_ram_buff_start_byte,
    ctrl_ram_buff_end_byte,
    ctrl_ram_buff_ent_num,
    ctrl_ram_buff_start_addr,
    ctrl_ram_buff_ent_rng,
    //to ram output
    ram_read_vld,
    ram_read_addr,
    //to mxu output
    ram_buff_mxu_vld,
    ram_buff_mxu_data 
);

    //parameter
    parameter AWID_WIDTH = 8;
    parameter AWARRD_WIDTH = 11;
    parameter WDATA_WIDTH = 32;
    parameter WSTRB_WIDTH = 4; // should be WDATA_WIDTH/4
    parameter RAM_WIDTH = 128;
    parameter RAM_DEPTH = 256;
    parameter RAM_TYPE  = `AXI_WRAM_REGION;
    parameter ENT_NUM = 16;
    //input
    input clk;
    input rst_n;
    //ram alloc data
    input ram_buff_alloc_vld;
    input [7:0] ram_buff_alloc_addr;
    input [127:0] ram_buff_alloc_data;
    //control signals
    input ctrl_ram_buff_vld;
    input [3:0] ctrl_ram_buff_start_byte;
    input [3:0] ctrl_ram_buff_end_byte;
    input [3:0] ctrl_ram_buff_ent_num;
    input [7:0] ctrl_ram_buff_start_addr;
    input [4:0] ctrl_ram_buff_ent_rng;
    //output to RAM
    output ram_read_vld;
    output [7:0] ram_read_addr;
    //output to MXU
    output [15:0] ram_buff_mxu_vld;
    output [127:0] ram_buff_mxu_data;

    //buff ent input
    //alloc logic
    wire [ENT_NUM-1:0] ent_alloc;
    wire [ENT_NUM-1:0] ent_alloc_ptr;
    wire [ENT_NUM-1:0] ent_alloc_ptr_nxt;
    wire [ENT_NUM-1:0] ent_alloc_ptr_en;
    wire [7:0] ent_alloc_addr;
    wire [127:0] ent_alloc_data;
    //
    wire [7:0] buf_rd_addr;
    //buff ent output
    wire [ENT_NUM-1:0] ent_vld;
    wire [15:0] ent_vld_1_in_16 [ENT_NUM-1:0];
    wire [127:0] ent_data[15:0];
    wire [7:0] ent_addr[15:0];
    wire [ENT_NUM-1:0] ent_cur;
    wire [ENT_NUM-1:0] ent_free;
    wire [ENT_NUM-1:0] ent_match;
    //RAM buffer status
    wire [1:0] ram_buff_stat_fsm;
    wire [1:0] ram_buff_stat_fsm_nxt;
    wire [1:0] ram_buff_stat_fsm_en;
    wire [3:0] ram_buff_ent_cnt;
    wire [3:0] ram_buff_ent_cnt_nxt;
    wire [3:0] ram_buff_ent_cnt_en;
    wire ram_buff_done_recv;
    wire ram_buff_done_send;
    //ctrl input store
    wire [3:0] ctrl_ram_buff_start_byte_ff;
    wire [3:0] ctrl_ram_buff_end_byte_ff;
    wire [3:0] ctrl_ram_buff_ent_num_ff;
    wire [7:0] ctrl_ram_buff_start_addr_ff;
    wire [4:0] ctrl_ram_buff_ent_rng_ff;
    wire [4:0] ram_buff_read_addr_offset;
    wire [4:0] ram_buff_read_addr_offset_nxt;
    wire ram_buff_read_addr_offset_en;
    wire ram_read_dir;
    //ram rd request logic
    wire all_ent_has_fetched;
    wire read_offset_exceed_ctrl_rng;

    //alloc ent
    assign ent_invld = ~ent_vld;

    DFFRE #(.WIDTH(ENT_NUM-1)) 
    ff_alloc_ptr_hi( 
        .clk(clk), 
        .rst_n(rst_n), 
        .en(ent_alloc_ptr_en), 
        .d(ent_alloc_ptr_nxt[ENT_NUM-1:1]), 
        .q(ent_alloc_ptr[ENT_NUM-1:1])
    );

    DFFSE #(.WIDTH(1)) 
    ff_alloc_ptr_lo( 
        .clk(clk), 
        .rst_n(rst_n), 
        .en(ent_alloc_ptr_en), 
        .d(ent_alloc_ptr_nxt[0]), 
        .q(ent_alloc_ptr[0])
    );
    
    assign ent_alloc_ptr_en = ram_buff_alloc_vld | ctrl_ram_buff_vld;

    assign ent_alloc_ptr_nxt = ctrl_ram_buff_vld ? {{ENT_NUM-1{1'b0}} ,1'b1} 
                             : {ent_alloc_ptr[ENT_NUM-2:0], ent_alloc_ptr[ENT_NUM-1]};

    assign ent_alloc_ptr = (|ent_invld) ? ent_invld_oh : ent_free_oh;
    assign ent_alloc = {ENT_NUM{ram_buff_alloc_vld}} & ent_alloc_ptr;

    assign ent_alloc_addr = ram_buff_alloc_addr;
    assign ent_alloc_data = ram_buff_alloc_data;
    //done alloc ent

    //ctrl input store
    DFFE #(.WIDTH(4)) 
    ff_ctrl_ram_buff_start_byte(
        .clk(clk),
        .rst_n(rst_n),
        .en(ctrl_ram_buff_vld),
        .d(ctrl_ram_buff_start_byte),
        .q(ctrl_ram_buff_start_byte_ff)
    );

    DFFE #(.WIDTH(4)) 
    ff_ctrl_ram_buff_end_byte(
        .clk(clk),
        .rst_n(rst_n),
        .en(ctrl_ram_buff_vld),
        .d(ctrl_ram_buff_end_byte),
        .q(ctrl_ram_buff_end_byte_ff)
    );
    
    DFFE #(.WIDTH(4)) 
    ff_ctrl_ram_buff_ent_num(
        .clk(clk),
        .rst_n(rst_n),
        .en(ctrl_ram_buff_vld),
        .d(ctrl_ram_buff_ent_num),
        .q(ctrl_ram_buff_ent_num_ff)
    );
    
    DFFE #(.WIDTH(8)) 
    ff_ctrl_ram_buff_start_addr(
        .clk(clk),
        .rst_n(rst_n),
        .en(ctrl_ram_buff_vld),
        .d(ctrl_ram_buff_start_addr),
        .q(ctrl_ram_buff_start_addr_ff)
    );
    
    DFFE #(.WIDTH(5)) 
    ff_ctrl_ram_buff_ent_rng(
        .clk(clk),
        .rst_n(rst_n),
        .en(ctrl_ram_buff_vld),
        .d(ctrl_ram_buff_ent_rng),
        .q(ctrl_ram_buff_ent_rng_ff)
    );
    //done ctrl input store
    
    //ram buff offset
    assign ram_read_dir = ~ctrl_ram_buff_ent_rng_ff[4]; //rng uses 2's complement
    assign ram_buff_read_addr_offset_en = ctrl_ram_buff_vld | ram_read_vld;
    assign ram_buff_read_addr_offset_nxt = ctrl_ram_buff_vld ? 5'b0 //read from start ent
                                         : ram_read_dir ? ram_buff_read_addr_offset + 5'b1
                                         : ram_buff_read_addr_offset - 5'b1;

    DFFE #(.WIDTH(5)) 
    ff_ram_buff_read_addr_offset(
        .clk(clk),
        .rst_n(rst_n),
        .en(ram_buff_read_addr_offset_en),
        .d(ram_buff_read_addr_offset_nxt),
        .q(ram_buff_read_addr_offset)
    );
    //

    //ram read logic
    //ram_buff_read_addr_offset == 0: first fetch request, must send to RAM
    //~read_offset_exceed_ctrl_rng: has not read out all ent
    assign read_offset_exceed_ctrl_rng = ram_read_dir & (ram_buff_read_addr_offset[3:0] > ctrl_ram_buff_ent_rng_ff[3:0])
                                       | ~ram_read_dir & (ram_buff_read_addr_offset[3:0] < ctrl_ram_buff_ent_rng_ff[3:0]);
    assign all_ent_has_fetched = (|ram_buff_read_addr_offset) & read_offset_exceed_ctrl_rng;
    assign ram_read_vld = ~ram_buff_stat_fsm[1] & ram_buff_stat_fsm[0] //2'b01
                        & ~all_ent_has_fetched;
    assign ram_read_addr = ctrl_ram_buff_start_addr_ff + {{3{ram_buff_read_addr_offset[4]}}, ram_buff_read_addr_offset};
    //

    //ram buff fsm
    assign ram_buff_done_recv = (ram_buff_ent_cnt == ctrl_ram_buff_ent_num_ff) & ram_buff_alloc_vld;
    assign ram_buff_done_send = (ram_buff_stat_fsm == `RAM_BUFF_FSM_SND) & ~(|ent_vld);
    assign ram_buff_stat_fsm_en = ctrl_ram_buff_vld | ram_buff_alloc_vld | (|ent_vld);
    assign ram_buff_stat_fsm_nxt = ctrl_ram_buff_vld ? `RAM_BUFF_FSM_RECV
                                 : ram_buff_done_recv ? `RAM_BUFF_FSM_SND
                                 : ram_buff_done_send ? `RAM_BUFF_FSM_IDLE : `RAM_BUFF_FSM_REV;

    DFFRE #(.WIDTH(2))
    ff_ram_buff_stat_fsm(
        .clk(clk),
        .rst_n(rst_n),
        .en(ram_buff_stat_fsm_en),
        .d(ram_buff_stat_fsm_nxt),
        .q(ram_buff_stat_fsm)
    );
    //done ram buff fsm

    genvar i;
    generate
        for (i = 0; i < ENT_NUM ; i=i+1) begin
            ram_buffer_ent ram_buffer_ent(
                .clk(clk),
                .rst_n(rst_n),
                .alloc_en(ent_alloc[i]),
                .alloc_data(ent_alloc_data),
                .alloc_addr(ent_alloc_addr),
                .alloc_byte(ctrl_ram_buff_start_byte_ff),
                .axi_rd_addr(buf_rd_addr),
                .ram_update(update_ent_cur[i]),
                .ent_cnt_dec(ent_cnt_inc[i]),
                .ent_cnt_inc(ent_pick[i]),
                .buff_start_byte(ctrl_ram_buff_start_byte_ff),
                .buff_end_byte(ctrl_ram_buff_end_byte_ff),
                .addr_match(ent_match[i]),
                .ent_vld(ent_vld[i]),
                .ent_data(ent_data[i]),
                .ent_addr(ent_addr[i]),
                .ent_cur(ent_cur[i]),
                .ent_free(ent_free[i]),
                .ent_vld_1_in_16(ent_vld_1_in_16[i])
            );
        end
    endgenerate 

    //output to MXU
    assign ram_buff_mxu_vld = ent_vld_1_in_16[0]
                            | ent_vld_1_in_16[1] 
                            | ent_vld_1_in_16[2] 
                            | ent_vld_1_in_16[3] 
                            | ent_vld_1_in_16[4] 
                            | ent_vld_1_in_16[5] 
                            | ent_vld_1_in_16[6] 
                            | ent_vld_1_in_16[7] 
                            | ent_vld_1_in_16[8] 
                            | ent_vld_1_in_16[9] 
                            | ent_vld_1_in_16[10] 
                            | ent_vld_1_in_16[11] 
                            | ent_vld_1_in_16[12] 
                            | ent_vld_1_in_16[13] 
                            | ent_vld_1_in_16[14] 
                            | ent_vld_1_in_16[15]; 
    
    assign ram_buff_mxu_data = ent_data[0]
                             | ent_data[1] 
                             | ent_data[2] 
                             | ent_data[3] 
                             | ent_data[4] 
                             | ent_data[5] 
                             | ent_data[6] 
                             | ent_data[7] 
                             | ent_data[8] 
                             | ent_data[9] 
                             | ent_data[10] 
                             | ent_data[11] 
                             | ent_data[12] 
                             | ent_data[13] 
                             | ent_data[14] 
                             | ent_data[15]; 
    //

endmodule