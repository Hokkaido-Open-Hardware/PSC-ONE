"""Optional browser validation (requires websockets and Chrome debug port 9224).

First run validate_traces.py --serve and a headless Chrome with
--remote-debugging-port=9224. Runtime viewer has no websockets dependency.
"""
import asyncio
import base64
import json
from pathlib import Path
from urllib.request import urlopen
import websockets


async def main():
    tabs = json.load(urlopen('http://127.0.0.1:9224/json'))
    tab = next(t for t in tabs if t['type'] == 'page')
    async with websockets.connect(tab['webSocketDebuggerUrl'], max_size=16*1024*1024) as ws:
        serial = 0
        errors = []

        async def call(method, params=None):
            nonlocal serial
            serial += 1
            ident = serial
            await ws.send(json.dumps(dict(id=ident, method=method, params=params or {})))
            while True:
                message = json.loads(await ws.recv())
                if message.get('method') == 'Runtime.exceptionThrown':
                    errors.append(message)
                if message.get('id') == ident:
                    assert 'error' not in message, message
                    return message.get('result', {})

        async def evaluate(expression):
            r = await call('Runtime.evaluate', dict(expression=expression, awaitPromise=True, returnByValue=True))
            assert 'exceptionDetails' not in r, r
            return r.get('result', {}).get('value')

        async def wait_until(expression):
            for _ in range(100):
                if await evaluate(expression): return
                await asyncio.sleep(.1)
            raise AssertionError(expression)

        await call('Runtime.enable')
        await call('Page.enable')
        for cpu, port in [('legacy',8000),('v1',8001),('v2',8002)]:
            await call('Page.navigate', {'url':f'http://127.0.0.1:{port}/'})
            await wait_until("document.getElementById('cpuType')?.textContent === 'CPU: PSC_RV32 " + cpu + "' && !!document.querySelector('#instructionRows tr')")
            assert await evaluate("document.querySelectorAll('.row-label').length === state.meta.stage_names.length + 1")
            await wait_until("document.querySelectorAll('.register-cell').length === 32")
            assert await evaluate("document.querySelector('[data-register=\"0\"] strong').textContent === '0x00000000'")
            await evaluate("$('instructionSearch').value='mul'; $('findInstruction').click()")
            await wait_until("document.querySelector('.instruction-title')?.textContent.includes('mul ')")
            selected = await evaluate('state.selected')
            await evaluate("$('nextCycle').click()")
            await wait_until(f"state.selected === {selected+1} && $('detailCycle').textContent === '#' + fmt({selected+1})")
            assert await evaluate(f"$('registerCycle').textContent === 'Cycle ' + fmt({selected+1})")
            await evaluate("$('prevCycle').click()")
            await wait_until(f"state.selected === {selected} && $('detailCycle').textContent === '#' + fmt({selected})")
            await evaluate("$('zoomOut').click()")
            await wait_until("$('zoomLabel').textContent === '80%'")
            await evaluate("$('categoryFilter').value='MUL'; $('categoryFilter').dispatchEvent(new Event('change'))")
            await wait_until("state.category === 'MUL' && Object.values(state.data.instructions).every(x=>x.category==='MUL')")
            await evaluate("$('instructionSearch').value=''; $('pcSearch').value='0x88'; $('findPc').click()")
            await wait_until("document.querySelector('.instruction-title')?.textContent.includes('0x00000088')")
            # Exercise the actual canvas click handler and inspector stage selection.
            await evaluate("(() => { const c=$('timelineCanvas'),r=c.getBoundingClientRect();c.dispatchEvent(new MouseEvent('click',{clientX:r.left+10,clientY:r.top+110})); })()")
            await wait_until("$('detailCycle').textContent === '#' + fmt(state.selected)")
            assert not errors, errors
            await evaluate("$('registerGrid').scrollIntoView({block:'end'})")
            assert await evaluate("$('registerGrid').getBoundingClientRect().bottom <= innerHeight + 1")
            await evaluate("window.scrollTo(0,0); new Promise(r=>requestAnimationFrame(()=>requestAnimationFrame(r)))")
            shot = await call('Page.captureScreenshot', {'format':'png','captureBeyondViewport':True})
            (Path(__file__).parent/'validation'/f'{cpu}-gui.png').write_bytes(base64.b64decode(shot['data']))
            print(f'{cpu}: GUI load / CPU rows / MUL search / PC search / cycle navigation / filter / zoom / canvas inspector / 32 registers PASS',flush=True)
        await call('Browser.close')


if __name__ == '__main__':
    asyncio.run(main())
