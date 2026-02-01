An experimental implementation of Hamming-code-hardened D-flip-flops

Modules "Hamming splitter" and "Hamming merger" have no logic and are just conveniences for numbering bits as the Hamming scheme expects it.

"Hamming parity calculator" is a more expensive module with lots of XOR's for checking parity

Design currently has TWO of these parity calculators (one for detecting and correcting errors in the flip flop, and one for preparing parity bits when writing new data). This is quite a substantial overhead and can be avoided, but not without some compromises to the behaviour.

Testbench randomly injects bursts of SEU's and constantly asserts the output is not affected.

Note that the flop cannot handle multiple SEU's in the same clock cycle

Possible improvements:
- Find a way to only have one parity calculator instead of two
- Quantify PPA overheads
- Provide support for multiple SEU's in a single clock cycle (either with nested Hamming codes or a more sophisticated scheme)
    The added complexity will increase overheads but will also mean far, far more bits can be included in the same EC block without compromising MTBF, ultimately reducing overheads.
- Provide suppor for sharing logic circuitry across multiple flip-flops
    - Parity calculator for write data can be shared for all registers in a bank of registers, for example
    - Error corrector circuit could multiplex back and forth across lots of flops
- Give some kind of simple 'wrapper' with an interface to connect to other flip flops so the dev can easily lump unrelated flip flops into one EC block e.g.: seu_hardened_ff #(.dwidth(7)) my_flip_flop (.wdata(whatever), .rdata(whatever), .wren(whatever), .hamming_if(interface_to_connect_to_a_central_EC_block))
    - Might be simpler to do this all "in-post" with some kind of post-processing on the RTL

