module hamming_parity_calculator #(
    parameter parity_bits,
    parameter data_width = (1<<parity_bits)-parity_bits-1
) (
    input  [data_width-1:0]  data,
    output [parity_bits-1:0] parity
);
    localparam total_width = data_width + parity_bits;
    wire [total_width:1] padded_data;

    // Do a Hamming merge to get more convenient bit numbering - allows us to index data bits out of the combined (interleaved) data and parity bits as they are represented in a Hamming code
    // this is equivalent to just renaming signals, there is no logic in this module
    hamming_merger #(
        .parity_bits(parity_bits)
    ) merger_inst (
        .parity('{default: 1'b0}), // pass in zeros as the parity here - it's just filler to get the bit numbering convenient. We will calculate the correct parity bits below
        .data(data),
        .full(padded_data)
    );

    // each vector in this array corresponds to one parity bit
    // and has a masked copy of the padded data
    wire [total_width:1] parity_bits_table [parity_bits-1:0];

    // example of the mask for a 4 parity bit implementation:
    //             p0  p1  p2  p3
    // 15   d10     X	X	X	X
    // 14   d9      	X	X	X
    // 13   d8      X		X	X
    // 12   d7      		X	X
    // 11   d6      X	X		X
    // 10   d5      	X		X
    //  9   d4      X			X
    //  8       p3  			X
    //  7   d3      X	X	X	
    //  6   d2      	X	X	
    //  5   d1      X		X	
    //  4       p2  		X	
    //  3   d0      X	X		
    //  2       p1  	X		
    //  1       p0  X			
    // where parity_bits={p3,p2,p1,p0};
    // data_bits={d10,d9,...,d0};
    // The X's indicate which bits contribute to which parity
    // Note there are FIFTEEN bits, not sixteen. Hamming codes only work with inconvenient non-powers-of-two


    genvar parity_bit,bit_index;
    generate
        for (parity_bit = 0; parity_bit < parity_bits; parity_bit = parity_bit + 1) begin
            for (bit_index = 1; bit_index < total_width+1; bit_index = bit_index + 1) begin
                // this bit should be included in the nth parity bit iff the nth bit of its index is set
                if (bit_index & (1 << parity_bit))
                    assign parity_bits_table[parity_bit][bit_index] = padded_data[bit_index];
                else
                    assign parity_bits_table[parity_bit][bit_index] = 1'b0;
            end

            // assign the output to the XOR of the vector from our table
            assign parity[parity_bit] = ^parity_bits_table[parity_bit];
        end
    endgenerate
endmodule
