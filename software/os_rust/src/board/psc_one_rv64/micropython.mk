# RV64 GC register spill helper; the upstream NLR code already selects RV64.
$(BUILD)/shared/runtime/gchelper_rv64i.o: $(TOP)/shared/runtime/gchelper_rv64i.s
	$(CC) $(CFLAGS) -c $< -o $@
