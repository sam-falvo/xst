`timescale 1ns / 1ps

module xst_tb(
);
	reg	[15:0]	story;
	reg		clk_i = 0, reset_i = 0;
	reg		txreg_oe_i = 0, txreg_we_i = 0;
	reg	[63:0]	dat_i;

	wire		txd_o, idle_o;
	wire	[15:0]	brg_o;

	xst x(
		.clk_i(clk_i),
		.reset_i(reset_i),

		.rxd_i(1'b1),
		.dat_i(dat_i),

		.bits_i(6'd11),
		.txreg_we_i(txreg_we_i),
		.txbaud_i(16'h0004),
		.txd_o(txd_o),
		.idle_o(idle_o),
		.brg_o(brg_o)
	);

	always begin
		#10 clk_i <= ~clk_i;
	end

	task assert_idle;
	input expected;
	begin
		if (expected !== idle_o) begin
			$display("@E %d idle_o Expected %d; got %d", story, expected, idle_o);
			$stop;
		end
	end
	endtask

	task assert_txd;
	input expected;
	begin
		if (expected !== txd_o) begin
			$display("@E %d txd_o Expected %d; got %d", story, expected, txd_o);
			$stop;
		end
	end
	endtask

	task assert_brg;
	input [15:0] expected;
	begin
		if (expected !== brg_o) begin
			$display("@E %d brg_o Expected %d; got %d", story, expected, brg_o);
			$stop;
		end
	end
	endtask

	task test_bitcell;
	input expected_txd;
	begin
		wait(~clk_i); wait(clk_i); #1 assert_txd(expected_txd); assert_idle(0); assert_brg(4);
		wait(~clk_i); wait(clk_i); #1 assert_txd(expected_txd); assert_idle(0); assert_brg(3);
		wait(~clk_i); wait(clk_i); #1 assert_txd(expected_txd); assert_idle(0); assert_brg(2);
		wait(~clk_i); wait(clk_i); #1 assert_txd(expected_txd); assert_idle(0); assert_brg(1);
		wait(~clk_i); wait(clk_i); #1 assert_txd(expected_txd); assert_idle(0); assert_brg(0);
	end
	endtask

	initial begin
		$dumpfile("wtf.vcd");
		$dumpvars;

		wait(clk_i);

		reset_i <= 1;
		story <= 1;

		wait(~clk_i); wait(clk_i);

		reset_i <= 0;
		
		wait(~clk_i); wait(clk_i); assert_idle(1);

		dat_i <= 64'b11111111111111111111111111111111111111111111111111111_11_00010001_0;
							//			   || \______/ |
							// Stop bit ---------------'|     |    |
							// Odd Parity --------------'     |    |
							// Data (0x11) -------------------'    |
							// Start Bit --------------------------'
		txreg_we_i <= 1;
		wait(~clk_i); wait(clk_i); #1 assert_txd(0); assert_idle(0); assert_brg(4);
		txreg_we_i <= 0;
		wait(~clk_i); wait(clk_i); #1 assert_txd(0); assert_idle(0); assert_brg(3);
		wait(~clk_i); wait(clk_i); #1 assert_txd(0); assert_idle(0); assert_brg(2);
		wait(~clk_i); wait(clk_i); #1 assert_txd(0); assert_idle(0); assert_brg(1);
		wait(~clk_i); wait(clk_i); #1 assert_txd(0); assert_idle(0); assert_brg(0);

		test_bitcell(1);
		test_bitcell(0);
		test_bitcell(0);
		test_bitcell(0);
		test_bitcell(1);
		test_bitcell(0);
		test_bitcell(0);
		test_bitcell(0);

		test_bitcell(1);
		test_bitcell(1);

		story <= 2;
		wait(~clk_i); wait(clk_i); #1
		assert_idle(1);

		$display("@I Done.");
		$stop;
	end
endmodule

