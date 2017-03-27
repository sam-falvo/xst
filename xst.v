`timescale 1ns / 1ps

module xst(
	input		clk_i,
	input		reset_i,

	input		rxd_i,
	input	[63:0]	dat_i,

	input		txreg_we_i,
	input		txregr_we_i,
	input		txreg_oe_i,
	input		txregr_oe_i,
	input	[15:0]	txbaud_i,
	input	[5:0]	bits_i,

	output		txd_o,
	output		txc_o,
	output		idle_o,
	output	[15:0]	brg_o,
	output	[5:0]	bits_o,
	output	[63:0]	dat_o
);
	reg	[5:0]	bits_o;
	reg	[15:0]	brg_o;
	reg	[63:0]	shift_register;
	reg		txc_o;

	assign		txd_o = shift_register[0];
	assign		idle_o = ~|bits_o;

	wire		txreg_shift = ~|brg_o;
	wire	[15:1]	halfbit = txbaud_i[15:1];

	wire	[63:0]	shift_reg_rev = {
				shift_register[0],
				shift_register[1],
				shift_register[2],
				shift_register[3],
				shift_register[4],
				shift_register[5],
				shift_register[6],
				shift_register[7],
				shift_register[8],
				shift_register[9],
				shift_register[10],
				shift_register[11],
				shift_register[12],
				shift_register[13],
				shift_register[14],
				shift_register[15],
				shift_register[16],
				shift_register[17],
				shift_register[18],
				shift_register[19],
				shift_register[20],
				shift_register[21],
				shift_register[22],
				shift_register[23],
				shift_register[24],
				shift_register[25],
				shift_register[26],
				shift_register[27],
				shift_register[28],
				shift_register[29],
				shift_register[30],
				shift_register[31],
				shift_register[32],
				shift_register[33],
				shift_register[34],
				shift_register[35],
				shift_register[36],
				shift_register[37],
				shift_register[38],
				shift_register[39],
				shift_register[40],
				shift_register[41],
				shift_register[42],
				shift_register[43],
				shift_register[44],
				shift_register[45],
				shift_register[46],
				shift_register[47],
				shift_register[48],
				shift_register[49],
				shift_register[50],
				shift_register[51],
				shift_register[52],
				shift_register[53],
				shift_register[54],
				shift_register[55],
				shift_register[56],
				shift_register[57],
				shift_register[58],
				shift_register[59],
				shift_register[60],
				shift_register[61],
				shift_register[62],
				shift_register[63]
			};

	assign		dat_o =
			  (txreg_oe_i ? shift_register : 0)
			| (txregr_oe_i ? shift_reg_rev : 0);

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

		else if(txregr_we_i) begin
			brg_o <= txbaud_i;
			txc_o <= 1;
			shift_register <= {
				dat_i[0], dat_i[1], dat_i[2], dat_i[3],
				dat_i[4], dat_i[5], dat_i[6], dat_i[7],
				dat_i[8], dat_i[9],
				dat_i[10], dat_i[11], dat_i[12], dat_i[13],
				dat_i[14], dat_i[15], dat_i[16], dat_i[17],
				dat_i[18], dat_i[19],
				dat_i[20], dat_i[21], dat_i[22], dat_i[23],
				dat_i[24], dat_i[25], dat_i[26], dat_i[27],
				dat_i[28], dat_i[29],
				dat_i[30], dat_i[31], dat_i[32], dat_i[33],
				dat_i[34], dat_i[35], dat_i[36], dat_i[37],
				dat_i[38], dat_i[39],
				dat_i[40], dat_i[41], dat_i[42], dat_i[43],
				dat_i[44], dat_i[45], dat_i[46], dat_i[47],
				dat_i[48], dat_i[49],
				dat_i[50], dat_i[51], dat_i[52], dat_i[53],
				dat_i[54], dat_i[55], dat_i[56], dat_i[57],
				dat_i[58], dat_i[59],
				dat_i[60], dat_i[61], dat_i[62], dat_i[63]
			};
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

