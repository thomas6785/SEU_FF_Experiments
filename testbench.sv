module testbench;
    localparam data_width = 16;

    // DUT signals
    logic clk;
    logic [data_width-1:0] wdata;
    logic [data_width-1:0] rdata;
    logic wren;
    logic reset;

    logic [data_width-1:0] expected_value; // testbench signal

    // Define a clock
    initial begin
        clk = 1;
        forever begin
            #5 clk = ~clk;
        end
    end

    // DUT
    hamming_reg #(
        .data_width(data_width)
    ) dut (
        .wren(wren),
        .wdata(wdata),
        .rdata(rdata),
        .clk(clk),
        .reset(reset)
    );

    // Constantly changing write data
    initial begin
        forever begin
            @(posedge clk)
            #2 wdata = $urandom_range(0, (1 << data_width) - 1);
        end
    end

    // Inject SEU's randomly, sometimes in bursts, sometimes just one. NEVER TWO IN THE SAME CLOCK CYCLE - Hamming codes cannot handle that by design
    initial begin
        int seu_burst_length;
        forever begin
            // Wait a random number of cycles before SEU burst
            int wait_cycles = $urandom_range(2, 10);
            repeat (wait_cycles) @(posedge clk);

            // Inject a random number of SEUs in a burst
            seu_burst_length = $urandom_range(1, 4);
            repeat (seu_burst_length) begin
                #5 inject_seu;
                @(posedge clk);
            end
        end
    end

    // Always expect expected value
    initial begin
        #21
        forever begin
            #1
            $display("%0t Asserting %0d == %0d", $time, rdata, expected_value);
            assert (rdata == expected_value) else $fatal("Assertion failed: rdata (%0d) != expected_value (%0d) at time %0t", rdata, expected_value, $time);
        end
    end

    initial begin
        wdata = 0; expected_value = 0; wren = 0;
        reset = 1;
        #1 reset = 0;
        #1 reset = 1;

        write_new_value; // write a new value
        repeat (10) begin
            #1000          // and let it run for 100 clock cycles to observe SEU impact
            write_new_value; // write a new value
        end
        #1000
        $finish;
    end

    // Task to randomly flip one bit in dut.mem
    task inject_seu;
        int bit_pos;
        begin
            // Randomly select a bit position
            bit_pos = $urandom_range(0, $size(dut.core.mem)-1);

            // Flip the selected bit
            dut.core.mem[bit_pos] = ~dut.core.mem[bit_pos];

            $display("SEU injected: Flipped bit %0d in dut.core.mem at time %0t", bit_pos, $time);
        end
    endtask

    task write_new_value;
        begin
            @(posedge clk); #1
            wren = 1;
            $display("%0t Set new wdata %0d and asserting wren", $time, wdata);
            @(posedge clk);
            expected_value = wdata;
            #1
            wren = 0;
            $display("%0t Deasserting wren and updating expected_value to %0d", $time, expected_value);
        end
    endtask
endmodule
