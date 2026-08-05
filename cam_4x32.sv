`timescale 1ns / 1ps

module cam_4x32 (
    input  logic        clk,
    input  logic         rst_n,       

    input  logic         write_en,
    input  logic  [1:0]  write_addr,  
    input  logic  [31:0] write_data,

    input  logic         search_en,
    input  logic  [31:0] search_data,

    output logic         match,
    output logic  [1:0]  match_addr,
    output logic         miss
);

    localparam int NUM_ENTRIES = 4;

    logic [31:0] cam_mem [NUM_ENTRIES-1:0];
    logic        valid   [NUM_ENTRIES-1:0];
    logic [NUM_ENTRIES-1:0] match_lines;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < NUM_ENTRIES; i++) begin 
                cam_mem[i] <= 32'h0;
                valid[i]   <= 1'b0;
            end
        end else if (write_en) begin
            cam_mem[write_addr] <= write_data;
            valid[write_addr]   <= 1'b1;
        end
    end

    always_comb begin
        for (int i = 0; i < NUM_ENTRIES; i++) begin 
            match_lines[i] = valid[i] && (cam_mem[i] == search_data);
        end
    end


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

