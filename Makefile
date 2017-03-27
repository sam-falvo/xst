waves:
	iverilog -s xst_tb *.v && vvp -n a.out && gtkwave wtf.vcd

