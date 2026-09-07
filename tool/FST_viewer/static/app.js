"use strict";

const state = { meta: null, start: 0, count: 70, cellWidth: 72, selected: null,
  category: "ALL", data: null, instructionMap: {}, requestSerial: 0, selectedStage: 1 };
let rows = [];
const colors = { ALU: "#27759b", MUL: "#6f55a8", DIV: "#9b4f76", LOAD: "#257c63",
  STORE: "#286e58", BRANCH: "#91662f", JUMP: "#8e612c", CSR: "#82772e",
  SYSTEM: "#59697d", OTHER: "#46566a" };
const $ = id => document.getElementById(id);
const hex = (v, width=8) => v == null ? "—" : `0x${Number(v).toString(16).padStart(width,"0")}`;
const bit = v => v == null ? "—" : String(v);
const fmt = n => Number(n).toLocaleString();
const timeNs = fs => `${(fs / 1e6).toLocaleString(undefined,{maximumFractionDigits:3})} ns`;

async function api(path) {
  const response = await fetch(path);
  if (!response.ok) throw new Error(`${response.status} ${response.statusText}`);
  return response.json();
}

function toast(message) {
  const el = $("toast"); el.textContent = message; el.classList.add("show");
  clearTimeout(toast.timer); toast.timer = setTimeout(() => el.classList.remove("show"), 1700);
}

async function initialize() {
  try {
    state.meta = await api("/api/meta");
    rows = ["FETCH / DECODE", ...state.meta.stage_names];
    $("cpuType").textContent = `CPU: PSC_RV32 ${state.meta.cpu}`;
    $("modelName").textContent = state.meta.display_model;
    const height = 38 + rows.length*56 + 12;
    document.querySelector(".canvas-shell").style.height = `${height}px`;
    $("timelineCanvas").style.height = `${height}px`;
    $("sourceName").textContent = state.meta.source;
    $("metricCycles").textContent = fmt(state.meta.cycles);
    $("metricInstructions").textContent = fmt(state.meta.instructions);
    $("metricRetired").textContent = fmt(state.meta.retired);
    $("scrubber").max = Math.max(0, state.meta.cycles - 1);
    state.start = state.meta.first_activity;
    state.selected = state.start;
    buildLabels(); bindEvents(); resize();
    await loadRange(); await selectCycle(state.selected);
  } catch (error) {
    document.body.innerHTML = `<pre style="padding:30px;color:#ef6c79">Viewer error: ${error.message}</pre>`;
  }
}

function buildLabels() {
  const host = $("rowLabels"); host.innerHTML = "";
  rows.forEach((name,index) => { const el=document.createElement("div"); el.className="row-label";
    el.style.top=`${index===0?38:38+index*56}px`; el.style.height="56px"; el.textContent=name; host.appendChild(el); });
}

function visibleCount() {
  const width = $("timelineCanvas").getBoundingClientRect().width || 900;
  return Math.max(6, Math.min(180, Math.ceil(width / state.cellWidth) + 1));
}

function resize() {
  const canvas = $("timelineCanvas"), rect = canvas.getBoundingClientRect(), dpr = devicePixelRatio || 1;
  canvas.width = Math.floor(rect.width*dpr); canvas.height=Math.floor(rect.height*dpr);
  const ctx=canvas.getContext("2d"); ctx.setTransform(dpr,0,0,dpr,0,0);
  state.count=visibleCount(); if(state.data) draw();
}

async function loadRange() {
  if (!state.meta) return;
  state.start=Math.max(0,Math.min(state.start,Math.max(0,state.meta.cycles-state.count)));
  const serial=++state.requestSerial;
  const data=await api(`/api/cycles?start=${state.start}&count=${state.count}&category=${state.category}`);
  if(serial!==state.requestSerial) return;
  state.data=data; state.instructionMap=data.instructions;
  $("scrubber").value=state.start; $("rangeStart").textContent=fmt(data.start);
  $("rangeEnd").textContent=fmt(Math.max(data.start,data.end-1));
  $("cycleJump").value=state.selected ?? state.start;
  draw(); await loadLedger();
}

function rounded(ctx,x,y,w,h,r=4) {
  w=Math.max(w,1); r=Math.min(r,w/2,h/2); ctx.beginPath(); ctx.roundRect(x,y,w,h,r);
}

