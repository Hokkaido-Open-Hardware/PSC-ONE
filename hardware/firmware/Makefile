# ============================================================
# Makefile for kernel.mem, user.mem
# SDカードからのOSブート
# kernel.mem, user.memをSDカードのルートフォルダにコピーしてください
# ============================================================

firmware_fat32:
	$(MAKE) -C ../../software/os clean
	$(MAKE) -C ../../software/os fpga_mem
	$(MAKE) -C ../../software/os disasm
	mkdir -p ./mem
	mkdir -p ./S_file

	cp ../../software/os/build/kernel.mem     		./mem/
	cp ../../software/os/build/user.mem       		./mem/
	cp ../../software/os/build/kernel.S 			./S_file/

clean:
	$(RM) -rf ./mem/*.mem
