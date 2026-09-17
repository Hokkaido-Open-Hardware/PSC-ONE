"""End-to-end checks for the shared bridge in CPU and cache regressions."""
from cocotb.triggers import RisingEdge, ReadOnly


class SharedMonitor:
    def __init__(self, top):
        self.top = top
        self.pending = {'i': False, 'd': False}
        self.count = {'i_read': 0, 'd_read': 0, 'd_write': 0}
        self.shared = {'i_read': 0, 'd_read': 0, 'd_write': 0}
        self.collision = 0

    async def run(self):
        t = self.top
        unused = [getattr(t, 'd_axi_' + n) for n in (
            'awid', 'awaddr', 'awlen', 'awsize', 'awburst', 'awvalid',
            'wdata', 'wstrb', 'wlast', 'wvalid', 'bready',
            'arid', 'araddr', 'arlen', 'arsize', 'arburst', 'arvalid', 'rready')]
        assert hasattr(t, 'shared_axi_bridge')
        assert not hasattr(t, 'p_axi_bridge') and not hasattr(t, 'd_axi_bridge')
        while True:
            await RisingEdge(t.clock)
            await ReadOnly()
            if str(t.reset_n.value) != "1":
                self.pending = dict.fromkeys(self.pending, False)
                continue
            assert all(int(s.value) == 0 for s in unused), 'd_axi_* must remain inactive/zero'
            for owner, prefix in [('i', 'p'), ('d', 'd')]:
                if int(getattr(t, prefix + '_mem_valid256').value):
                    assert not self.pending[owner], 'Cache issued a second outstanding request'
                    self.pending[owner] = True
                if int(getattr(t, prefix + '_mem_ready256').value):
                    assert self.pending[owner], 'Unexpected/duplicate cache response'
                    self.pending[owner] = False
                    kind = owner + ('_write' if owner == 'd' and int(t.d_mem_rw256.value) else '_read')
                    self.count[kind] += 1
            assert not (int(t.p_mem_ready256.value) and int(t.d_mem_ready256.value))
            if all(self.pending.values()):
                self.collision += 1
            # Count channel handshakes at the next rising edge, using the signals
            # sampled after this edge (the drivers settle on falling edges).
            # Address VALID rising is enough here: AXI stability is checked in unit tests.
            for channel in ('ar', 'aw'):
                valid = int(getattr(t, 'p_axi_' + channel + 'valid').value)
                old = getattr(self, channel + '_valid', 0)
                if valid and not old:
                    owner = 'd' if int(t.shared_axi_bridge.owner.value) else 'i'
                    kind = owner + ('_write' if channel == 'aw' else '_read')
                    self.shared[kind] += 1
                setattr(self, channel + '_valid', valid)

    def check(self, require_write=True):
        for key in self.count:
            if key != 'd_write' or require_write:
                assert self.count[key] > 0, f'No {key} coverage'
                assert self.shared[key] >= self.count[key], f'{key} bypassed shared AXI'
        self.top._log.info('PASS shared integration: completed=%s AXI=%s contention_cycles=%d',
                           self.count, self.shared, self.collision)
