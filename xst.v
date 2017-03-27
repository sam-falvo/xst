`timescale 1ns / 1ps

module xst(
	input		clk_i,
	input		reset_i,

	input		rxd_i,
	input	[63:0]	dat_i,

	input		txreg_we_i,
	input	[15:0]	txbaud_i,
	input	[5:0]	bits_i,

	output		txd_o,
	output		txc_o,
	output		idle_o,
	output	[15:0]	brg_o,
	output	[5:0]	bits_o
	
);
	reg	[5:0]	bits_o;
	reg	[15:0]	brg_o;
	reg	[63:0]	shift_register;
	reg		txc_o;

	assign		txd_o = shift_register[0];
	assign		idle_o = ~|bits_o;

	wire		txreg_shift = ~|brg_o;
	wire	[15:1]	halfbit = txbaud_i[15:1];

	always @(posedge clk_i) begin
		shift_register <= shift_register;
		brg_o <= brg_o;
		txc_o <= txc_o;
		bits_o <= bits_o;

		if(reset_i) begin
			shift_register <= ~(64'd0);
			brg_o <= 0;
			txc_o <= 0;
			bits_o <= 0;
		end

		else if(txreg_we_i) begin
			brg_o <= txbaud_i;
			txc_o <= 1;
			shift_register <= dat_i;
			bits_o <= bits_i;
		end

		else begin
			if(txreg_shift & ~idle_o) begin
				brg_o <= txbaud_i;
				txc_o <= (bits_o != 6'd1);
				shift_register <= {rxd_i, shift_register[63:1]};
				bits_o <= bits_o - 1;
			end
			else if(~txreg_shift & ~idle_o) begin
				brg_o <= brg_o - 1;
			end
		end

		if(brg_o == {1'b0, halfbit}) begin
			txc_o <= 0;
		end
	end
endmodule
