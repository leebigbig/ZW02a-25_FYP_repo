module DFFR(
    clk,
    rst_n,
    d,
    en,
    q,
);

parameter WIDTH = 1;

input wire clk;
input wire rst_n;
input wire en;
input wire [WIDTH-1:0]d;
output reg [WIDTH-1:0]q;

always@(posedge clk or negedge rst_n)begin
    if(~rst_n)begin
        q <= {WIDTH{1'b0}};
    end
    else if(en) begin
        q <= d;
    end
end

endmodule
