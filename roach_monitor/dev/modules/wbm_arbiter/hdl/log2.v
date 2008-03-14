`ifndef LOG2
`define LOG2(x)  (x <= 32'h1        ? 0 : \
                  x <= 32'h3        ? 1 : \
                  x <= 32'h7        ? 2 : \
                  x <= 32'hF        ? 3 : \
                  x <= 32'h1F       ? 4 : \
                  x <= 32'h3F       ? 5 : \
                  x <= 32'h7F       ? 6 : \
                  x <= 32'hFF       ? 7 : \
                  x <= 32'h1FF      ? 8 : \
                  x <= 32'h3FF      ? 9 : \
                  x <= 32'h7FF      ? 10 : \
                  x <= 32'hFFF      ? 11 : \
                  x <= 32'h1FFF     ? 12 : \
                  x <= 32'h3FFF     ? 13 : \
                  x <= 32'h7FFF     ? 14 : \
                  x <= 32'hFFFF     ? 15 : \
                  x <= 32'h1FFFF    ? 16 : \
                  x <= 32'h3FFFF    ? 17 : \
                  x <= 32'h7FFFF    ? 18 : \
                  x <= 32'hFFFFF    ? 19 : \
                  x <= 32'h1FFFFF   ? 20 : \
                  x <= 32'h3FFFFF   ? 21 : \
                  x <= 32'h7FFFFF   ? 22 : \
                  x <= 32'hFFFFFF   ? 23 : \
                  x <= 32'h1FFFFFF  ? 24 : \
                  x <= 32'h3FFFFFF  ? 25 : \
                  x <= 32'h7FFFFFF  ? 26 : \
                  x <= 32'hFFFFFFF  ? 27 : \
                  x <= 32'h1FFFFFFF ? 28 : \
                  x <= 32'h3FFFFFFF ? 29 : \
                  x <= 32'h7FFFFFFF ? 30 : \
                  x <= 32'hFFFFFFFF ? 31 : \
                  31) 
`endif
