

module CC(
//Input Port
    clk,
    rst_n,
    in_valid,
    mode,
    xi,
    yi,

    //Output Port
    out_valid,
    xo,
    yo
    );

input    clk, rst_n, in_valid;
input    [1:0]   mode;
input    signed   [7:0]   xi, yi;  

output reg          out_valid;
output reg signed [7:0]   xo, yo;

//==============================================//
//          Parameters & Moor Machines          //
//==============================================//
parameter IDLE = 3;
parameter MODE0 = 0;
parameter MODE1 = 1;
parameter MODE2 = 2; 
//==============================================//
//                 reg declaration              //
//==============================================//
reg [1:0] current_state;
reg [1:0] next_state;
reg [2:0] counter;
reg xo_eq_left;
reg valid_now;

reg signed[7:0] x_now, y_now;
reg signed[7:0] right_bound, left_bound;
reg signed[7:0] left_bound_old;
reg signed[7:0] minus1, minus2, minus3; 
reg signed[8:0] minus4;
reg signed[15:0] multi_accum1 [4:0];
reg signed[16:0] accum_deltax_right, accum_deltax_left;
reg signed[16:0] area_ans_pre;
reg signed[16:0] area_ans;

wire reap_stam_left;
wire signed[7:0] xul = (in_valid & counter==0)? xi : xul;//Mode0:xul 1:a1 
wire signed[7:0] xur = (in_valid & counter==1)? xi : xur;//Mode0:xur 1:b1
wire signed[7:0] xdl = (in_valid & counter==2)? xi : xdl; //Mode0:xdl 1:c1
wire signed[7:0] xdr = (in_valid & counter==3)? xi : xdr;
wire signed[7:0] yu = (in_valid & counter==0)? yi: yu; //Mode0:yu 1:a2
wire signed[7:0] b2 = (in_valid & counter==1)? yi: b2; //Mode0:yu 1:b2
wire signed[7:0] c2 = (in_valid & counter==2)? yi: c2; //Mode1:c2
wire signed[7:0] yd = (in_valid & counter==3)? yi: yd; //Mode0:yd 
wire signed[7:0] d1 = (in_valid & counter==4)? xi: d1; //Mode2:d1 
wire signed[7:0] d2 = (in_valid & counter==4)? yi: d2; //Mode2:d2 

wire signed[8:0] deltax_left = (in_valid && counter==2)? xul - xi : deltax_left;
wire signed[8:0] deltax_right = (in_valid && counter==3)? xur - xi : deltax_right;
wire signed[8:0] deltay = (in_valid && counter==2)? yu - yi : deltay;

wire signed[7:0] b2_minus_a2 = (mode==1 && counter==1)? yi - yu : b2_minus_a2;
wire signed[7:0] a1_minus_b1 = (mode==1 && counter==1)? xul - xi : a1_minus_b1;
wire signed[7:0] a2_minus_b2 = (mode==1 && counter==1)? yu - yi : a2_minus_b2;
wire signed[7:0] c2_minus_d2 = (mode==1 && counter==3)? c2 - yi : c2_minus_d2;
wire signed[7:0] c1_minus_d1 = (mode==1 && counter==3)? xdl - xi : c1_minus_d1;
wire signed[26:0] multi_ans1 = multi_accum1[2] * multi_accum1[2];
wire signed[26:0] multi_ans2 = multi_accum1[1] * multi_accum1[3];

//==============================================//
//             Signal  Multiplexer              //
//==============================================// 
always @(*) begin //procedure assigment
    if(mode == 1) begin
        case(counter)
            1:begin
                minus1 = b2_minus_a2;// b2-a2 (Multiplexer Area small than subtractor)
                minus2 = b2_minus_a2;// b2-a2
                minus3 = a1_minus_b1;// a1-b1
                minus4 = a1_minus_b1;// a1-b1
            end
            2:begin
                minus1 = a1_minus_b1;// a1-b1
                minus2 = yi - b2;// c2 - b2
                minus3 = a2_minus_b2;// a2-b2
                minus4 = xur - xi;// b1 - c1
            end
            3:begin
                minus1 = c1_minus_d1; //c1 - d1
                minus2 = c1_minus_d1; 
                minus3 = c2_minus_d2;//c2 - d2
                minus4 = c2_minus_d2;
            end
            default:begin
                minus1 = minus1;
                minus2 = minus2;
                minus3 = minus3;
                minus4 = minus4;
            end
        endcase
    end
    else if(mode == 2) begin
        case(counter)
            1:begin
                minus1 = xul;//a1
                minus2 = yi;//b2
                minus3 = yu;//a2
                minus4 = ~{xi[7],xi} + 1;//-b1
            end
            2:begin
                minus1 = xur;//b1
                minus2 = yi;//c2
                minus3 = b2;//b2
                minus4 = ~{xi[7],xi} + 1;//-c1
            end
            3:begin
                minus1 = xdl;//c1
                minus2 = yi;//d2
                minus3 = c2;//c2
                minus4 = ~{xi[7],xi} + 1;//-d1
            end
            4:begin
                minus1 = d1;//d1
                minus2 = yu;//a2
                minus3 = d2;//d2
                minus4 = ~{xul[7],xul} + 1;//-a1
            end
            default:begin
                minus1 = minus1;
                minus2 = minus2;
                minus3 = minus3;
                minus4 = minus4;
            end
        endcase
    end
    else begin
        minus1 = minus1;
        minus2 = minus2;
        minus3 = minus3;
        minus4 = minus4;
    end
