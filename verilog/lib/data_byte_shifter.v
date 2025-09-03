module data_byte_shifter(
    in,
    offset,
    out
);
    input [127:0] in;
    input [3:0] offset;
    output [127:0] out;

    wire [127:0] shiftted_data [15:0];

    genvar i;
    generate
        for (i = 1;i < 16;i++) begin
            assign shiftted_data[i] = {in[7+i*8:0], in[127:8+i*8]};
        end
    endgenerate
    
    assign shiftted_data[0] = in;

    assign out = shiftted_data[offset];

endmodule