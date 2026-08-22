# ============================================================
# Makefile for bootloader.mem
# SDカードからのOSブート
# ============================================================

firmware_fat32:
	$(MAKE) -C ../../software/os fpga_mem
	$(MAKE) -C ../../software/os fpga_fat32_boot
	$(MAKE) -C ../../software/os disasm
	$(MAKE) -C ../../software/os disasm_bootloader_fat32
	mkdir -p ./mem
	mkdir -p ./S_file

	cp ../../software/os/build/bootrom.mem    		./mem/
	cp ../../software/os/build/kernel.mem     		./mem/
	cp ../../software/os/build/user.mem       		./mem/
	cp ../../software/os/build/bootloader_fat32.mem ./mem/

	@tmp=$$(mktemp); \
	head -n 4500 ./mem/bootloader.mem > $$tmp; \
	mv $$tmp ./mem/bootloader.mem

	cp ../../software/os/build/bootrom.S 			./S_file/
	cp ../../software/os/build/kernel.S 			./S_file/
	cp ../../software/os/build/bootloader_fat32.S 	./S_file/

	$(MAKE) -C ../../software/os clean

clean:
	$(RM) -rf ./mem/*.mem