end
//==============================================//
//            multiplier accumulator            //
//==============================================// 
integer i;
always @(*) begin
    if(counter == 0) begin // | counter==4
        for(i =0;i<4;i=i+1) begin
            multi_accum1[i] = multi_accum1[i];
        end 
    end 
    else begin
        multi_accum1[counter] = (minus1 * minus2) + (minus3 * minus4);
    end
end
//==============================================//
//            Mode0 signal Control              //
//==============================================// 
assign  reap_stam_left = ((~deltax_left[8] ^ deltay[8]) && (counter == 0))? ((left_bound != left_bound_old)? 1 : (xo_eq_left) ? 0 :reap_stam_left) : 0;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        xo_eq_left <= 0;
    else if(xo == left_bound)
        xo_eq_left <= 1;
    else
        xo_eq_left <= 0;
end

always @(posedge clk or negedge rst_n) begin
    left_bound_old <= left_bound;
end
//==============================================//
//                 Accumulate                   //
//==============================================//  
always @(posedge clk or negedge rst_n) begin //y * dalta_x 
    if(counter==4)
        accum_deltax_left <= 0;    //left_bound
    else if(xo == left_bound && counter == 0 && reap_stam_left!=1)
        accum_deltax_left <= accum_deltax_left + deltax_left;
    else 
        accum_deltax_left <= accum_deltax_left;
end
always @(posedge clk or negedge rst_n) begin //y * dalta_x 
    if(counter==3)
        accum_deltax_right <= deltax_right;
    else if(xo == right_bound && counter == 0) 
        accum_deltax_right <= accum_deltax_right + deltax_right;
    else 
        accum_deltax_right <= accum_deltax_right;
end
//==============================================//
//                    Bound                     //
//==============================================//  
always @(*) begin
    if(counter==2) 
        left_bound <= xi;
    else if(counter == 0) begin 
        if(~deltax_left[8] ^ deltay[8])
            left_bound <= xdl + (accum_deltax_left / deltay);
        else begin
            if((accum_deltax_left % deltay) == 0)
                left_bound <= xdl + (accum_deltax_left / deltay);
            else
                left_bound <= xdl + (accum_deltax_left / deltay) - 1;
        end
    end
end
always @(posedge clk) begin
    if(counter==3) 
        right_bound <= xi;
    else if(xo == right_bound && counter == 0)begin 
        if(~deltax_right[8] ^ deltay[8])
            right_bound <= xdr + (accum_deltax_right / deltay);
        else begin
            if((accum_deltax_right % deltay) == 0)
                right_bound <= xdr + (accum_deltax_right / deltay);
            else
                right_bound <= xdr + (accum_deltax_right / deltay) - 1;
        end
    end
end
//==============================================//
//                   Counter                    //
//==============================================//      
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        counter <= 0;
    else if(in_valid) 
        counter <= counter +1;
    else 
        counter <= 0;
end
//==============================================//
//                     FSM                      //
//==============================================//
//Current state
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        current_state <= IDLE;
    else 
        current_state <= next_state;
end

//Next state
always @(*) begin
    if(!rst_n)
        next_state = IDLE;
    else begin
        case(current_state)
            IDLE: begin
                if(counter == 3)
                    next_state = mode;
                else
                    next_state = IDLE;
            end
            MODE0: begin
                if(counter == 0 && valid_now == 0)
                    next_state = IDLE;
                else
                    next_state = MODE0;
            end
            MODE1: begin
                if(counter == 4)
                    next_state = MODE1;
                else
                    next_state = IDLE;
            end
            MODE2: begin
                if(counter == 4)
                    next_state = MODE2;
                else
                    next_state = IDLE;
            end
            default:next_state = IDLE;
        endcase
    end
end
//==============================================//
//                 Mode0 Ans                     //
//==============================================//
always @(*) begin // * comb
    case(current_state)
        IDLE: begin
            x_now <= 0;
            y_now <= 0;
        end
        MODE0: begin
            if((xo == xur) & (yo == yu))
                valid_now <= 0;
            else if(counter == 4) begin
                valid_now <= 1;
                x_now <= xdl;
                y_now <= yd;
            end
            else if(xo == right_bound) begin
                y_now <= yo + 1;
                x_now <= left_bound;
            end
            else begin
                y_now <= yo;
                x_now <= xo + 1;
            end
        end
        MODE1: begin
            if(counter == 4) begin
                valid_now = 1;
                x_now = 0;
                if(multi_ans1 == multi_ans2) 
                    y_now = 2;
                else if(multi_ans1 < multi_ans2)
                    y_now = 1;
                else
                    y_now = 0;
            end
            else
                valid_now = 0;
        end
        MODE2: begin
            if(counter == 4) begin
                valid_now = 1;
                area_ans_pre = (multi_accum1[1] + multi_accum1[2] + multi_accum1[3] + multi_accum1[4]);
                if(area_ans_pre[16] == 0) 
                    area_ans = (area_ans_pre )>>>1;
                else
                    area_ans = (~(area_ans_pre) + 1)>>>1;

                x_now = area_ans[15:8];
                y_now = area_ans[7:0];
            end
            else
                valid_now = 0;
        end
    endcase
end
//==============================================//
//                   output                     //
//==============================================//
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        out_valid <= 0;
        xo <= 0;
        yo <= 0;
    end
    else begin
        out_valid <= valid_now;
        yo <= y_now;
        xo <= x_now;
    end
end

endmodule

