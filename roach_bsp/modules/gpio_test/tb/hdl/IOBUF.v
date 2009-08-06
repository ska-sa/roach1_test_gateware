module IOBUF(
    input  IO,
    output O,
    input  I,
    input  T
  );

  //assign IO = !T ? I : 1'bz;
  assign O  = !T ? I : IO;
endmodule
