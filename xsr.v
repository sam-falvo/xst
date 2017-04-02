module xsr(
	input		clk_i,
	input		reset_i,

	input	[5:0]	bits_i,
	input	[63:0]	baud_i,
	input		rxd_i,
	input		rxc_i,

	output		idle_o,
	output	[63:0]	sr_to,
	output		sample_to
);
	reg	[63:0]	sampleCtr;
	reg	[5:0]	bitsLeft;
	reg		d0, d1;

	assign sample_to = sampleCtr == 0;

	always @(posedge clk_i) begin
		bitsLeft <= bitsLeft;
		sampleCtr <= sampleCtr;
		d1 <= d0;
		d0 <= rxd_i;

		if(reset_i) begin
			bitsLeft <= 0;
			sampleCtr <= 0;
			d0 <= 1;
			d1 <= 1;
		end

		else begin
			if(d0 ^ d1) begin
				if(idle_o) begin
					bitsLeft <= bits_i;
				end
				sampleCtr <= {1'b0, baud_i[63:1]};
			end
			else if(~idle_o && (sampleCtr == 0)) begin
				sampleCtr <= baud_i;
				bitsLeft <= bitsLeft - 1;
			end
			else if(idle_o) begin
				sampleCtr <= baud_i;
			end
			else begin
				sampleCtr <= sampleCtr - 1;
			end
		end
	end

	assign idle_o = (bitsLeft == 0);
	assign sr_to = 64'hFFFFFFFFFFFFFFFF;
endmodule
