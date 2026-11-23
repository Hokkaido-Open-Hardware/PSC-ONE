# ============================================================
# Makefile for kernel.mem, user.mem
# SDカードからのOSブート
# kernel.mem, user.memをSDカードのルートフォルダにコピーしてください
# ============================================================

.PHONY: firmware_fat32 firmware_fat32_tang138k

# Tang 20K SD firmware.
firmware_fat32:
	$(MAKE) -C ../../software/os clean
	$(MAKE) -C ../../software/os fpga_mem
	mkdir -p ./mem
	mkdir -p ./S_file

	cp ../../software/os/build/kernel.mem     		./mem/
	cp ../../software/os/build/user.mem       		./mem/

#$(MAKE) -C ../../software/os disasm
#cp ../../software/os/build/kernel.S 			./S_file/

# Tang Mega 138K SD firmware with HDMI VRAM support.
firmware_fat32_tang138k:
	$(MAKE) -C ../../software/os BOARD=psc_one_tang138k Build=./build/tang138k fpga_mem
	mkdir -p ./mem/tang138k
	cp ../../software/os/build/tang138k/kernel.mem ../../software/os/build/tang138k/user.mem ./mem/tang138k/

clean:
	$(RM) -rf ./mem/
