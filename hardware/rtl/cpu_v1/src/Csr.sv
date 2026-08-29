`timescale 1ns / 1ps
module Csr (
    input  logic             clock,
    input  logic             reset_n,
    input  logic             csr_enb,
    input  logic             csr_valid,

    // ==== from pipeline (CSR ops) ====
    input  logic             csr_wr,              // CSRRW/CSRRS/CSRRC (*I含む)
    input  logic [1:0]       csr_cmd,             // 0:RW, 1:RS(OR), 2:RC(ANDN)
    input  logic             csr_use_imm,         // *I (zimm)
    input  logic [11:0]      csr_addr,            // CSR address
    input  logic [11:0]      csr_read_addr,       // pipelined read address
    input  logic [31:0]      csr_old_value,       // old value captured before commit
    input  logic [31:0]      csr_rs1_val,         // rs1 value
    input  logic [4:0]       csr_zimm,            // zimm (0..31)
    output logic  [31:0]     csr_rdata,           // old value to rd

    // ==== Supervisor trap in/out ====
    input  logic             set_trap,
    input  logic [31:0]      trap_sepc,
    input  logic [31:0]      trap_scause,
    input  logic [31:0]      trap_stval,
    input  logic             do_sret,

    // ==== Machine trap in/out ====
    input  logic             set_mtrap,           // TBD
    input  logic [31:0]      trap_mepc,
    input  logic [31:0]      trap_mcause,
    input  logic             do_mret,

    // ==== mip (pending) ====
    input  logic             set_msip,
    input  logic             clr_msip,
    input  logic             set_mtip,
    input  logic             clr_mtip,
    input  logic             set_meip,
    input  logic             clr_meip,

    // ==== current privilege mode ====
    output logic [1:0]        priv_mode,

    // ==== observes (not used by the CPP test, but kept) ====
    output logic [31:0]       out_mstatus,
    output logic [31:0]       out_medeleg,
    output logic [31:0]       out_mie,
    output logic [31:0]       out_mip,
    output logic [31:0]       out_mtvec,
    output logic [31:0]       out_mepc,
    output logic [31:0]       out_mcause,

    output logic [31:0]       out_sstatus,
    output logic [31:0]       out_stvec,
    output logic [31:0]       out_sepc,
    output logic [31:0]       out_scause,
    output logic [31:0]       out_stval,
    output logic [31:0]       out_satp,

    // to Data-Cache
    output logic [31:0]       out_DCACHE_CTRL,

    // to DMA
    output logic [31:0]       out_DMA_CTRL,
    output logic [31:0]       out_DMA_WORDS,
    output logic [31:0]       out_DMA_SRC,
    output logic [31:0]       out_DMA_DST,
    input  logic [31:0]       in_DMA_STATUS,

    // to SynapEngine
    output logic [31:0]       out_SA_CTRL,
    output logic [31:0]       out_SA_MODE,
    input  logic [31:0]       in_SA_STATUS,
    output logic [31:0]       out_SA_ADDR_A,
    output logic [31:0]       out_SA_ADDR_B,
    output logic [31:0]       out_SA_ADDR_C,

    // to CPU Monitor
    output logic [31:0]       out_CPU_MON_CTRL,
    input  logic [31:0]       in_CPU_MON_CYCLE
);
    // SA ADDRESS (TBD)
    localparam logic [31:0]  SA_ADDR_A = 32'h0002_0000;
    localparam logic [31:0]  SA_ADDR_B = 32'h0002_0010;
    localparam logic [31:0]  SA_ADDR_C = 32'h0002_0020;

    // Privilege level encoding (RISC-V spec)
    localparam logic [1:0] PRIV_U = 2'b00;
    localparam logic [1:0] PRIV_S = 2'b01;
    localparam logic [1:0] PRIV_M = 2'b11;

    // ---------------- Machine CSRs ----------------
    logic  [31:0] csr_mstatus;
    logic  [31:0] csr_medeleg;
    localparam logic [31:0] CSR_MISA = 32'h4014_0100; // RV32 + I,S,U
    logic  [31:0] csr_mie;
    logic  [31:0] csr_mip;
    logic  [31:0] csr_mtvec;
    logic  [31:0] csr_mscratch;
    logic  [31:0] csr_mepc;
    logic  [31:0] csr_mcause;
    logic  [31:0] csr_mtval;

    // ---------------- Supervisor CSRs ----------------
    logic  [31:0] csr_sstatus;   // ★独立CSR（SIE=bit1 等）
    logic  [31:0] csr_sie;       // ★独立CSR（SSIP=1, STIP=5, SEIP=9）
    logic  [31:0] csr_stvec;
    logic  [31:0] csr_sscratch;
    logic  [31:0] csr_sepc;
    logic  [31:0] csr_scause;
    logic  [31:0] csr_stval;
    logic  [31:0] csr_satp;

    logic [1:0]   csr_priv_mode;

    // ---------------- DMA CSRs ----------------
    logic  [31:0] csr_DCACHE_CTRL;
    logic  [31:0] csr_DMA_CTRL;
    logic  [31:0] csr_DMA_WORDS;
    logic  [31:0] csr_DMA_SRC;
    logic  [31:0] csr_DMA_DST;
    logic  [31:0] csr_DMA_STATUS;

    // ---------------- SynapEngine CSRs ----------------
    logic  [31:0] csr_SA_CTRL;
    logic  [31:0] csr_SA_MODE;
    logic  [31:0] csr_SA_STATUS;
    logic  [31:0] csr_SA_ADDR_A;
    logic  [31:0] csr_SA_ADDR_B;
    logic  [31:0] csr_SA_ADDR_C;

    // ---------------- CPU Monitor CSRs ----------------
    logic  [31:0] csr_CPU_MON_CTRL;

    // ---------------- constants ----------------
    localparam int S_SIE_BIT  = 1;
    localparam int S_SPIE_BIT = 5;
    localparam int S_SPP_BIT  = 8;
    localparam int S_SUM_BIT  = 18;
    localparam int S_MXR_BIT  = 19;

    localparam logic [31:0] SSTATUS_MASK =
        (32'h1<<S_SIE_BIT) | (32'h1<<S_SPIE_BIT) | (32'h1<<S_SPP_BIT) |
        (32'h1<<S_SUM_BIT) | (32'h1<<S_MXR_BIT);

    // M IRQ
    localparam logic [31:0] MSIP_MASK = (32'h1<<3);
    localparam logic [31:0] MTIP_MASK = (32'h1<<7);
    localparam logic [31:0] MEIP_MASK = (32'h1<<11);
    localparam logic [31:0] MIRQ_MASK = MSIP_MASK | MTIP_MASK | MEIP_MASK;

    // S IRQ
    localparam logic [31:0] SSIP_MASK = (32'h1<<1);
    localparam logic [31:0] STIP_MASK = (32'h1<<5);
    localparam logic [31:0] SEIP_MASK = (32'h1<<9);
    localparam logic [31:0] SIRQ_MASK = SSIP_MASK | STIP_MASK | SEIP_MASK;

    // ---------------- helpers ----------------
    function automatic logic [31:0] pack_tvec_direct(input logic [31:0] v);
        begin pack_tvec_direct = {v[31:2], 2'b00}; end
    endfunction
    function automatic logic [31:0] pack_epc(input logic [31:0] v);
      begin pack_epc = {v[31:2], 2'b00}; end   // 下位2bitゼロ固定
    endfunction
    function automatic logic [31:0] pack_satp_sv32(input logic [31:0] v);
        begin
            // ソフトが書いた値をほぼそのまま使う。
            // 必要なら MODE/PPN にマスクをかける程度でOK
            pack_satp_sv32        = 32'b0;
            pack_satp_sv32[31]    = v[31];      // MODE
            pack_satp_sv32[30:22] = v[30:22];   // ASID
            pack_satp_sv32[21:0]  = v[21:0];    // PPN
        end
    endfunction

    // sip view（mip -> sip）
    function automatic logic [31:0] sip_view(input logic [31:0] mip);
        logic [31:0] v;
        begin
            v = 32'b0;
            v[1] = mip[3];   // SSIP <- MSIP
            v[5] = mip[7];   // STIP <- MTIP
            v[9] = mip[11];  // SEIP <- MEIP
            sip_view = v;
        end
    endfunction

    // CSR apply (RW/RS/RC)
    logic [31:0] csr_wr_val;
    logic        side_effect_none_rs;

    assign csr_wr_val =
        csr_use_imm ? {27'b0, csr_zimm} : csr_rs1_val;
    assign side_effect_none_rs =
        csr_use_imm ? (csr_zimm == 5'd0) : (csr_rs1_val == 32'd0);

    function automatic logic [31:0] csr_apply(
        input logic [1:0]  cmd,
        input logic no_side_effect_rs,
        input logic [31:0] oldv,
        input logic [31:0] wv
    );
        begin
            case (cmd)
                2'b00: csr_apply = wv;                                   // RW
                2'b01: csr_apply = no_side_effect_rs ? oldv : (oldv |  wv); // RS
                2'b10: csr_apply = no_side_effect_rs ? oldv : (oldv & ~wv); // RC
                default: csr_apply = oldv;
            endcase
        end
    endfunction
    
    logic trap_to_s;

    assign trap_to_s =
        (priv_mode != PRIV_M) && csr_medeleg[trap_scause];

    // ---------------- outputs ----------------
    // The CSR registers are already the architectural state.  Driving a
    // second bank of output flops duplicated hundreds of bits and created a
    // global csr_valid clock-enable network.  Expose the state directly and
    // retain registers only for status inputs that must be sampled.
    always_comb begin
        out_mstatus = csr_mstatus;
        out_medeleg = csr_medeleg;
        out_mie     = csr_mie;
        out_mip     = csr_mip;
        out_mtvec   = csr_mtvec;
        out_mepc    = csr_mepc;
        out_mcause  = csr_mcause;

        out_sstatus = csr_sstatus;
        out_stvec   = csr_stvec;
        out_sepc    = csr_sepc;
        out_scause  = csr_scause;
        out_stval   = csr_stval;
        out_satp    = csr_satp;
        priv_mode   = csr_priv_mode;

        out_DCACHE_CTRL = csr_DCACHE_CTRL;
        out_DMA_CTRL    = csr_DMA_CTRL;
        out_DMA_WORDS   = csr_DMA_WORDS;
        out_DMA_SRC     = csr_DMA_SRC;
        out_DMA_DST     = csr_DMA_DST;
        out_SA_CTRL     = csr_SA_CTRL;
        out_SA_MODE     = csr_SA_MODE;
        out_SA_ADDR_A   = csr_SA_ADDR_A;
        out_SA_ADDR_B   = csr_SA_ADDR_B;
        out_SA_ADDR_C   = csr_SA_ADDR_C;
        out_CPU_MON_CTRL = csr_CPU_MON_CTRL;
    end

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            csr_DMA_STATUS <= 32'd0;
            csr_SA_STATUS  <= 32'd0;
        end else if (csr_valid) begin
            csr_DMA_STATUS <= in_DMA_STATUS;
            csr_SA_STATUS  <= in_SA_STATUS;
        end
    end

    // ---------------- read mux ----------------
    function automatic logic [31:0] csr_read_mux(input logic [11:0] a);
        begin
            case (a)
                // Supervisor
                12'h100: csr_read_mux = (csr_sstatus & SSTATUS_MASK); // sstatus
                12'h104: csr_read_mux = (csr_sie     & SIRQ_MASK);    // sie
                12'h105: csr_read_mux = csr_stvec;                    // stvec
                12'h140: csr_read_mux = csr_sscratch;
                12'h141: csr_read_mux = csr_sepc;
                12'h142: csr_read_mux = csr_scause;
                12'h143: csr_read_mux = csr_stval;
                12'h144: csr_read_mux = sip_view(csr_mip);            // sip(view)
                12'h180: csr_read_mux = csr_satp;
                // Machine
                12'h300: csr_read_mux = csr_mstatus;
                12'h301: csr_read_mux = CSR_MISA;
                12'h302: csr_read_mux = csr_medeleg;
                12'h304: csr_read_mux = (csr_mie & MIRQ_MASK);
                12'h305: csr_read_mux = csr_mtvec;
                12'h340: csr_read_mux = csr_mscratch;
                12'h341: csr_read_mux = csr_mepc;
                12'h342: csr_read_mux = csr_mcause;
                12'h344: csr_read_mux = (csr_mip & MIRQ_MASK);
                // DMA
                12'h7F0: csr_read_mux = csr_DMA_STATUS;
                // SynapEngine
                12'h7C8: csr_read_mux = csr_SA_STATUS;
                // CPU Monitor
                12'hBC4: csr_read_mux = in_CPU_MON_CYCLE;

                default: csr_read_mux = 32'b0;
            endcase
        end
    endfunction

    // ---------------- main ----------------
    //reg [31:0] oldv, newv;
    logic [31:0] oldv, newv;

    // Read the CSR before commit and register it in the pipeline.  This keeps
    // the address decoder and the read mux out of the commit-stage CSR update
    // and register-file write-back paths.
    always_comb begin
        csr_rdata = csr_read_mux(csr_read_addr);
    end

    assign  oldv = csr_old_value;
    assign  newv = csr_apply(csr_cmd, side_effect_none_rs, oldv, csr_wr_val);

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            //oldv          <= 32'h0;
            //newv          <= 32'h0;
            csr_priv_mode   <= PRIV_M;
            // M
            csr_mstatus   <= 32'h00001800; // MPP=M-mode, IE=OFF
            //csr_mstatus   <= 32'h00000000;
            csr_medeleg   <= 32'b0;
            csr_mie       <= 32'b0;
            csr_mtvec     <= 32'b0;
            csr_mscratch  <= 32'b0;
            csr_mepc      <= 32'b0;
            csr_mcause    <= 32'b0;
            csr_mip       <= 32'b0;
            // S
            csr_sstatus   <= 32'b0;
            csr_sie       <= 32'b0;
            csr_stvec     <= 32'b0;
            csr_sscratch  <= 32'b0;
            csr_sepc      <= 32'b0;
            csr_scause    <= 32'b0;
            csr_stval     <= 32'b0;
            csr_satp      <= 32'b0;
            // Data Cache
            csr_DCACHE_CTRL <= 32'b0; 
            // DMA
            csr_DMA_CTRL    <= 32'b0; 
            csr_DMA_WORDS   <= 32'b0; 
            csr_DMA_SRC     <= 32'b0; 
            csr_DMA_DST     <= 32'b0; 
            // SA
            csr_SA_CTRL     <= 32'b0; 
            csr_SA_MODE     <= 32'b0; 
            csr_SA_ADDR_A   <= SA_ADDR_A;
            csr_SA_ADDR_B   <= SA_ADDR_B;
            csr_SA_ADDR_C   <= SA_ADDR_C;
            // MONITOR
            csr_CPU_MON_CTRL <= 32'b0; 

        end else begin
            // ---- CSR writes ----
            if (csr_wr & csr_enb) begin
                //oldv = csr_read_mux(csr_addr);
                //newv = csr_apply(csr_cmd, side_effect_none_rs, oldv, csr_wr_val);

                case (csr_addr)
                    // ===== Supervisor =====
                    12'h100: csr_sstatus  <= (newv & SSTATUS_MASK);   // sstatus
                    12'h104: csr_sie      <= (newv & SIRQ_MASK);      // sie
                    12'h105: csr_stvec    <= pack_tvec_direct(newv);  // stvec
                    12'h140: csr_sscratch <= newv;
                    12'h141: csr_sepc     <= pack_epc(newv);
                    12'h142: csr_scause   <= newv;
                    12'h143: csr_stval    <= newv;
                    // sip write: SSIPのみ可 → mip[MSIP]へ反映
                    12'h144: begin
                        if (!side_effect_none_rs) csr_mip[3] <= newv[1];
                    end
                    12'h180: csr_satp     <= pack_satp_sv32(newv);

                    // ===== Machine =====
                    12'h300: csr_mstatus  <= newv;                    // mstatus
                    12'h302: csr_medeleg <= newv;                     // medeleg
                    12'h301: /* misa: RO */;
                    12'h304: csr_mie      <= (newv & MIRQ_MASK);
                    12'h305: csr_mtvec    <= pack_tvec_direct(newv);
                    12'h340: csr_mscratch <= newv;
                    12'h341: csr_mepc     <= pack_epc(newv);
                    12'h342: csr_mcause   <= newv;
                    12'h344: csr_mip      <= (newv & MIRQ_MASK);

                    // ===== DATA CACHE =====
                    12'h7F0: csr_DCACHE_CTRL <= newv;

                    // ===== DMA =====
                    12'h7E0: csr_DMA_CTRL   <= newv;
                    12'h7E4: csr_DMA_WORDS  <= newv;
                    12'h7E8: csr_DMA_SRC    <= newv;
                    12'h7EC: csr_DMA_DST    <= newv;

                    // ===== SynapEngine =====
                    12'h7C0: csr_SA_CTRL    <= newv;
                    12'h7C4: csr_SA_MODE    <= newv;
                    // 7C8: csr_SA_STATUS
                    12'h7D0: csr_SA_ADDR_A  <= newv;
                    12'h7D4: csr_SA_ADDR_B  <= newv;
                    12'h7D8: csr_SA_ADDR_C  <= newv;

                    // ===== CPU MONITOR =====
                    12'hBC0: csr_CPU_MON_CTRL <= newv;

                    default: ;
                endcase
            end

            // Faults are not normal commits.  Accept the trap event directly;
            // ecall and illegal-instruction still arrive with csr_enb asserted.
            if (set_trap) begin
                        if (trap_to_s) begin
                            // ---- S trap ----
                            csr_priv_mode  <= PRIV_S;

                            csr_sepc   <= pack_epc(trap_sepc);
                            csr_scause <= trap_scause;
                            csr_stval  <= trap_stval;

                            csr_sstatus[S_SPIE_BIT] <= csr_sstatus[S_SIE_BIT];
                            csr_sstatus[S_SIE_BIT]  <= 1'b0;
                            csr_sstatus[S_SPP_BIT]  <= priv_mode[0];

                        end else begin
                            // ---- M trap ----
                            csr_priv_mode  <= PRIV_M;

                            csr_mepc   <= pack_epc(trap_sepc);
                            csr_mcause <= trap_scause;
                            csr_mtval  <= trap_stval;

                            csr_mstatus[7]     <= csr_mstatus[3];   // MPIE <- MIE
                            csr_mstatus[3]     <= 1'b0;             // MIE  <- 0
                            csr_mstatus[12:11] <= priv_mode;        // MPP  <- 元のモード
                        end
            end

            if (csr_enb) begin
                // ---- Supervisor trap in/out (SRET) ----
                if (do_sret) begin
                    csr_priv_mode <= {1'b0, csr_sstatus[S_SPP_BIT]}; // 0 or 1
                    csr_sepc   <= pack_epc(csr_sepc);
                    csr_sstatus[S_SIE_BIT]  <= csr_sstatus[S_SPIE_BIT];
                    csr_sstatus[S_SPIE_BIT] <= 1'b1;
                    csr_sstatus[S_SPP_BIT]  <= 1'b0;     
                end

                // ---- Machine trap in/out ----
                if (do_mret) begin
                    // 特権遷移
                    csr_priv_mode <= csr_mstatus[12:11];

                    // mstatus の更新（あなたの既存コードに追加）
                    csr_mstatus[3]  <= csr_mstatus[7];  // MIE  <- MPIE
                    csr_mstatus[7]  <= 1'b1;            // MPIE <- 1
                    csr_mstatus[12:11] <= 2'b00;        // ★ MPP <- U (必須)
                end
                if (set_mtrap) begin
                    csr_mepc       <= pack_epc(trap_mepc);
                    csr_mcause     <= trap_mcause;
                    csr_mstatus[7] <= csr_mstatus[3];   // MPIE <- MIE
                    csr_mstatus[3] <= 1'b0;             // MIE  <- 0
                end
            end

            // ---- mip pending ----
            if (set_msip)  csr_mip[3]  <= 1'b1;
            if (clr_msip)  csr_mip[3]  <= 1'b0;
            if (set_mtip)  csr_mip[7]  <= 1'b1;
            if (clr_mtip)  csr_mip[7]  <= 1'b0;
            if (set_meip)  csr_mip[11] <= 1'b1;
            if (clr_meip)  csr_mip[11] <= 1'b0;
        end
    end
endmodule
