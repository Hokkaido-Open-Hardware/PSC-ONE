# Clean intermediate files
clean:
	$(RM) -rf sim_build 
	$(RM) -rf ./cocotb_tb/ai/__pycache__
	$(RM) -rf ./cocotb_tb/cache/__pycache__
	$(RM) -rf ./cocotb_tb/mmio/__pycache__
	$(RM) -rf ./cocotb_tb/cpu/__pycache__
	$(RM) -rf ./cocotb_tb/psc_os/__pycache__
	$(RM) -rf ./parallel_run
	$(RM) -rf ./wave/*.fst.hier
	$(RM) sim.vvp results.xml ./dump.fst ./dump.fst.hier
	$(RM) -rf ./wave/*.vcd
	$(RM) -rf ./wave/*.fst
	$(MAKE) -f Makefile.riscv clean

log_clean:
	$(RM) ./log/test*.log
	$(RM) ./log_uart/log*.log

mem_clean:
	$(RM) ./mem/*.mem
