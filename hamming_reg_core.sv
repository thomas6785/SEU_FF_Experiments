module hamming_reg_core #(
    parameter parity_bits
) (
    input clk,
    input reset,
    input wren,
    input [(1<<parity_bits)-parity_bits-2:0] wdata,
    output logic [(1<<parity_bits)-parity_bits-2:0] rdata
);

    localparam data_width = (1<<parity_bits)-parity_bits-1;
    localparam total_width = (1<<parity_bits)-1;

    // Signal declarations
    logic [total_width:1]   mem;
    wire  [data_width-1:0]  stored_data;                  // data stored in mem
    wire  [parity_bits-1:0] stored_parity;                // parity bits stored in mem
    wire  [parity_bits-1:0] calculated_wdata_parity_bits; // calculated parity bits based on selected_data
    wire  [parity_bits-1:0] calculated_mem_parity_bits;   // calculated parity bits based on selected_data
    wire  [total_width:1]   extended_wdata;               // wdata extended with parity bits
    wire  [parity_bits-1:0] syndrome;                     // calculated parity bits ^ stored parity. By the properties of Hamming codes, this VALUE is the bit position of the error bit in mem
    wire  [total_width:1]   correction_mask;              // mask to XOR with 'mem' to get 'corrected_mem' (has a '1' on the erroneous bit, or all 0's i fno SEU's have taken place)
    wire  [total_width:1]   corrected_mem;                // memory with bit correction according to syndrome
    wire  [total_width:1]   mem_next;                     // next value selected for mem (MUX'd between corrected_mem and extended_wdata)

    // ---------------------------------------------------------------
    //  Error correction
    // ---------------------------------------------------------------
    // Split stored mem into stored_data and stored_parity
    hamming_splitter #(
        .parity_bits(parity_bits)
    ) mem_splitter (
        .full(mem),
        .data(stored_data),
        .parity(stored_parity)
    );

    // Calculate expected parity bit values for the data in storage
    hamming_parity_calculator #(
        .parity_bits(parity_bits)
    ) parity_calculator (
        .data(stored_data),
        .parity(calculated_mem_parity_bits)
    );

    // Calculate syndrome and corrected mem
    assign syndrome = calculated_mem_parity_bits ^ stored_parity;
    assign correction_mask = syndrome > 0 ? (1 << (syndrome - 1)) : '0; // if syndrome is zero, no correction is needed. Otherwise the syndrome is the bit position of the error bit (a usefu lproperty of Hamming codes)
    assign corrected_mem = mem ^ correction_mask; // property of Hamming codes: the syndrome IS the binary representation of the index of the erroneous bit

    // ---------------------------------------------------------------
    //   Write logic (determine initial parity bits when writing)
    // ---------------------------------------------------------------
    // Calculate expected parity bit values for the write data
    hamming_parity_calculator #(
        .parity_bits(parity_bits)
    ) write_data_parity_calculator (
        .data(wdata),
        .parity(calculated_wdata_parity_bits)
    );

    // Determine write data from wdata and calculated parity bits
    hamming_merger #(
        .parity_bits(parity_bits)
    ) wdata_merger (
        .parity(calculated_wdata_parity_bits),
        .data(wdata),
        .full(extended_wdata)
    );
    // TODO: it's not ideal that we have two hamming_parity_calculator instances as each one is a lot of XOR gates
    // TODO: it's possible to do it with just a single one but then we need to read rdata from mem instead of corrected_mem, meaning SEU's are visible at the output for a brief moment. Not ideal
    // TODO: I wonder if it's possible to use the same parity calculator but somehow "lock" the data bits for one cycle so it's forced to adjust the parity bits instead?
    // TODO: all this to save a few XOR gates - it's possible the synthesis tool can figure this out for us anyway

    // ---------------------------------------------------------------
    //  Main flop
    // ---------------------------------------------------------------
    assign mem_next = wren ? extended_wdata : corrected_mem;
    always_ff @(posedge clk or negedge reset) begin
        if (!reset) mem <= '{default:1'b0};
        else        mem <= mem_next;
    end

    // Get output data
    hamming_splitter #(
        .parity_bits(parity_bits)
    ) output_splitter (
        .full(corrected_mem),
        .data(rdata),
        .parity()
    );
endmodule
