module DFFE(
    clk,
    d,
    en,
    q
);

parameter WIDTH = 1;

input wire clk;
input wire en;
input wire [WIDTH-1:0]d;
output reg [WIDTH-1:0]q;

always@(posedge clk)begin
    if(en) begin
        q <= d;
    end
end

endmodule
