"""Cocotb regression for sdram_32bit_to_256bit_axi_bridge.

Cache side : 256-bit cache line
AXI side   : 32-bit data, 8-beat INCR burst (LEN=7, SIZE=2)
Beat order : beat0 -> bits[31:0], ... beat7 -> bits[255:224]

Checks pulse requests, I/D round-robin arbitration, read/write packing,
completion routing, and AXI VALID/payload stability under backpressure.
Cache payloads stay stable until completion, matching the actual cache RTL.
AXI signals are sampled before each active clock edge, never after NBA updates.
"""
import random
import cocotb
from cocotb.triggers import Timer


class Bench:
    def __init__(self, dut):
        self.dut = dut
        self.axi_data_bits = len(dut.m_axi_wdata)
        self.cache_line_bits = len(dut.d_write_data)
        assert self.axi_data_bits == 32, (
            f'Expected 32-bit AXI data, got {self.axi_data_bits}'
        )
        assert self.cache_line_bits == 256, (
            f'Expected 256-bit cache line, got {self.cache_line_bits}'
        )
        self.beats = self.cache_line_bits // self.axi_data_bits
        assert self.beats == 8, f'Expected 8 beats, got {self.beats}'
        self.line_bytes = self.cache_line_bits // 8
        self.rng = random.Random(432128)
        self.memory = {}
        self.requests = {}
        self.active = None
        self.order = []
        self.stalled = {}
        self.stalls = dict.fromkeys(('aw', 'w', 'ar', 'r', 'b'), 0)
        self.cycle = 0
        self.backpressure = True
        self.block_address = False
        self.rbeat = None
        self.bvalid = False

    def get(self, name):
        return int(getattr(self.dut, name).value)

    def put(self, name, value):
        getattr(self.dut, name).value = value

    def word(self, address):
        return self.memory.get(address, (address * 0x12345 ^ 0xCAFE1234) & 0xffffffff)

    def request(self, owner, write=False, address=0x1000, data=0):
        assert owner not in self.requests, 'Only one outstanding request per cache'
        assert not write or owner == 'd'
        self.requests[owner] = (write, address & ~(self.line_bytes - 1), data, self.cycle)
        self.put(f'{owner}_{"write" if write else "read"}_valid', 1)
        self.put(f'{owner}_{"write" if write else "read"}_addr', address)
        if write:
            self.put('d_write_data', data)

    async def tick(self, reset=False):
        self.put('clock', 0)
        for ch in ('aw', 'ar', 'w'):
            ready = not (self.block_address and ch in ('aw', 'ar')) and (
                not self.backpressure or self.rng.randrange(4) == 0)
            self.put(f'm_axi_{ch}ready', int(ready))
        if self.active:
            owner, write, address, index = self.active
            if not write and self.rbeat is None:
                if not self.backpressure or self.rng.randrange(3) == 0:
                    self.rbeat = (self.word(address + index * 4), index == self.beats - 1)
                else:
                    self.stalls['r'] += 1
            if write and index == self.beats and not self.bvalid:
                if not self.backpressure or self.rng.randrange(5) == 0:
                    self.bvalid = True
                else:
                    self.stalls['b'] += 1
        self.put('m_axi_rvalid', int(self.rbeat is not None))
        self.put('m_axi_rdata', self.rbeat[0] if self.rbeat else 0)
        self.put('m_axi_rlast', int(self.rbeat[1]) if self.rbeat else 0)
        self.put('m_axi_bvalid', int(self.bvalid))
        await Timer(5, unit='ns')
        finished = None
        if not reset:
            # VALID and every payload bit must survive arbitrary READY stalls.
            for ch, fields in [('aw', ('id', 'addr', 'len', 'size', 'burst')),
                               ('ar', ('id', 'addr', 'len', 'size', 'burst')),
                               ('w', ('data', 'strb', 'last'))]:
                value = tuple(self.get(f'm_axi_{ch}{f}') for f in fields)
                valid = self.get(f'm_axi_{ch}valid')
                ready = self.get(f'm_axi_{ch}ready')
                if ch in self.stalled:
                    assert valid and value == self.stalled[ch], f'{ch} changed under stall'
                if valid and not ready:
                    self.stalled[ch] = value
                    self.stalls[ch] += 1
                else:
                    self.stalled.pop(ch, None)
            for ch in ('aw', 'ar'):
                if self.get(f'm_axi_{ch}valid') and self.get(f'm_axi_{ch}ready'):
                    assert self.active is None, 'More than one AXI transaction outstanding'
                    owner = 'd' if self.get('owner') else 'i'
                    assert owner in self.requests, 'Duplicate/unrequested AXI transaction'
                    write, address, data, _ = self.requests[owner]
                    assert write == (ch == 'aw')
                    assert self.get(f'm_axi_{ch}addr') == address
                    assert self.get(f'm_axi_{ch}len') == self.beats - 1
                    assert self.get(f'm_axi_{ch}size') == 2
                    assert self.get(f'm_axi_{ch}burst') == 1
                    self.active = [owner, write, address, 0]
                    self.order.append(owner)
            if self.active:
                owner, write, address, index = self.active
                assert self.get('owner') == (owner == 'd'), 'Owner changed before completion'
                if write and self.get('m_axi_wvalid') and self.get('m_axi_wready'):
                    assert index < self.beats
                    data = self.get('m_axi_wdata')
                    assert data == (self.requests[owner][2] >> (index * self.axi_data_bits)) & ((1 << self.axi_data_bits) - 1)
                    assert self.get('m_axi_wstrb') == 15
                    assert self.get('m_axi_wlast') == (index == self.beats - 1)
                    self.memory[address + index * 4] = data
                    self.active[3] += 1
                if not write and self.rbeat and self.get('m_axi_rready'):
                    self.rbeat = None
                    self.active[3] += 1
                    if index == self.beats - 1:
                        finished = (owner, False, address)
                if write and self.bvalid and self.get('m_axi_bready'):
                    assert self.active[3] == self.beats
                    self.bvalid = False
                    finished = (owner, True, address)
        self.put('clock', 1)
        await Timer(5, unit='ns')
        self.cycle += 1
        if not reset:
            ready = [self.get('i_read_ready'), self.get('d_read_ready'), self.get('d_write_ready')]
            assert sum(ready) == int(finished is not None), 'Early, missing or misrouted response'
            if finished:
                owner, write, address = finished
                assert ready[0 if owner == 'i' else 2 if write else 1]
                if not write:
                    expected = sum(self.word(address + n * 4) << (self.axi_data_bits * n) for n in range(self.beats))
                    assert self.get(f'{owner}_read_data') == expected, 'Line/beat data mismatch'
                del self.requests[owner]
                self.active = None
            for req in self.requests.values():
                assert self.cycle - req[3] < 500, 'Request lost or starved'
        for name in ('i_read_valid', 'd_read_valid', 'd_write_valid'):
            self.put(name, 0)

    async def drain(self):
        for _ in range(500):
            await self.tick()
            if not self.requests:
                # Includes fence and observes accidental duplicate transactions.
                for _ in range(12):
                    await self.tick()
                return
        assert False, 'Transaction timeout'


