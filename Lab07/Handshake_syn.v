module Handshake_syn #(parameter WIDTH=32) (
    sclk,
    dclk,
    rst_n,
    sready,
    din,
    dbusy,
    sidle,
    dvalid,
    dout,

    clk1_handshake_flag1,
    clk1_handshake_flag2,
    clk1_handshake_flag3,
    clk1_handshake_flag4,

    handshake_clk2_flag1,
    handshake_clk2_flag2,
    handshake_clk2_flag3,
    handshake_clk2_flag4
);

input sclk, dclk;
input rst_n;
input sready;
input [WIDTH-1:0] din;
input dbusy;
output sidle;
output reg dvalid;
output reg [WIDTH-1:0] dout;

// You can change the input / output of the custom flag ports
input clk1_handshake_flag1;
input clk1_handshake_flag2;
output clk1_handshake_flag3;
output clk1_handshake_flag4;

input handshake_clk2_flag1;
input handshake_clk2_flag2;
output handshake_clk2_flag3;
output handshake_clk2_flag4;

// request and ack
reg sreq;
wire dreq;
reg dack;
wire sack;

reg [WIDTH-1:0] data;
reg [1:0] s_state, s_nstate; // sclk state
reg [1:0] d_state, d_nstate; // dclk state

localparam S_IDLE = 0;
localparam S_SEND = 1;
localparam S_WAIT = 2;

localparam D_IDLE = 0;
localparam D_RECV = 1;
//localparam D_DONE = 2;//consummation


// double flip flops: NDFF_syn(D, Q, clk, rst_n);
NDFF_syn S2D (sreq, dreq, dclk, rst_n);
NDFF_syn D2S (dack, sack, sclk, rst_n);

// sender idle
assign sidle = (s_state == S_IDLE)? 1 : 0;

//Transmitter FSM
always @(*)begin
    case(s_state)
        S_IDLE:begin
            if(sready)//sready && !sack
                s_nstate = S_SEND;
            else
                s_nstate = S_IDLE;
        end
        S_SEND:begin
            if(sack)//wait scak = 1
                s_nstate = S_WAIT;
            else
                s_nstate = S_SEND;
        end
        S_WAIT:begin
            if(!sack)
                s_nstate = S_IDLE;
            else
                s_nstate = S_WAIT;
        end
        default:begin
            s_nstate = S_IDLE; //預防意外情況
        end
    endcase
end

always @(posedge sclk or negedge rst_n)begin
    if(!rst_n)
        s_state <= S_IDLE;
    else 
        s_state <= s_nstate;
end
//==============================================//
//              Capturing Data                  //
//==============================================//
always @(posedge sclk or negedge rst_n) begin
    if (!rst_n)
        data <= 0;
    else if (sready && s_state == S_IDLE)
        data <= din; // 捕捉數據
end

always @(posedge sclk or negedge rst_n) begin
    if (!rst_n)
        sreq <= 0;
    else if (s_nstate == S_SEND)
        sreq <= 1; // 發送請求
    else
        sreq <= 0;
end

 // **NDFF 同步器 - 同步 sreq 到接收端**
NDFF_syn NDFF_SYNC_REQ (
    .D(sreq),
    .Q(dreq),
    .rst_n(rst_n),
    .clk(dclk)
);

//==============================================//
//                Receiver FSM                  //
//==============================================//
always @(*)begin
    case(d_state)
        D_IDLE:begin
            if(dreq && !dbusy)
                d_nstate = D_RECV;
            else
                d_nstate = D_IDLE;
        end
        D_RECV:begin
            if(!dreq)
                d_nstate = D_IDLE;
            else
                d_nstate = D_RECV;
        end
        default:d_nstate = D_IDLE;
    endcase
end

always @(posedge dclk or negedge rst_n) begin
    if (!rst_n)
        d_state <= D_IDLE;
    else
        d_state <= d_nstate;
end

always @(posedge dclk or negedge rst_n)begin
    if(!rst_n)
        dack <= 0;
    else
        dack <= (d_nstate == D_IDLE) ? 0 : 1;
end

always @(posedge dclk or negedge rst_n)begin
    if(!rst_n) begin
        dout <= 0;
        dvalid <= 0;
    end
    else begin
        if(d_state == D_IDLE && dbusy == 0 && dreq == 1) begin
            dout <= data;
            dvalid <= 1;
        end
        else begin
            dout <= 0;
            dvalid <= 0;
        end
    end
end
/*
always @(posedge dclk or negedge rst_n)begin
    if(!rst_n) begin
        dout <= 0;
        dvalid <= 0;
        dack <= 0;
    end
    else begin

        if(d_state == D_RECV) begin
            dout <= data;
            dvalid <= 1;
            dack <= 1;
        end
        else begin
            dout <= 0;
            dvalid <= 0;
            dack <= 0;
        end
    end
end
*/
NDFF_syn NDFF_SYNC_ACK (
    .D(dack),
    .Q(sack),
    .rst_n(rst_n),
    .clk(sclk)
);



endmodule