function draw() {
  const canvas=$("timelineCanvas"), ctx=canvas.getContext("2d"), width=canvas.clientWidth, height=canvas.clientHeight;
  ctx.clearRect(0,0,width,height); ctx.fillStyle="#0c1118"; ctx.fillRect(0,0,width,height);
  if(!state.data) return;
  ctx.font="9px JetBrains Mono, Consolas, monospace"; ctx.textBaseline="middle";
  state.data.cycles.forEach((cycle,i)=>{
    const x=i*state.cellWidth;
    ctx.strokeStyle="#202a37"; ctx.lineWidth=1; ctx.beginPath(); ctx.moveTo(x+.5,0); ctx.lineTo(x+.5,height); ctx.stroke();
    ctx.fillStyle="#738297"; ctx.fillText(String(cycle.cycle),x+6,13);
    ctx.fillStyle="#46576b"; ctx.font="8px JetBrains Mono, Consolas, monospace"; ctx.fillText(cycle.cpu_state,x+6,28);
    ctx.font="9px JetBrains Mono, Consolas, monospace";
    if(cycle.cycle===state.selected){ctx.fillStyle="rgba(85,194,255,.08)";ctx.fillRect(x,0,state.cellWidth,height);ctx.fillStyle="#55c2ff";ctx.fillRect(x,0,2,height);}
  });
  for(let r=0;r<rows.length;r++){const y=38+r*56;ctx.strokeStyle="#1d2632";ctx.beginPath();ctx.moveTo(0,y+.5);ctx.lineTo(width,y+.5);ctx.stroke();}
  drawFetch(ctx);
  for(let stage=0;stage<state.meta.stage_names.length;stage++) drawStage(ctx,stage);
  drawFlags(ctx);
}

function drawFetch(ctx) {
  let i=0;
  while(i<state.data.cycles.length){const item=state.data.cycles[i].fetch;if(!item){i++;continue;}
    let j=i+1;while(j<state.data.cycles.length){const n=state.data.cycles[j].fetch;if(!n||n.pc!==item.pc||n.opcode!==item.opcode)break;j++;}
    paintBar(ctx,i,j,0,item);i=j;}
}

function drawStage(ctx, stage) {
  let i=0; const cycles=state.data.cycles;
  while(i<cycles.length){const id=cycles[i].tokens[stage];if(id==null){i++;continue;}
    let j=i+1;while(j<cycles.length&&cycles[j].tokens[stage]===id)j++;
    const item=state.instructionMap[String(id)]; if(item)paintBar(ctx,i,j,stage+1,item);i=j;}
}

function paintBar(ctx,start,end,row,item) {
  const x=start*state.cellWidth+3,y=38+row*56+7,w=(end-start)*state.cellWidth-6,h=40;
  rounded(ctx,x,y,w,h,4);ctx.fillStyle=colors[item.category]||colors.OTHER;ctx.fill();
  ctx.strokeStyle="rgba(255,255,255,.14)";ctx.stroke();ctx.save();ctx.beginPath();ctx.rect(x+5,y,w-10,h);ctx.clip();
  ctx.fillStyle="#edf5ff";ctx.font="600 10px JetBrains Mono, Consolas, monospace";ctx.fillText(item.mnemonic.toUpperCase(),x+8,y+14);
  ctx.fillStyle="rgba(230,240,250,.68)";ctx.font="8px JetBrains Mono, Consolas, monospace";ctx.fillText(hex(item.pc),x+8,y+29);ctx.restore();
}

function drawFlags(ctx){state.data.cycles.forEach((c,i)=>{const x=i*state.cellWidth+state.cellWidth-7;let y=45;
  [[c.stall,"#ef6c79"],[c.flush,"#e7a85f"],[c.mul_busy,"#a88bea"],[c.div_busy,"#d4699e"]].forEach(([on,color])=>{if(on){ctx.fillStyle=color;ctx.fillRect(x,y,3,8);y+=10;}});});}

async function loadLedger() {
  const serial = (state.ledgerSerial || 0) + 1; state.ledgerSerial = serial;
  const end=state.data?.end??state.start+state.count, q=encodeURIComponent($("instructionSearch").value.trim());
  const list=await api(`/api/instructions?start=${state.start}&end=${end}&category=${state.category}&q=${q}`);
  if(serial !== state.ledgerSerial) return;
  $("ledgerCount").textContent=`${list.length} records`;
  $("instructionRows").innerHTML=list.map(record=>`<tr data-cycle="${record.start}" data-id="${record.id}" class="${record.id===selectedInstructionId()?"selected":""}">
    <td>${hex(record.pc)}</td><td>${hex(record.opcode)}</td><td>${escapeHtml(record.text)}</td>
    <td><span class="cat-pill">${record.category}</span></td><td>${fmt(record.start)}</td><td>${fmt(record.end)}</td><td>${fmt(record.cycles)}</td>
    <td class="${record.status==="retired"?"status-retired":"status-flushed"}">${record.status}</td></tr>`).join("");
  $("instructionRows").querySelectorAll("tr").forEach(row=>row.onclick=()=>{state.selectedStage=0;jump(Number(row.dataset.cycle),true);});
}