@cocotb.test()
async def shared_bridge_regression(dut):
    b = Bench(dut)
    for name in ('clock', 'reset_n', 'i_read_valid', 'd_read_valid', 'd_write_valid',
                 'i_read_addr', 'd_read_addr', 'd_write_addr', 'd_write_data',
                 'm_axi_bid', 'm_axi_bresp', 'm_axi_rid', 'm_axi_rresp'):
        b.put(name, 0)
    for _ in range(3):
        await b.tick(reset=True)
    b.put('reset_n', 1)
    # Direct IDLE capture: no arbitration-only cycle.
    b.request('i', address=0x1003)
    await b.tick()
    assert b.get('m_axi_arvalid') == 1
    await b.drain()
    b.request('d', True, 0x2007, 0xFFEEDDCCBBAA998877665544332211000123456789ABCDEFFEDCBA9876543210)
    await b.drain()
    for owner in ('d', 'i'):
        b.request(owner, address=0x2000)
        await b.drain()

    # Both requests arrive as one-cycle pulses. Loser must survive address stalls.
    b.block_address = True
    b.request('i', address=0x3010)
    b.request('d', address=0x4020)
    await b.tick()
    for _ in range(15):
        await b.tick()
    b.block_address = False
    await b.drain()

    # A request arriving while the other owner is active, in both directions.
    for first, second in [('i', 'd'), ('d', 'i')]:
        b.request(first, write=first == 'd', address=0x5000, data=(1 << (b.beats * 32 - 1)) | 0x87654321)
        await b.tick()
        b.request(second, address=0x6000)
        await b.drain()

    # Saturated I+D, saturated I, saturated D, and alternating access.
    for owners in [('i', 'd'), ('i',), ('d',)]:
        remaining = dict.fromkeys(owners, 40)
        previous_done = set()
        start = len(b.order)
        for cycle in range(10000):
            # Allow the completion pulse to be consumed before a new request.
            for owner in owners:
                if remaining[owner] and owner not in b.requests and owner not in previous_done:
                    n = remaining[owner]
                    b.request(owner, write=owner == 'd' and n % 2 == 0,
                              address=(0x10000 if owner == 'i' else 0x20000) + n * b.line_bytes,
                              data=b.rng.getrandbits(b.beats * 32))
                    remaining[owner] -= 1
            old = set(b.requests)
            await b.tick()
            previous_done = old - set(b.requests)
            if not any(remaining.values()) and not b.requests:
                break
        else:
            assert False, 'Continuous requests did not finish'
        await b.drain()
        if len(owners) == 2:
            order = b.order[start:]
            assert len(order) == 80
            assert all(a != c for a, c in zip(order, order[1:])), 'Round-robin fairness failed'
    b.backpressure = False
    for n in range(20):
        b.request('i' if n % 2 else 'd', address=0x30000 + n * b.line_bytes)
        await b.drain()
    assert all(b.stalls.values()), b.stalls
    dut._log.info('PASS shared bridge: %d transactions; stalls=%s', len(b.order), b.stalls)
