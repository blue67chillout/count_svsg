// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

module user_proj_example #(
    parameter   [31:0]  NUM    = 32'h3000_0000
    ) (
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif
    input wire          clk,
    input wire          reset,

    // wishbone slave ports
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output reg wbs_ack_o,
    output [31:0] wbs_dat_o,

    output reg [7:0]svsg,
    output [7:0] io_oeb
   
);
    reg [3:0]BCD;
    wire [3:0]wdata;
    reg [7:0]rdata;
    wire valid ;
    
    assign wdata = wbs_dat_i[3:0];
    assign wbs_dat_o = {{24{1'b0}},svsg};
    assign valid = wbs_cyc_i && wbs_stb_i;
    assign io_oeb = 8'd0;

//wishbone write

    always @(posedge clk ) begin
        if(reset) begin
          wbs_ack_o <=0;
            end
        else begin 
            wbs_ack_o <=0;
            if(valid && wbs_we_i && !wbs_ack_o && (wbs_adr_i == NUM)) begin
            wbs_ack_o <=1;
            BCD <= wdata[3:0];
            end
        end
    end

// wishbone read

    always@(posedge clk) begin
        if (reset) begin
            wbs_ack_o <=0;
        end
        else begin
        
        if ( !wbs_we_i && wbs_cyc_i && wbs_stb_i && (wbs_adr_i == NUM) ) begin
            wbs_ack_o <=1;
            rdata <= svsg;
            
        end
        end
    end
    always@(posedge clk) begin
        if(reset) begin
            svsg <= 8'h00;
        end

        else begin
            case (BCD)
                4'b0000:svsg<=8'b11111100;
                4'b0001:svsg<=8'b01100000;
                4'b0010:svsg<=8'b11011010;
                4'b0011:svsg<=8'b11110010;
                4'b0100:svsg<=8'b01100110;
                4'b0101:svsg<=8'b10110110;
                4'b0110:svsg<=8'b10111110;
                4'b0111:svsg<=8'b11100000;
                4'b1000:svsg<=8'b11111110;
                4'b1001:svsg<=8'b11110110;

                default:svsg<=8'b00000000;

               
            endcase
        end
    end


 /*  always@(posedge clk) begin
        if(reset) begin
            wbs_ack_o = 0;
        end
        else if(wbs_stb_i && wbs_cyc_i &&  (wbs_adr_i == NUM  )) begin
            wbs_ack_o = 1;
        end
    end*/

    
endmodule

`default_nettype wire
