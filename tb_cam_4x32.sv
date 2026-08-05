`timescale 1ns / 1ps

module tb_cam_4x32;

    logic        clk;
    logic        rst_n;

    logic        write_en;
    logic [1:0]  write_addr;
    logic [31:0] write_data;

    logic        search_en;
    logic [31:0] search_data;

    logic        match;
    logic [1:0]  match_addr;
    logic        miss;

    int unsigned pass_count = 0;
    int unsigned fail_count = 0;

    cam_4x32 dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .write_en    (write_en),
        .write_addr  (write_addr),
        .write_data  (write_data),
        .search_en   (search_en),
        .search_data (search_data),
        .match       (match),
        .match_addr  (match_addr),
        .miss        (miss)
    );

    always #5 clk = ~clk;
    task automatic write_entry(input logic [1:0] addr, input logic [31:0] data);
        @(negedge clk);
        write_en   = 1'b1;
        write_addr = addr;
        write_data = data;
        @(negedge clk);
        write_en   = 1'b0;
    endtask

    task automatic do_search(input logic [31:0] data);
        @(negedge clk);
        search_en   = 1'b1;
        search_data = data;
        #1; 
    endtask

    task automatic end_search();
        @(negedge clk);
        search_en = 1'b0;
    endtask

    task automatic check(input string name, input logic cond);
        if (cond) begin
            pass_count++;
            $display("PASS: %s", name);
        end else begin
            fail_count++;
            $display("FAIL: %s", name);
        end
    endtask
    initial begin
        clk         = 1'b0;
        rst_n       = 1'b0;
        write_en    = 1'b0;
        write_addr  = 2'd0;
        write_data  = 32'h0;
        search_en   = 1'b0;
        search_data = 32'h0;
        
        repeat (2) @(negedge clk);
        rst_n = 1'b1;

        // Test 0: search on an empty CAM must miss 
        do_search(32'hAAAA_AAAA);
        check("Empty CAM search misses", miss && !match);
        end_search();

        // Populate all 4 entries 
        write_entry(2'd0, 32'hDEAD_BEEF);
        write_entry(2'd1, 32'hCAFE_BABE);
        write_entry(2'd2, 32'h0000_0001);
        write_entry(2'd3, 32'hFFFF_FFFF);

        // Test 1: hit on entry 2 
        do_search(32'h0000_0001);
        check("Hit on entry 2", match && !miss && (match_addr == 2'd2));
        end_search();

        // Test 2: hit on entry 0
        do_search(32'hDEAD_BEEF);
        check("Hit on entry 0", match && !miss && (match_addr == 2'd0));
        end_search();

        // Test 3: hit on entry 3 
        do_search(32'hFFFF_FFFF);
        check("Hit on entry 3", match && !miss && (match_addr == 2'd3));
        end_search();

        // Test 4: miss on a tag that was never written 
        do_search(32'h1234_5678);
        check("Miss on unknown tag", miss && !match);
        end_search();

        // Test 5: overwrite entry 1, new tag should hit at addr 1
        write_entry(2'd1, 32'h1234_5678);
        do_search(32'h1234_5678);
        check("Hit on entry 1 after overwrite", match && !miss && (match_addr == 2'd1));
        end_search();

        // Test 6: old tag at entry 1 must now miss 
        do_search(32'hCAFE_BABE);
        check("Old tag misses after overwrite", miss && !match);
        end_search();

        // Test 7: reset clears all entries 
        rst_n = 1'b0;
        @(negedge clk);
        rst_n = 1'b1;
        @(negedge clk);
        do_search(32'hDEAD_BEEF);
        check("Search misses after reset", miss && !match);
        end_search();

        
        
        $display("Total: %0d  Passed: %0d  Failed: %0d",
                  pass_count + fail_count, pass_count, fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTS FAILED");

        $finish;
    end

endmodule