function selectedInstructionId(){if(!state.data||state.selected==null)return null;const c=state.data.cycles.find(x=>x.cycle===state.selected);if(!c)return null;return [...c.tokens].reverse().find(x=>x!=null)??null;}
function escapeHtml(text){const d=document.createElement("div");d.textContent=text;return d.innerHTML;}

async function selectCycle(cycle) {
  const serial = (state.detailSerial || 0) + 1; state.detailSerial = serial;
  if(!state.meta)return; state.selected=Math.max(0,Math.min(cycle,state.meta.cycles-1));
  if(state.selected<state.start||state.selected>=state.start+state.count){state.start=Math.max(0,state.selected-Math.floor(state.count/3));await loadRange();}else draw();
  if(serial !== state.detailSerial) return;
  $("cycleJump").value=state.selected; const detail=await api(`/api/cycle/${state.selected}`);
  if(serial !== state.detailSerial) return;
  renderDetail(detail); await loadLedger();
}

function renderDetail(d) {
  $("registerCycle").textContent = `Cycle ${fmt(d.cycle)}`;
  $("registerSource").textContent = `${d.registers.source} · highlighted = changed from previous cycle`;
  $("registerGrid").innerHTML = d.registers.values.map(r =>
    `<div class="register-cell ${r.changed ? "changed" : ""}" data-register="${r.index}"><span>${escapeHtml(r.label)}</span><strong>${hex(r.value)}</strong></div>`).join("");
  $("detailCycle").textContent=`#${fmt(d.cycle)}`;$("detailTime").textContent=`${timeNs(d.time_fs)} · CPU counter ${fmt(d.counter??0)}`;
  const active=d.stages[state.selectedStage]?.instruction ? d.stages[state.selectedStage] : [...d.stages].reverse().find(s=>s.instruction);
  const instruction=active?.instruction;
  const stageHtml=d.stages.map(s=>s.instruction?`<div class="stage-item active"><div class="stage-name">${s.name}</div>${hex(s.pc)} · ${escapeHtml(s.instruction.text)}</div>`:`<div class="stage-item"><div class="stage-name">${s.name}</div>—</div>`).join("");
  const f=d.flow,e=d.execution,m=d.memory;
  $("detailsBody").innerHTML=`
    <div class="detail-hero"><div class="datum"><span>Architectural PC</span><strong>${hex(d.pc)}</strong></div><div class="datum"><span>CPU state</span><strong>${d.cpu_state}</strong></div></div>
    <div class="detail-card"><h3>Selected instruction <em>${active?.name??"FETCH"}</em></h3>
      <div class="instruction-title">${instruction?`${hex(instruction.pc)} : ${hex(instruction.opcode).slice(2)} : ${escapeHtml(instruction.text)}`:"No active instruction"}</div>
      ${active?kvGrid([["rs1",`${active.rs1_label} = ${hex(active.rs1_value)}`],["rs2",`${active.rs2_label} = ${hex(active.rs2_value)}`],["rd",active.rd_label],["ALU result",hex(active.alu_result)],["Writeback",hex(active.writeback_value)],["Branch taken",bit(active.branch_taken)] ]):""}
    </div>
    ${Object.keys(d.profile_detail||{}).length ? `<div class="detail-card"><h3>${escapeHtml(state.meta.display_model)}</h3>${kvGrid(Object.entries(d.profile_detail))}</div>` : ""}
    <div class="detail-card"><h3>Instruction occupancy</h3><div class="stage-stack" style="padding:8px">${stageHtml}</div></div>
    <div class="detail-card"><h3>Execute / multi-cycle FSM <em>${e.state}</em></h3>
      ${kvGrid([["Operand 1",hex(e.operand_1)],["Operand 2",hex(e.operand_2)],["ALU output",hex(e.alu_result)],["Execute done",bit(e.done)],
      ["MUL state",e.mul.state],["MUL busy / result",`${bit(e.mul.busy)} / ${hex(e.mul.result)}`],["DIV state / count",`${e.div.state} / ${e.div.count??"—"}`],["DIV Q / R",`${hex(e.div.quotient)} / ${hex(e.div.remainder)}`]])}
    </div>
    <div class="detail-card"><h3>Memory transactions</h3>${kvGrid([["Load FSM",`${m.load_state} (${bit(m.load_valid)})`],["Store FSM",`${m.store_state} (${bit(m.store_valid)})`],
      ["Virtual / ALU addr",hex(m.virtual_address)],["Read address",hex(m.read_address)],["Read V/R/data",`${bit(m.read_valid)}/${bit(m.read_ready)} · ${hex(m.read_data)}`],["Write address",hex(m.write_address)],["Write V/R/data",`${bit(m.write_valid)}/${bit(m.write_ready)} · ${hex(m.write_data)}`],["Byte select",m.write_select==null?"—":`0b${m.write_select.toString(2).padStart(3,"0")}`]])}</div>
    <div class="detail-card"><h3>Flow control / PC transition</h3>${kvGrid([["Next PC",hex(f.next_pc)],["Branch target",hex(f.branch_target_pc)],["Sequential PC",hex(f.seq_pc)],["Forward rs1 / rs2",`${f.forward_rs1??"—"} / ${f.forward_rs2??"—"}`]])}
      <div class="flag-row">${flags([["DECODE",f.decode_fire],["ISSUE",f.issue_fire],["EX FIRE",f.execute_fire],["MEM FIRE",f.memory_fire],["RAW STALL",f.raw_hazard],["SERIAL",f.backend_serial],["FLUSH",f.fifo_flush],["BRANCH",f.branch_taken],["D-PF",f.data_page_fault],["I-PF",f.instruction_page_fault],["IRQ",f.timer_irq_take]])}</div></div>`;
}

