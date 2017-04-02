xsr.waves:
	iverilog -s xsr_tb *.v && vvp -n a.out && gtkwave wtf.vcd

xst.waves:
	iverilog -s xst_tb *.v && vvp -n a.out && gtkwave wtf.vcd

