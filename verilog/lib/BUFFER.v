module BUFFER(
    clk,
    rst_n,
    cen,
    wen, // 0:read 1:wriet 
    addr,
    wdata,
    rdata
);

//TODO should be change later 
parameter ADDR_WIDTH = 16;
parameter DATA_WIDTH = 16;

input wire clk;
input wire rst_n;
input wire cen;
input wire wen;
input wire [ADDR_WIDTH-1:0]addr;
input reg [DATA_WIDTH-1:0]wdata;
output reg [DATA_WIDTH-1:0]rdata;

reg [DATA_WIDTH-1:0] mem_data [ADDR_WIDTH-1:0]

always@(posedge clk or negedge rst_n)begin
    if(~rst_n)begin
        for (i=0; i<ADDR_WIDTH; i=i+1)begin
            mem_data[i] <= {DATA_WIDTH{1'b0}};
        end
    end
    else if(cen) begin
        if(wen)begin
            mem_data[addr] <= wdata;
        end
        else begin
            rdata = mem_data[addr]
        end
    end
end

endmodule
