`timescale 1ns/10ps
`include "memlayout.v"
module gen_memlayout ();
  initial begin
    $display("#ifndef %s_%s_MEMORY_H        ","`MODULE_ID","`REV_MAJOR");
    $display("#define %s_%s_MEMORY_H        ","`MODULE_ID","`REV_MAJOR");
    $display("#endif");
    $finish;
  end
endmodule
