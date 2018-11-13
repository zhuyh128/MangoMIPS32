/********************MangoMIPS32*******************
Filename:	Core_Top.v
Author:		RickyTino
Version:	Unreleased
**************************************************/
`include "Defines.v"

module MangoMIPS_Core_Top
(
    input  wire            clk,
    input  wire            rst,

    output wire            ibus_en,
    output wire [`AddrBus] ibus_addr,
    input  wire [`DataBus] ibus_rdata,

    output wire            dbus_en,
    output wire [`AddrBus] dbus_addr,
    input  wire [`DataBus] dbus_rdata,
    output wire [`ByteWEn] dbus_wen,
    output wire [`DataBus] dbus_wdata,

    output wire [`AddrBus] debug_wb_pc,
    output wire            debug_wb_wreg,
    output wire [`RegAddr] debug_wb_wraddr,
    output wire [`DataBus] debug_wb_wrdata
);
    wire [`AddrBus] if_pcp4;
    wire            if_i_en;
    wire [`AddrBus] if_i_vaddr;
    wire [`DataBus] if_i_rdata; 

    wire [`AddrBus] id_pc;
    wire [`AddrBus] id_pcp4;
    wire [`DataBus] id_inst;
    wire            id_inslot;

    wire            r1read;
    wire [`RegAddr] r1addr;
    wire [`DataBus] r1data;
    wire            r2read;
    wire [`RegAddr] r2addr;
    wire [`DataBus] r2data;

    wire            br_flag;
    wire [`AddrBus] br_addr;
    wire [`DataBus] id_opr1;
    wire [`DataBus] id_opr2;
    wire [`DataBus] id_offset;
    wire [`ALUOp  ] id_aluop;
    wire            id_wreg;
    wire [`RegAddr] id_wraddr;
    wire            id_isbranch;
    wire            id_clrslot;

    wire [`AddrBus] ex_pc;
    wire [`ALUOp  ] ex_aluop;
    wire [`DataBus] ex_opr1;
    wire [`DataBus] ex_opr2;
    wire [`DataBus] ex_offset;
    wire            ex_wreg;
    wire [`RegAddr] ex_wraddr;

    wire            div_start;
    wire            div_signed;
    wire            div_ready;
    wire [`DWord  ] div_res;

    wire [`DataBus] ex_alures;
    wire            ex_resnrdy;
    wire [`DWord  ] ex_mulhi;
    wire [`DWord  ] ex_mullo;
    wire            ex_mul_s;

    wire            ex_m_en;
    wire [`ByteWEn] ex_m_wen;
    wire [`AddrBus] ex_m_vaddr;
    wire [`DataBus] ex_m_wdata;
    
    wire [`AddrBus] mem_pc;
    wire [`ALUOp  ] mem_aluop;
    wire [`DataBus] mem_alures_i;
    wire [`DataBus] mem_opr2;
    wire [`DWord  ] mem_mulhi;
    wire [`DWord  ] mem_mullo;
    wire            mem_mul_s;
    wire [`DWord  ] mem_divres; 
    wire            mem_wreg;
    wire [`RegAddr] mem_wraddr;

    wire            mem_m_en;
    wire [`ByteWEn] mem_m_wen;
    wire [`AddrBus] mem_m_vaddr;
    wire [`DataBus] mem_m_wdata;
    wire [`DataBus] mem_m_rdata;

    wire [`DataBus] mem_alures_o;
    wire            mem_resnrdy;
    wire            mem_whilo;
    wire [`DWord  ] mem_hilo;

    wire [`AddrBus] wb_pc;
    wire [`ALUOp  ] wb_aluop;
    wire [`DataBus] wb_alures;
    wire [`DataBus] wb_opr2;
    wire [`AddrBus] wb_m_vaddr;
    wire [`DataBus] wb_m_rdata; 
    wire            wb_wreg;
    wire [`RegAddr] wb_wraddr;
    wire            wb_whilo;
    wire [`DWord  ] wb_hilo;

    wire [`DataBus] wb_wrdata;
    wire [`DWord  ] hilo;

    wire [`Stages ] stallreq;
    wire [`Stages ] stall;
    wire [`Stages ] flush; 
  
    PC pc (
        .clk     (clk       ),
        .rst     (rst       ),
        .stall   (stall[`IF]),
        .flush   (flush[`IF]),
        .flush_pc (`ZeroWord), //Temp!
        .br_flag  (br_flag),
        .br_addr  (br_addr),

        .pc      (if_i_vaddr ),
        .pcp4    (if_pcp4   ),
        .i_en    (if_i_en   )
    );
    
    MMU_Inst mmu_inst (
        .i_en    (if_i_en),
        .i_vaddr (if_i_vaddr),
        .i_rdata (if_i_rdata),

        .ibus_en    (ibus_en),
        .ibus_paddr (ibus_addr),
        .ibus_rdata (ibus_rdata),

        .stallreq (stallreq[`IF])
    );

    Reg_IF_ID reg_if_id (
        .clk     (clk       ),
        .rst     (rst       ),
        .stall   (stall[`ID]),
        .flush   (flush[`ID]),
        .clrslot (id_clrslot),

        .if_pc   (ibus_addr ),
        .if_pcp4 (if_pcp4 ),
        .if_inst (ibus_rdata),
        .id_isbranch (id_isbranch),
        .id_pc     (id_pc     ),
        .id_pcp4   (id_pcp4     ),
        .id_inst   (id_inst   ),
        .id_inslot (id_inslot)
    );

    Decode decode (
        .pc         (id_pc     ),
        .pcp4       (id_pcp4   ),
        .inst       (id_inst   ),

        .r1read     (r1read    ),
        .r1addr     (r1addr    ),
        .r1data     (r1data    ),
        .r2read     (r2read    ),
        .r2addr     (r2addr    ),
        .r2data     (r2data    ),

        .opr1       (id_opr1   ),
        .opr2       (id_opr2   ),
        .aluop      (id_aluop  ),
        .offset     (id_offset ),
        .wreg       (id_wreg   ),
        .wraddr     (id_wraddr ),

        .ex_wreg    (ex_wreg   ),
        .ex_wraddr  (ex_wraddr ),
        .ex_alures  (ex_alures ),
        .ex_resnrdy (ex_resnrdy),

        .mem_wreg   (mem_wreg  ),
        .mem_wraddr (mem_wraddr),
        .mem_alures (mem_alures_o),
        .mem_resnrdy (mem_resnrdy),

        .isbranch (id_isbranch),
        .inslot   (id_inslot),
        .clrslot  (id_clrslot),
        .br_flag  (br_flag),
        .br_addr  (br_addr),

        .stallreq(stallreq[`ID])
    );

    RegFile regfile (
        .clk    (clk      ),
        .rst    (rst      ), 

        .re1    (r1read   ), 
        .r1addr (r1addr   ),
        .r1data (r1data   ),

        .re2    (r2read   ),
        .r2addr (r2addr   ),
        .r2data (r2data   ),

        
        .we     (wb_wreg  ),
        .waddr  (wb_wraddr), 
        .wdata  (wb_wrdata)
    );

    Reg_ID_EX reg_id_ex (
        .clk       (clk       ),
        .rst       (rst       ),
        .stall     (stall[`EX]),
        .flush     (flush[`EX]),

        .id_pc     (id_pc     ),
        .id_aluop  (id_aluop  ),
        .id_opr1   (id_opr1   ),
        .id_opr2   (id_opr2   ),
        .id_offset (id_offset ),
        .id_wreg   (id_wreg   ),
        .id_wraddr (id_wraddr ),
        

        .ex_pc     (ex_pc     ),
        .ex_aluop  (ex_aluop  ),
        .ex_opr1   (ex_opr1   ),
        .ex_opr2   (ex_opr2   ),
        .ex_offset (ex_offset ),
        .ex_wreg   (ex_wreg   ),
        .ex_wraddr (ex_wraddr )
    );

    ALU_EX alu_ex (
        .pc     (ex_pc),
        .aluop  (ex_aluop ),
        .opr1   (ex_opr1  ),
        .opr2   (ex_opr2  ),
        .offset (ex_offset),
        .div_start  (div_start),
        .div_signed (div_signed),
        .div_ready  (div_ready),

        .alures (ex_alures),
        .resnrdy (ex_resnrdy),
        .mulhi (ex_mulhi),
        .mullo (ex_mullo),
        .mul_s (ex_mul_s),

        .m_en (ex_m_en),
        .m_wen (ex_m_wen),
        .m_vaddr (ex_m_vaddr),
        .m_wdata (ex_m_wdata),

        .stallreq (stallreq[`EX])
    );

    Divider divider (
        .clk (clk),
        .rst (rst),
        .start (div_start),
        .abandon (flush[`EX]),
        .signdiv (div_signed),
        .opr1 (ex_opr1),
        .opr2 (ex_opr2),
        .ready (div_ready),
        .res   (div_res)
    );

    Reg_EX_MEM reg_ex_mem (
        .clk        (clk        ),
        .rst        (rst        ),
        .stall      (stall[`MEM]),
        .flush      (flush[`MEM]),

        .ex_pc      (ex_pc      ),
        .ex_aluop   (ex_aluop   ),
        .ex_alures  (ex_alures  ),
        .ex_opr2    (ex_opr2),
        .ex_mulhi (ex_mulhi),
        .ex_mullo (ex_mullo),
        .ex_mul_s (ex_mul_s),
        .ex_divres (div_res),
        .ex_m_en (ex_m_en),
        .ex_m_wen (ex_m_wen),
        .ex_m_vaddr (ex_m_vaddr),
        .ex_m_wdata (ex_m_wdata),
        .ex_wreg    (ex_wreg    ),
        .ex_wraddr  (ex_wraddr  ),
        
        .mem_pc     (mem_pc     ),
        .mem_aluop  (mem_aluop  ),
        .mem_alures (mem_alures_i ),
        .mem_opr2   (mem_opr2),
        .mem_mulhi (mem_mulhi),
        .mem_mullo (mem_mullo),
        .mem_mul_s (mem_mul_s),
        .mem_divres (mem_divres),
        .mem_m_en (mem_m_en),
        .mem_m_wen (mem_m_wen),
        .mem_m_vaddr (mem_m_vaddr),
        .mem_m_wdata (mem_m_wdata),
        .mem_wreg   (mem_wreg   ),
        .mem_wraddr (mem_wraddr )
    );
    
    MMU_Data mmu_data (
        .m_en (mem_m_en),
        .m_wen (mem_m_wen),
        .m_vaddr (mem_m_vaddr),
        .m_wdata (mem_m_wdata),
        .m_rdata (mem_m_rdata),
        
        .dbus_en    (dbus_en   ),
        .dbus_paddr  (dbus_addr ),
        .dbus_rdata (dbus_rdata),
        .dbus_wen   (dbus_wen  ),
        .dbus_wdata (dbus_wdata),

        .stallreq (stallreq[`MEM])
    );
    
    ALU_MEM alu_mem (
        .aluop (mem_aluop),
        .alures_i (mem_alures_i),
        .mulhi (mem_mulhi),
        .mullo (mem_mullo),
        .mul_s (mem_mul_s),
        .divres (mem_divres),
        .hilo_i (hilo),

        .alures_o (mem_alures_o),
        .whilo  (mem_whilo),
        .hilo_o (mem_hilo),
        .resnrdy (mem_resnrdy)
    );

    Reg_MEM_WB reg_mem_wb (
        .clk         (clk       ),
        .rst         (rst       ),
        .stall       (stall[`WB]),
        .flush       (flush[`WB]),

        .mem_pc      (mem_pc    ),
        .mem_aluop   (mem_aluop ),
        .mem_alures  (mem_alures_o),
        .mem_opr2    (mem_opr2),
        .mem_m_vaddr (mem_m_vaddr),
        .mem_m_rdata (mem_m_rdata),
        .mem_wreg    (mem_wreg  ),
        .mem_wraddr  (mem_wraddr),
        .mem_whilo  (mem_whilo),
        .mem_hilo (mem_hilo),

        .wb_pc      (wb_pc      ),
        .wb_aluop   (wb_aluop   ),
        .wb_alures  (wb_alures  ),
        .wb_opr2    (wb_opr2),
        .wb_m_vaddr (wb_m_vaddr),
        .wb_m_rdata (wb_m_rdata),
        .wb_wreg    (wb_wreg    ),
        .wb_wraddr  (wb_wraddr  ),
        .wb_whilo  (wb_whilo),
        .wb_hilo (wb_hilo)
    );

    WriteBack writeback (
        .aluop  (wb_aluop),
        .alures (wb_alures),
        .opr2   (wb_opr2),
        .m_vaddr (wb_m_vaddr),
        .m_rdata (wb_m_rdata),
        .wrdata (wb_wrdata),
        .stallreq (stallreq[`WB])
    );
    
    HiLo hiloreg (
        .clk (clk),
        .rst (rst),
        .whilo (wb_whilo),
        .wdata (wb_hilo),
        .rdata (hilo)
    );
    
    Control control (
        .stallreq (stallreq),
        .stall    (stall   ),
        .flush    (flush   )
    );

    assign debug_wb_pc     = wb_pc;
    assign debug_wb_wreg   = wb_wreg;
    assign debug_wb_wraddr = wb_wraddr;
    assign debug_wb_wrdata = wb_wrdata;
    
endmodule



