module vrpsm(
    PUB,
    VRPU,
    FPGAGOOD,
    RTCPSMMATCH
  );
  input PUB, VRPU,RTCPSMMATCH;
  output  FPGAGOOD;
  wire temp;
    
  VRPSM VRPSM1(
    .PUB(PUB),
    .VRPU(VRPU),
    .VRINITSTATE(1'b1), 
    .RTCPSMMATCH(RTCPSMMATCH),
    .FPGAGOOD(FPGAGOOD),
    .PUCORE(temp)
  );
    
endmodule
