module hamming_reg #(
    parameter data_width
) (
    input clk,
    input reset,
    input wren,
    input [data_width-1:0] wdata,
    output logic [data_width-1:0] rdata
);
    // This module pads wdata up to the next size allowable by Hamming codes
    // then wraps hamming_reg_core which has the error correcting logic

    // the allowable data bits is given by (2^p - p - 1) where p is the number of parity bits
    // this formula can't be reversed so we use a lookup to determine how many parity bits are needed:
    localparam parity_bits = data_width <= (1<< 1)- 1-1 ?  1 :
                             data_width <= (1<< 2)- 2-1 ?  2 :
                             data_width <= (1<< 3)- 3-1 ?  3 :
                             data_width <= (1<< 4)- 4-1 ?  4 :
                             data_width <= (1<< 5)- 5-1 ?  5 :
                             data_width <= (1<< 6)- 6-1 ?  6 :
                             data_width <= (1<< 7)- 7-1 ?  7 :
                             data_width <= (1<< 8)- 8-1 ?  8 :
                             data_width <= (1<< 9)- 9-1 ?  9 :
                             data_width <= (1<<10)-10-1 ? 10 :
                             data_width <= (1<<11)-11-1 ? 11 :
                             data_width <= (1<<12)-12-1 ? 12 :
                             data_width <= (1<<13)-13-1 ? 13 :
                             data_width <= (1<<14)-14-1 ? 14 :
                             data_width <= (1<<15)-15-1 ? 15 :
                             data_width <= (1<<16)-16-1 ? 16 :
                             data_width <= (1<<17)-17-1 ? 17 :
                             data_width <= (1<<18)-18-1 ? 18 :
                             data_width <= (1<<19)-19-1 ? 19 :
                             data_width <= (1<<20)-20-1 ? 20 :
                             $clog2(data_width)+1; // this is an approximation that will sometimes include an extra bit unnecessarily

    localparam padded_data_width = (1<<parity_bits)-parity_bits-1;

    // Pad the wdata and rdata up to the width accommodated by Hamming codes
    wire [padded_data_width-1:0] wdata_padded;
    wire [padded_data_width-1:0] rdata_padded;
    assign wdata_padded = {{(padded_data_width - data_width){1'b0}}, wdata};
    assign rdata = rdata_padded[data_width-1:0];

    hamming_reg_core #(
        .parity_bits(parity_bits)
    ) core (
        .clk(clk),
        .reset(reset),
        .wren(wren),
        .wdata(wdata_padded),
        .rdata(rdata_padded)
    );
endmodule