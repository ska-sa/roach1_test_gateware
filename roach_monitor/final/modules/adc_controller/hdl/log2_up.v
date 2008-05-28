`ifndef LOG2_UP
`define LOG2_UP(x) ((x) == (32'h0) ? 0 : \
                    (x) <= (32'h2) ? 1 : \
                    (x) <= (32'h4) ? 2 : \
                    (x) <= (32'h8) ? 3 : \
                    (x) <= (32'h10) ? 4 : \
                    (x) <= (32'h20) ? 5 : \
                    (x) <= (32'h40) ? 6 : \
                    (x) <= (32'h80) ? 7 : \
                    (x) <= (32'h100) ? 8 : \
                    (x) <= (32'h200) ? 9 : \
                    (x) <= (32'h400) ? 10: \
                    (x) <= (32'h800) ? 11 : \
                    (x) <= (32'h1000) ? 12 : \
                    (x) <= (32'h2000) ? 13 : \
                    (x) <= (32'h4000) ? 14 : \
                    (x) <= (32'h8000) ? 15 : \
                    (x) <= (32'h10000) ? 16 : \
                    (x) <= (32'h20000) ? 17 : \
                    (x) <= (32'h40000) ? 18 : \
                    (x) <= (32'h80000) ? 19 : \
                    (x) <= (32'h100000) ? 20 : \
                    (x) <= (32'h200000) ? 21 : \
                    (x) <= (32'h400000) ? 22 : \
                    (x) <= (32'h800000) ? 23 : \
                    (x) <= (32'h1000000) ? 24 : \
                    (x) <= (32'h2000000) ? 25 : \
                    (x) <= (32'h4000000) ? 26 : \
                    (x) <= (32'h8000000) ? 27 : \
                    (x) <= (32'h10000000) ? 28 : \
                    (x) <= (32'h20000000) ? 29 : \
                    (x) <= (32'h40000000) ? 30 : \
                    31)                                                    
`endif