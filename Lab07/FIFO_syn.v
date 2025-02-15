module FIFO_syn #(parameter WIDTH=32, parameter WORDS=64) (
    wclk,
    rclk,
    rst_n,
    winc,
    wdata,
    wfull,
    rinc,
    rdata,
    rempty,

    clk2_fifo_flag1,
    clk2_fifo_flag2,
    clk2_fifo_flag3,
    clk2_fifo_flag4,

    fifo_clk3_flag1,
    fifo_clk3_flag2,
    fifo_clk3_flag3,
    fifo_clk3_flag4
);

input wclk, rclk;
input rst_n;
input winc;
input [WIDTH-1:0] wdata;
output reg wfull;
input rinc;
output reg [WIDTH-1:0] rdata;
output reg rempty;

// You can change the input / output of the custom flag ports
input clk2_fifo_flag1;
input clk2_fifo_flag2;
output clk2_fifo_flag3;
output clk2_fifo_flag4;

input fifo_clk3_flag1;
input fifo_clk3_flag2;
output fifo_clk3_flag3;
output fifo_clk3_flag4;

localparam SIZE = 6; // log_2^64
//==============================================//
//                    Reg                       //
//==============================================//
wire [SIZE:0] rq2_wptr, wq2_rptr;//Synchronized wptr & rptr
reg [SIZE:0] w_Binary;//wire connect to w_Binary output
reg [SIZE:0] r_Binary;
reg [SIZE:0] w_Binarynext;//wire connect to w_Binary input
reg [SIZE:0] r_Binarynext;
reg [SIZE:0] w_Graynext;//wire connect to wptr
reg [SIZE:0] r_Graynext;

reg [WIDTH-1:0] mem [0:WORDS-1];// FIFO 緩衝區
reg [SIZE:0] wptr;
reg [SIZE:0] rptr;

//==============================================//
//             NDFF BUS Synchronizer            //
//==============================================//
NDFF_BUS_syn #(.WIDTH(SIZE+1)) sync_w2r(wptr,rq2_wptr,rclk,rst_n);
NDFF_BUS_syn #(.WIDTH(SIZE+1)) sync_r2w(rptr,wq2_rptr,wclk,rst_n);
//==============================================//
//                FIFO write Ctrl               //
//==============================================//
always @(*)begin
    w_Binarynext = w_Binary + (winc & ~wfull);
    w_Graynext   = w_Binarynext ^ (w_Binarynext >> 1);
end

always @(posedge wclk or negedge rst_n)begin
    if(!rst_n)
        w_Binary <= 0;
    else
        w_Binary <= w_Binarynext;
end

always @(posedge wclk or negedge rst_n)begin
    if(!rst_n)
        wptr <= 0;
    else
        wptr <= w_Graynext;
end

always @(posedge wclk or negedge rst_n)begin
    if(!rst_n)
        wfull <= 0;
    else if(w_Graynext == {~wq2_rptr[SIZE:SIZE-1], wq2_rptr[SIZE-2:0]})
        wfull <= 1;
    else
        wfull <= 0;
end
//==============================================//
//                FIFO read Ctrl                //
//==============================================//
always @(*)begin
    r_Binarynext = r_Binary + (rinc & ~rempty);
    r_Graynext   = r_Binarynext ^ (r_Binarynext >> 1);
end

always @(posedge rclk or negedge rst_n)begin
    if(!rst_n)
        r_Binary <= 0;
    else
        r_Binary <= r_Binarynext;
end

always @(posedge rclk or negedge rst_n)begin
    if(!rst_n)
        rptr <= 0;
    else
        rptr <= r_Graynext;
end

always @(posedge rclk or negedge rst_n)begin
    if(!rst_n)
        rempty <= 1;
    else if(r_Graynext == rq2_wptr)
        rempty <= 1;
    else
        rempty <= 0;
end
//==============================================//
//                    FIFO                      //
//==============================================//
always @(posedge wclk) begin
    if (winc && !wfull)//FIFO 未滿且有寫請求
        mem[w_Binary[SIZE-1:0]] <= wdata;
end

always @(posedge rclk) begin
    rdata <= mem[r_Binary[SIZE-1:0]];
end



endmodule