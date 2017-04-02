`timescale 1ns / 1ps

module xsr_tb();
	reg	[15:0]	story;
	reg		clk_i = 0, reset_i = 0;
	reg		rxd_i = 1, rxc_i = 0;

	wire		idle_o;

	wire	[63:0]	sr_to;
	wire		sample_to;

	xsr x(
		.clk_i(clk_i),
		.reset_i(reset_i),

		.bits_i(6'd11),			// 8O1
		.baud_i(64'd49),		// 1Mbps when clocked at 50MHz.
		.rxd_i(rxd_i),
		.rxc_i(rxc_i),

		.idle_o(idle_o),

		.sr_to(sr_to),
		.sample_to(sample_to)
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

	task assert_sr;
	input [63:0] expected;
	begin
//		if (expected !== sr_to) begin
//			$display("@E %d sr_to Expected %d; got %d", story, expected, sr_to);
//			$stop;
//		end
	end
	endtask

	initial begin
		$dumpfile("wtf.vcd");
		$dumpvars;

		story <= 1;
		reset_i <= 1;

		wait(clk_i); wait(~clk_i);

		reset_i <= 0;

		assert_idle(1);
		assert_sr(64'hFFFFFFFFFFFFFFFF);
		
		rxd_i <= 0; #1000; assert_sr({1'b0, ~(63'h0)});
		rxd_i <= 1; #1000; assert_sr({2'b10, ~(62'h0)});
		rxd_i <= 0; #1000; assert_sr({3'b010, ~(61'h0)});
		rxd_i <= 1; #1000; assert_sr({4'b1010, ~(60'h0)});
		rxd_i <= 0; #1000; assert_sr({5'b01010, ~(59'h0)});
		rxd_i <= 0; #1000; assert_sr({6'b001010, ~(58'h0)});
		rxd_i <= 0; #1000; assert_sr({7'b0001010, ~(57'h0)});
		rxd_i <= 0; #1000; assert_sr({8'b00001010, ~(56'h0)});
		rxd_i <= 1; #1000; assert_sr({9'b100001010, ~(55'h0)});
		rxd_i <= 0; #1000; assert_sr({10'b0100001010, ~(54'h0)});
		rxd_i <= 1; #2500; assert_sr({11'b10100001010, ~(53'h0)});
		rxd_i <= 0; #1000; assert_sr({12'b010100001010, ~(52'h0)});

		$display("@I Done.");
		$stop;
	end
endmodule
