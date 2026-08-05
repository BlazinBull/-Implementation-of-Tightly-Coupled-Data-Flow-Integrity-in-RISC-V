`timescale 1ns / 1ps
// ============================================================================
// cam_4x32.sv
// 4-entry, 32-bit Content Addressable Memory (CAM)
//
// - Each entry has a 32-bit tag and a valid bit.
// - write_en loads write_data into the entry pointed to by write_addr and
//   marks it valid.
// - search_en compares search_data against all valid entries in parallel.
//   On a hit, match is asserted and match_addr gives the index of the
//   matching entry (lowest index wins if duplicate tags are ever written).
//   On a search with no valid entry matching, miss is asserted instead.
// ============================================================================

module cam_4x32 (
    input  logic        clk,
    input  logic         rst_n,       // active-low synchronous reset

    // Write port
    input  logic         write_en,
    input  logic  [1:0]  write_addr,  // selects 1 of 4 entries
    input  logic  [31:0] write_data,

    // Search (compare) port
    input  logic         search_en,
    input  logic  [31:0] search_data,

    // Search result (combinational on search_en/search_data)
    output logic         match,
    output logic  [1:0]  match_addr,
    output logic         miss
);

    localparam int NUM_ENTRIES = 4;

    logic [31:0] cam_mem [NUM_ENTRIES-1:0];
    logic        valid   [NUM_ENTRIES-1:0];
    logic [NUM_ENTRIES-1:0] match_lines;

//    integer i;

    // ------------------------------------------------------------------
    // Write logic: synchronous, active-low reset clears all valid bits
    // ------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < NUM_ENTRIES; i++) begin // <-- Added 'int' here
                cam_mem[i] <= 32'h0;
                valid[i]   <= 1'b0;
            end
        end else if (write_en) begin
            cam_mem[write_addr] <= write_data;
            valid[write_addr]   <= 1'b1;
        end
    end

    // ------------------------------------------------------------------
    // Compare logic: fully parallel tag comparison against every entry
    // ------------------------------------------------------------------
    always_comb begin
        for (int i = 0; i < NUM_ENTRIES; i++) begin // <-- Added 'int' here
            match_lines[i] = valid[i] && (cam_mem[i] == search_data);
        end
    end

    // ------------------------------------------------------------------
    // Priority encode the match lines into match_addr; lowest index wins
    // ------------------------------------------------------------------
    always_comb begin
        match      = search_en && (|match_lines);
        miss       = search_en && !(|match_lines);
        match_addr = 2'b00;
        unique case (1'b1)
            match_lines[0]: match_addr = 2'd0;
            match_lines[1]: match_addr = 2'd1;
            match_lines[2]: match_addr = 2'd2;
            match_lines[3]: match_addr = 2'd3;
            default:        match_addr = 2'd0;
        endcase
    end

endmodule

