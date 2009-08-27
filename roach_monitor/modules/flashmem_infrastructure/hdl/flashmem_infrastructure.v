`timescale 1ns/10ps
/* FlashMemory Wrapper
 *
 * Features fixed: 
 * - no page protection -> coherent controller 
 * - 16 bit data
 * - stripped down: no pipeline/readnext -> simple read/write/program
 */

module flashmem(
    FM_ADDR,       
    FM_WD,               
    FM_REN,              
    FM_WEN,              
    FM_PROGRAM,        
    FM_CLK,             
    FM_RESET,           
    FM_RD,              
    FM_BUSY,            
    FM_STATUS,
    FM_PAGESTATUS
  );
  input  [16:0] FM_ADDR;
  input  [15:0] FM_WD;
  input  FM_PAGESTATUS;
  input  FM_REN, FM_WEN, FM_PROGRAM;
  input  FM_CLK, FM_RESET;
  output [31:0]  FM_RD;
  output FM_BUSY;
  output [1:0] FM_STATUS;

  NVM NVM_inst(
   .ADDR({FM_ADDR,1'b0}), /*two bytes per command-hence no addr[0]*/
   .WD({16'b0,FM_WD}),               
   .DATAWIDTH(2'b01),        
   .REN(FM_REN),              
   .READNEXT(1'b0),         
   .PAGESTATUS(FM_PAGESTATUS),       
   .WEN(FM_WEN),              
   .ERASEPAGE(1'b0),      
   .PROGRAM(FM_PROGRAM),        
   .SPAREPAGE(1'b0),      
   .AUXBLOCK(1'b0),       
   .UNPROTECTPAGE(1'b0),  
   .OVERWRITEPAGE(1'b0),  
   .DISCARDPAGE(1'b0),    
   .OVERWRITEPROTECT(1'b0),
   .PAGELOSSPROTECT(1'b0), 
   .PIPE(1'b0),            
   .LOCKREQUEST(1'b0),     
   .CLK(FM_CLK),             
   .RESET(FM_RESET),           
   .RD(FM_RD),              
   .BUSY(FM_BUSY),            
   .STATUS(FM_STATUS)
  );
endmodule
