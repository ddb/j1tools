module j1(
   input sys_clk_i, 
   input sys_rst_i,
   input sys_en_i, 
   input [15:0] io_din,
   output io_rd, 
   output io_wr, 
   output [15:0] io_addr,
   output [15:0] io_dout,
   
//   output [15:0] mem_addr,
//   output [15:0] mem_wr_data,
//   output        mem_wr_enable,
//   input  [15:0] mem_rd_data,
//   output [12:0] mem_pc,
//   input  [15:0] mem_rd_insn,
   
   output [12:0] pc_out,
   output [15:0] st0_out,
   output [15:0] st1_out,
   output [15:0] rst0_out,
   output [15:0] insn_out,
   
   input  [4:0]  stk_lvl,
   output [15:0] stk_lvl_data
 );
   
//  reg [15:0] ram[0:16383];


//  reg [15:0] _insn;
//  wire [15:0] insn = _insn;
  wire [15:0] insn;
  wire [15:0] immediate = { 1'b0, insn[14:0] };

//  reg [15:0] _ramrd;
//  wire [15:0] ramrd = _ramrd;
  wire [15:0] ramrd;

  reg [4:0] dsp;  // Data stack pointer
  reg [4:0] _dsp;
  reg [15:0] st0; // Return stack pointer
  reg [15:0] _st0;
  wire _dstkW;     // D stack write

  reg [12:0] pc;
  reg [12:0] _pc;
  reg [4:0] rsp;
  reg [4:0] _rsp;
  reg _rstkW;     // R stack write
  reg [15:0] _rstkD;
  wire _ramWE;     // RAM write enable
  
  wire [15:0] pc_plus_1;
  assign pc_plus_1 = pc + 1;

  // The D and R stacks
  reg [15:0] dstack[0:31];
  reg [15:0] rstack[0:31];
  always @(posedge sys_clk_i)
  begin
    if (_dstkW)
      dstack[_dsp] = st0;
    if (_rstkW)
      rstack[_rsp] = _rstkD;
  end
  wire [15:0] st1 = dstack[dsp];
  wire [15:0] rst0 = rstack[rsp];
  
  assign pc_out = pc;
  assign st0_out = st0;
  assign st1_out = st1;
  assign rst0_out = rst0;
  assign insn_out = insn;
  assign stk_lvl_data = dstack[stk_lvl];
    
  // st0sel is the ALU operation.  For branch and call the operation
  // is T, for 0branch it is N.  For ALU ops it is loaded from the instruction
  // field.
  reg [3:0] st0sel;
  always @*
  begin
    case (insn[14:13])
      2'b00: st0sel = 0;          // ubranch
      2'b10: st0sel = 0;          // call
      2'b01: st0sel = 1;          // 0branch
      2'b11: st0sel = insn[11:8]; // ALU
      default: st0sel = 4'bxxxx;
    endcase
  end
  
//  assign mem_addr = _st0;
//  assign mem_wr_enable = _ramWE & (_st0[15:14] == 0);
//  assign mem_wr_data = _st1;
//  assign mem_pc = _pc;

//  always @(posedge sys_clk_i) begin
//    if (sys_en_i | sys_rst_i) begin
//      insn <= mem_rd_insn;
//    end
    
//    if ((|_st0[15:14] == 0) & sys_en_i) begin
//      ramrd <= mem_rd_data;
//    end
//  end  

//`define RAMS 3
//////`define RAMS 1

//  genvar i;

//`define w (16 >> `RAMS)
//`define w1 (`w - 1)

//  generate 
//    for (i = 0; i < (1 << `RAMS); i=i+1) begin : ram
//      // RAMB16_S18_S18
//      RAMB16_S2_S2
//      ram(
//        .DIA(0),
//        // .DIPA(0),
//        .DOA(insn[`w*i+`w1:`w*i]),
//        .WEA(0),
//        .ENA(sys_en_i | sys_rst_i),
//        .CLKA(sys_clk_i),
//        .ADDRA({_pc}),

//        .DIB(st1[`w*i+`w1:`w*i]),
//        // .DIPB(2'b0),
//        .WEB(_ramWE & (_st0[15:14] == 0)),
//        .ENB((|_st0[15:14] == 0) & sys_en_i),
//        .CLKB(sys_clk_i),
//        .ADDRB(_st0[15:1]),
//        .DOB(ramrd[`w*i+`w1:`w*i]));
//    end
//  endgenerate
  
//  BRAM_TDP_MACRO #(
//      .BRAM_SIZE("18Kb"), // Target BRAM: "9Kb" or "18Kb" 
//      .DEVICE("SPARTAN6"), // Target device: "VIRTEX5", "VIRTEX6", "SPARTAN6" 
//      .INIT_FILE ("NONE"),
//      .READ_WIDTH_A (16),   // Valid values are 1-36
//      .READ_WIDTH_B (16),   // Valid values are 1-36
//      .WRITE_WIDTH_A(16), // Valid values are 1-36
//      .WRITE_WIDTH_B(16) // Valid values are 1-36
//   ) forth_ram (
//      .DOA(insn),       // Output port-A data, width defined by READ_WIDTH_A parameter
//      .DOB(ramrd),       // Output port-B data, width defined by READ_WIDTH_B parameter
//      .ADDRA({_pc}),   // Input port-A address, width defined by Port A depth
//      .ADDRB(_st0[15:1]),   // Input port-B address, width defined by Port B depth
//      .CLKA(sys_clk_i),     // 1-bit input port-A clock
//      .CLKB(sys_clk_i),     // 1-bit input port-B clock
//      .DIA(16'b0),       // Input port-A data, width defined by WRITE_WIDTH_A parameter
//      .DIB(st1),       // Input port-B data, width defined by WRITE_WIDTH_B parameter
//      .ENA(sys_en_i | sys_rst_i),       // 1-bit input port-A enable
//      .ENB((|_st0[15:14] == 0) & sys_en_i),       // 1-bit input port-B enable
//      .WEA(1'b0),       // Input port-A write enable, width defined by Port A depth
//      .WEB(_ramWE & (_st0[15:14] == 0))        // Input port-B write enable, width defined by Port B depth
//   );
  j1mem ram (
    .clka(sys_clk_i), // input clka
    .ena(sys_en_i | sys_rst_i), // input ena
    .wea(1'b0), // input [0 : 0] wea
    .addra({_pc}), // input [11 : 0] addra
    .dina(16'b0), // input [15 : 0] dina
    .douta(insn), // output [15 : 0] douta
    
    .clkb(sys_clk_i), // input clkb
    .enb((|_st0[15:14] == 0) & sys_en_i), // input enb
    .web(_ramWE & (_st0[15:14] == 0)), // input [0 : 0] web
    .addrb(_st0[15:1]), // input [11 : 0] addrb
    .dinb(st1), // input [15 : 0] dinb
    .doutb(ramrd) // output [15 : 0] doutb
  );

// load the init for the startup forth code
//
//`include "firmware/serial_emit_a.v"

//   Compute the new value of T.
  always @*
  begin
    if (insn[15])
      _st0 = immediate;
    else
      case (st0sel)
        4'b0000: _st0 = st0;
        4'b0001: _st0 = st1;
        4'b0010: _st0 = st0 + st1;
        4'b0011: _st0 = st0 & st1;
        4'b0100: _st0 = st0 | st1;
        4'b0101: _st0 = st0 ^ st1;
        4'b0110: _st0 = ~st0;
        4'b0111: _st0 = {16{(st1 == st0)}};
        4'b1000: _st0 = {16{($signed(st1) < $signed(st0))}};
        4'b1001: _st0 = st1 >> st0[3:0];
        4'b1010: _st0 = st0 - 1;
        4'b1011: _st0 = rst0;
        4'b1100: _st0 = |st0[15:14] ? io_din : ramrd;
        4'b1101: _st0 = st1 << st0[3:0];
        4'b1110: _st0 = {rsp, 3'b000, dsp};
        4'b1111: _st0 = {16{(st1 < st0)}};
        default: _st0 = 16'hxxxx;
      endcase
  end

  wire is_alu = (insn[15:13] == 3'b011);
  wire is_lit = (insn[15]);

  assign io_rd = (is_alu & (insn[11:8] == 4'hc));
  assign io_wr = _ramWE;
  assign io_addr = st0;
  assign io_dout = st1;

  assign _ramWE = is_alu & insn[5];
  assign _dstkW = is_lit | (is_alu & insn[7]);

  wire [1:0] dd = insn[1:0];  // D stack delta
  wire [1:0] rd = insn[3:2];  // R stack delta

  always @*
  begin
    if (is_lit) begin                       // literal
      _dsp = dsp + 1;
      _rsp = rsp;
      _rstkW = 0;
      _rstkD = _pc;
    end else if (is_alu) begin
      _dsp = dsp + {dd[1], dd[1], dd[1], dd};
      _rsp = rsp + {rd[1], rd[1], rd[1], rd};
      _rstkW = insn[6];
      _rstkD = st0;
    end else begin                          // jump/call
      // predicated jump is like DROP
      if (insn[15:13] == 3'b001) begin
        _dsp = dsp - 1;
      end else begin
        _dsp = dsp;
      end
      if (insn[15:13] == 3'b010) begin // call
        _rsp = rsp + 1;
        _rstkW = 1;
        _rstkD = {pc_plus_1[14:0], 1'b0};
      end else begin
        _rsp = rsp;
        _rstkW = 0;
        _rstkD = _pc;
      end
    end
  end

  always @*
  begin
    if (sys_rst_i)
      _pc = pc;
    else
      if ((insn[15:13] == 3'b000) |
          ((insn[15:13] == 3'b001) & (|st0 == 0)) |
          (insn[15:13] == 3'b010))
        _pc = insn[12:0];
      else if (is_alu & insn[12])
        _pc = rst0[15:1];
      else
        _pc = pc_plus_1;
  end

  always @(posedge sys_clk_i)
  begin
    if (sys_rst_i) begin
      pc <= 0;
      dsp <= 0;
      st0 <= 0;
      rsp <= 0;
    end else if (sys_en_i) begin
      dsp <= _dsp;
      pc <= _pc;
      st0 <= _st0;
      rsp <= _rsp;
    end
  end

endmodule // j1
