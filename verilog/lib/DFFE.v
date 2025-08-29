module DFFE(
    clk,
    dE,
    en,
    q,
);

parameter WIDTH = 1;

input wire clk;
input wire en;
input wire [WIDTH-1:0]d;
output reg [WIDTH-1:0]q;

always@(posedge clk or negedge rst_n)begin
    if(en) begin
        q <= d;
    end
end

endmodule