function kvGrid(items){return `<div class="kv-grid">${items.map(([k,v])=>`<div class="kv"><span>${k}</span><strong title="${v??"—"}">${v??"—"}</strong></div>`).join("")}</div>`;}
function flags(items){return items.map(([name,on])=>`<span class="flag ${on===1?"on":""}">${name} ${bit(on)}</span>`).join("");}

async function jump(cycle, select=true){state.start=Math.max(0,cycle-Math.floor(state.count/3));if(select)state.selected=cycle;await loadRange();if(select)await selectCycle(cycle);}
async function search(kind,direction=1){const input=kind==="pc"?$("pcSearch"):$("instructionSearch"),q=input.value.trim();if(!q)return;
  const found=await api(`/api/search?kind=${kind}&q=${encodeURIComponent(q)}&start=${state.selected??state.start}&direction=${direction}`);
  if(found){state.selectedStage=0;await jump(found.start,true);}else toast("No matching instruction");}
async function moveInstruction(direction){const found=await api(`/api/search?kind=any&q=&start=${(state.selected??state.start)+direction}&direction=${direction}`);if(found){state.selectedStage=0;await jump(found.start,true);}else toast("No more instructions");}

function changeZoom(factor){state.cellWidth=Math.max(34,Math.min(150,state.cellWidth*factor));$("zoomLabel").textContent=`${Math.round(state.cellWidth/72*100)}%`;state.count=visibleCount();loadRange();}

function bindEvents(){
  window.addEventListener("resize",()=>{resize();loadRange();});
  $("jumpCycle").onclick=()=>jump(Number($("cycleJump").value),true);$("cycleJump").onkeydown=e=>{if(e.key==="Enter")$("jumpCycle").click();};
  $("prevCycle").onclick=()=>selectCycle((state.selected??state.start)-1);$("nextCycle").onclick=()=>selectCycle((state.selected??state.start)+1);
  $("prevInstruction").onclick=()=>moveInstruction(-1);$("nextInstruction").onclick=()=>moveInstruction(1);
  $("findPc").onclick=()=>search("pc",1);$("findInstruction").onclick=()=>search("mnemonic",1);
  $("pcSearch").onkeydown=e=>{if(e.key==="Enter")search("pc",1)};$("instructionSearch").onkeydown=e=>{if(e.key==="Enter")search("mnemonic",1)};
  $("categoryFilter").onchange=e=>{state.category=e.target.value;loadRange();};
  $("zoomIn").onclick=()=>changeZoom(1.25);$("zoomOut").onclick=()=>changeZoom(.8);
  $("scrubber").oninput=e=>{state.start=Number(e.target.value);loadRange();};
  const canvas=$("timelineCanvas");canvas.onclick=e=>{const rect=canvas.getBoundingClientRect(),i=Math.floor((e.clientX-rect.left)/state.cellWidth);state.selectedStage=Math.max(0,Math.min(state.meta.stage_names.length-1,Math.floor((e.clientY-rect.top-38)/56)-1));selectCycle(state.start+i);};
  canvas.onwheel=e=>{e.preventDefault();if(e.ctrlKey||e.metaKey)changeZoom(e.deltaY<0?1.13:.885);else{state.start+=Math.sign(e.deltaY||e.deltaX)*Math.max(1,Math.floor(state.count/8));loadRange();}};
  document.addEventListener("keydown",e=>{if(["INPUT","SELECT"].includes(document.activeElement.tagName))return;if(e.key==="ArrowLeft"){e.preventDefault();e.shiftKey?moveInstruction(-1):selectCycle((state.selected??state.start)-1);}if(e.key==="ArrowRight"){e.preventDefault();e.shiftKey?moveInstruction(1):selectCycle((state.selected??state.start)+1);}});
}

initialize();
