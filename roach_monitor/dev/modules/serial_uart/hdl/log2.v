`ifndef LOG2
`define LOG2(x)  (x <= 32'h1+1        ? 0 : \
                  x <= 32'h3+1        ? 1 : \
                  x <= 32'h7+1        ? 2 : \
                  x <= 32'hF+1        ? 3 : \
                  x <= 32'h1F+1       ? 4 : \
                  x <= 32'h3F+1       ? 5 : \
                  x <= 32'h7F+1       ? 6 : \
                  x <= 32'hFF+1       ? 7 : \
                  x <= 32'h1FF+1      ? 8 : \
                  x <= 32'h3FF+1      ? 9 : \
                  x <= 32'h7FF+1      ? 10 : \
                  x <= 32'hFFF+1      ? 11 : \
                  x <= 32'h1FFF+1     ? 12 : \
                  x <= 32'h3FFF+1     ? 13 : \
                  x <= 32'h7FFF+1     ? 14 : \
                  x <= 32'hFFFF+1     ? 15 : \
                  x <= 32'h1FFFF+1    ? 16 : \
                  x <= 32'h3FFFF+1    ? 17 : \
                  x <= 32'h7FFFF+1    ? 18 : \
                  x <= 32'hFFFFF+1    ? 19 : \
                  x <= 32'h1FFFFF+1   ? 20 : \
                  x <= 32'h3FFFFF+1   ? 21 : \
                  x <= 32'h7FFFFF+1   ? 22 : \
                  x <= 32'hFFFFFF+1   ? 23 : \
                  x <= 32'h1FFFFFF+1  ? 24 : \
                  x <= 32'h3FFFFFF+1  ? 25 : \
                  x <= 32'h7FFFFFF+1  ? 26 : \
                  x <= 32'hFFFFFFF+1  ? 27 : \
                  x <= 32'h1FFFFFFF+1 ? 28 : \
                  x <= 32'h3FFFFFFF+1 ? 29 : \
                  x <= 32'h7FFFFFFF+1 ? 30 : \
                  x <= 32'hFFFFFFFF+1 ? 31 : \
                  31) 
`endif
