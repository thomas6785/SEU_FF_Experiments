module hamming_splitter #(
    parameter parity_bits,
    parameter data_width = (1<<parity_bits)-parity_bits-1,
    parameter total_width = (1<<parity_bits)-1
) (
    input  [total_width:1]   full,
    output [data_width-1:0]  data,
    output [parity_bits-1:0] parity
);
    // Simple module to take in Hamming-coded data and split out the data from the parity bits
    // Hamming code positions:
    //  Parity bits at powers of 2 (1, 2, 4, 8, ...)
    //  Data bits at all other positions

    // Note output bits are 1-indexed but data bits and parity bits are 0-indexed
    // e.g.
    // Output bit positions:    | 16 | 15 | 14 | 13 | 12 | 11 | 10 |  9 |  8 |  7 |  6 |  5 |  4 |  3 |  2 |  1
    // Data bit numbering:      | 11 | 10 |  9 |  8 |  7 |  6 |  5 |  4 |    |  3 |  2 |  1 |    |  0 |    |
    // Parity bit numbering:    |    |    |    |    |    |    |    |    |  3 |    |    |    |  2 |    |  1 |  0

    genvar i;
    generate
        for (i = 1; i < total_width+1; i = i + 1) begin
            if ((1<<$clog2(i)) == i) // if it's a power of two, assign a parity bit
                assign parity[$clog2(i)] = full[i];
            else // otherwise, assign a data bit
                assign data[i-$clog2(i)-1] = full[i];
        end
    endgenerate
endmodule
