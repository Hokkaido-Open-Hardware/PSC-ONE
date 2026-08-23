
# ============================================================
# Makefile for bootloader.mem
# SDカードからのOSブート

bootloader:
	$(MAKE) -C ../../software/os fpga_mem
	$(MAKE) -C ../../software/os fpga_boot
	$(MAKE) -C ../../software/os disasm
	$(MAKE) -C ../../software/os disasm_bootloader
	mkdir -p ./mem
	mkdir -p ./S_file

	cp ../../software/os/build/bootrom.mem    ./mem/
	cp ../../software/os/build/kernel.mem     ./mem/
	cp ../../software/os/build/user.mem       ./mem/
	cp ../../software/os/build/bootloader.mem ./mem/

	@tmp=$$(mktemp); \
	head -n 4500 ./mem/bootloader.mem > $$tmp; \
	mv $$tmp ./mem/bootloader.mem

	cp ../../software/os/build/bootrom.S 	./S_file/
	cp ../../software/os/build/kernel.S 	./S_file/
	cp ../../software/os/build/shell.S 		./S_file/
	cp ../../software/os/build/bootloader.S ./S_file/

	$(MAKE) -C ../../software/os clean

# ============================================================
# Makefile for bootloader.mem
# SDカードからのOSブート

bootloader_fat32:
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

# ============================================================
# SDカード用 .img ファイル生成
# ============================================================
SD_IMG_DIR = ./sd_img

sd_imgfile:
	python ./python/sdcard_mem_to_img.py ./mem/user.mem -o $(SD_IMG_DIR)/user.img
	python ./python/sdcard_mem_to_img.py ./mem/kernel.mem -o $(SD_IMG_DIR)/kernel.img

# .img file dump
dump_userimg:
	hexdump -C $(SD_IMG_DIR)/user.img

dump_kernelimg:
	hexdump -C $(SD_IMG_DIR)/kernel.img

check_sd_card:
	lsblk

check_kernel_size:
	@awk '$$0!="00000000"{last=NR; val=$$0} \
	END{ \
	    printf("last_nonzero_line=%d value=%s\n", last, val); \
	    printf("size=%d bytes\n", last*4); \
	    printf("sectors=%d\n", (last*4+511)/512); \
	}' ./mem/kernel.mem

check_user_size:
	@awk '$$0!="00000000"{last=NR; val=$$0} \
	END{ \
	    printf("last_nonzero_line=%d value=%s\n", last, val); \
	    printf("size=%d bytes\n", last*4); \
	    printf("sectors=%d\n", (last*4+511)/512); \
	}' ./mem/user.mem

write_img_to_sd_card: sd_imgfile
	@echo "=== SDカード書き込み ==="
	@lsblk
	@echo ""
	@echo "ターゲットは /dev/sdc で本当にOK？"
	@read -p "YES と入力しないと中止: " ans; \
	if [ "$$ans" != "YES" ]; then \
		echo "中止しました"; \
		exit 1; \
	fi

	@echo "=== アンマウント ==="
	sudo umount /dev/sdc1 || true

	@echo "=== 書き込み ==="
	sudo dd if=$(SD_IMG_DIR)/kernel.img of=/dev/sdc bs=512 seek=100 conv=fsync status=progress
	sudo dd if=$(SD_IMG_DIR)/user.img of=/dev/sdc bs=512 seek=300 conv=fsync status=progress

	@echo "=== sync ==="
	sync

	@echo "=== 検証 ==="
	sudo dd if=/dev/sdc bs=512 skip=100 count=2 | xxd | head
	sudo dd if=/dev/sdc bs=512 skip=300 count=2 | xxd | head

	@echo "=== 完了 ==="

clean:
	$(RM) -rf ./mem/bootloader.mem
