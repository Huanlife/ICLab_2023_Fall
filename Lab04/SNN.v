//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab04 Exercise		: Siamese Neural Network 
//   Author     		: Ching-Huan He
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : SNN.v
//   Module Name : SNN
//   Release version : V1.0 (Release Date: 2025-01)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module SNN(
    //Input Port
    clk,
    rst_n,
    in_valid,
    Img,
    Kernel,
	Weight,
    Opt,

    //Output Port
    out_valid,
    out
    );

//==============================================//
//             PARAMETER & I/O                  //
//==============================================//
// IEEE floating point parameter
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
//DW_fp_div parameter
parameter faithful_round = 0;
parameter en_ubr_flag = 0;
//DW_fp_exp parameter
parameter inst_arch = 0;


parameter IDLE = 3'd0;
parameter CONV = 3'd1;
parameter CONV2 = 3'd2;
parameter OUT = 3'd3;

integer i;

input rst_n, clk, in_valid;
input [inst_sig_width + inst_exp_width:0] Img, Kernel, Weight;
input [1:0] Opt;

output reg	out_valid;
output reg [inst_sig_width + inst_exp_width:0] out;
//==============================================//
//                     Reg                      //
//==============================================//
reg [5:0] counter1;
reg [1:0] current_state, next_state;
reg [1:0] Opt_buf;
reg [1:0] CONV2_valid;
reg [inst_sig_width+inst_exp_width:0] img_row [0:15];
reg [inst_sig_width+inst_exp_width:0] Weight_buf[0:3];
reg [inst_sig_width+inst_exp_width:0] kernel_buf[0:26]; //supposed  3D [31:0] kernel_buf[0:8] [0:2]
reg [inst_sig_width+inst_exp_width:0] PE_out [0:8];
reg [inst_sig_width+inst_exp_width:0] Feat_Map [0:15]; //Feature Map
reg [inst_sig_width+inst_exp_width:0] Max_pooling [0:3]; //

reg [inst_sig_width+inst_exp_width:0] Cmp_in1, Cmp_in2, Cmp_in3, Cmp_in4;//Comparators input
reg [inst_sig_width+inst_exp_width:0] PE1_input, PE2_input, PE3_input, PE4_input, PE5_input,
    PE6_input, PE7_input, PE8_input, PE9_input; //PE input wire
reg [inst_sig_width+inst_exp_width:0] PE1_kernel, PE2_kernel, PE3_kernel, PE4_kernel, PE5_kernel,
    PE6_kernel, PE7_kernel, PE8_kernel, PE9_kernel; //PE input wire
reg [inst_sig_width+inst_exp_width:0] Partial_Suml, Partial_Sum2, Partial_Sum3, Partial_Sum4, Partial_Sum5,
    Partial_Sum6, Partial_Sum7, Partial_Sum8; //PE input wire
reg [inst_sig_width+inst_exp_width:0] div_Numerator , div_Denominator; //Div input wire
reg [inst_sig_width+inst_exp_width:0] exp_in;//exp input wire
reg [inst_sig_width+inst_exp_width:0] flatten4_value, flatten3_value, flatten2_value, flatten1_value;// flatten value wire
    
wire [3:0] img_address;
wire [inst_sig_width+inst_exp_width:0] PE1_out, PE2_out, PE3_out, PE4_out, PE5_out,
    PE6_out, PE7_out, PE8_out, PE9_out; //PE output wire
//wire kernel_valid;
reg kernel_valid;
wire [inst_sig_width+inst_exp_width:0] conv_ans;
wire [inst_sig_width+inst_exp_width:0] cmp_ans1, cmp_ans2, cmp_ans3, cmp_ans4, cmp_ans5, cmp_ans6, cmp_ans7, cmp_ans8;
wire [inst_sig_width+inst_exp_width:0] div_ans;
wire [inst_sig_width+inst_exp_width:0] exp_out;
wire [inst_sig_width+inst_exp_width:0] flatten4, flatten3, flatten2, flatten1;
wire [inst_sig_width+inst_exp_width:0] min, thi, sec, max;
wire [inst_sig_width+inst_exp_width:0] min_value, thi_value, sec_value, max_value;
//==============================================//
//            Flatten to Avt function           //
//==============================================//
assign max = (counter1 == 52)? Max_pooling[3] : kernel_buf[22];
assign sec = (counter1 == 52)? Max_pooling[2] : kernel_buf[21];
assign thi = (counter1 == 52)? Max_pooling[1] : kernel_buf[20];
assign min = (counter1 == 52)? Max_pooling[0] : kernel_buf[19];

assign max_value = (Opt_buf[1] == 1)? 32'b00111111010000101111011111010110 : 32'b00111111001110110010011010101000;//tanh : segmoid
assign sec_value = (Opt_buf[1] == 1)? kernel_buf[14] : kernel_buf[17];//
assign thi_value = (Opt_buf[1] == 1)? kernel_buf[13] : kernel_buf[15];
assign min_value = (Opt_buf[1] == 1)? 0 : 32'b00111111000000000000000000000000;// 0 : 0.5

assign flatten1 = (CONV2_valid == 3)? kernel_buf[12] : kernel_buf[26];
assign flatten2 = (CONV2_valid == 3)? kernel_buf[11] : kernel_buf[25];
assign flatten3 = (CONV2_valid == 3)? kernel_buf[10] : kernel_buf[24];
assign flatten4 = (CONV2_valid == 3)? kernel_buf[9] : kernel_buf[23];

always @(*)begin
    if(flatten4 == max) begin//mode1
        if(flatten3 == sec) begin//mode1-1
            if(flatten2 == thi)begin
                flatten4_value = max_value;
                flatten3_value = sec_value;
                flatten2_value = thi_value;
                flatten1_value = min_value;
            end
            else begin
                flatten4_value = max_value;
                flatten3_value = sec_value;
                flatten2_value = min_value;
                flatten1_value = thi_value;
            end 
        end
        else if(flatten2 == sec) begin//mode1-2
            if(flatten3 == thi) begin
                flatten4_value = max_value;
                flatten3_value = thi_value;
                flatten2_value = sec_value;
                flatten1_value = min_value;
            end
            else begin
                flatten4_value = max_value;
                flatten3_value = min_value;
                flatten2_value = sec_value;
                flatten1_value = thi_value;
            end
        end
        else begin//mode 1-3
            if(flatten3 == thi) begin
                flatten4_value = max_value;
                flatten3_value = thi_value;
                flatten2_value = min_value;
                flatten1_value = sec_value;
            end
            else begin
                flatten4_value = max_value;
                flatten3_value = min_value;
                flatten2_value = thi_value;
                flatten1_value = sec_value;
            end
        end
    end
    else if(flatten3 == max) begin//mode2
        if(flatten4 == sec) begin//mode2-1
            if(flatten2 == thi)begin
                flatten4_value = sec_value;
                flatten3_value = max_value;
                flatten2_value = thi_value;
                flatten1_value = min_value;
            end
            else begin
                flatten4_value = sec_value;
                flatten3_value = max_value;
                flatten2_value = min_value;
                flatten1_value = thi_value;
            end
        end
        else if(flatten2 == sec) begin//mode2-2
            if(flatten4 == thi)begin
                flatten4_value = thi_value;
                flatten3_value = max_value;
                flatten2_value = sec_value;
                flatten1_value = min_value;
            end
            else begin
                flatten4_value = min_value;
                flatten3_value = max_value;
                flatten2_value = sec_value;
                flatten1_value = thi_value;
            end
        end
        else begin//mode2-3
            if(flatten4 == thi)begin
                flatten4_value = thi_value;
                flatten3_value = max_value;
                flatten2_value = min_value;
                flatten1_value = sec_value;
            end
            else begin
                flatten4_value = min_value;
                flatten3_value = max_value;
                flatten2_value = thi_value;
                flatten1_value = sec_value;
            end
        end
    end
    else if(flatten2 == max)//mode3
        if(flatten4 == sec) begin//mode3-1
            if(flatten3 == thi) begin
                flatten4_value = sec_value;
                flatten3_value = thi_value;
                flatten2_value = max_value;
                flatten1_value = min_value;
            end
            else begin
                flatten4_value = sec_value;
                flatten3_value = min_value;
                flatten2_value = max_value;
                flatten1_value = thi_value;
            end
        end
        else if(flatten3 == sec) begin//mode3-2
            if(flatten4 == thi) begin
                flatten4_value = thi_value;
                flatten3_value = sec_value;
                flatten2_value = max_value;
                flatten1_value = min_value;
            end
            else begin
                flatten4_value = min_value;
                flatten3_value = sec_value;
                flatten2_value = max_value;
                flatten1_value = thi_value;
            end
        end
        else begin//mode 3-3
            if(flatten4 == thi) begin
                flatten4_value = thi_value;
                flatten3_value = min_value;
                flatten2_value = max_value;
                flatten1_value = sec_value;
            end
            else begin
                flatten4_value = min_value;
                flatten3_value = thi_value;
                flatten2_value = max_value;
                flatten1_value = sec_value;
            end
        end
    else begin//mode4
        if(flatten4 == sec) begin//mode4-1
            if(flatten3 == thi) begin
                flatten4_value = sec_value;
                flatten3_value = thi_value;
                flatten2_value = min_value;
                flatten1_value = max_value;
            end
            else begin
                flatten4_value = sec_value;
                flatten3_value = min_value;
                flatten2_value = thi_value;
                flatten1_value = max_value;
            end
        end
        else if(flatten3 == sec) begin//mode 4-2
            if(flatten4 == thi) begin
                flatten4_value = thi_value;
                flatten3_value = sec_value;
                flatten2_value = min_value;
                flatten1_value = max_value;
            end
            else begin
                flatten4_value = min_value;
                flatten3_value = sec_value;
                flatten2_value = thi_value;
                flatten1_value = max_value;
            end
        end
        else begin//mode 4-3
            if(flatten4 == thi) begin
                flatten4_value = thi_value;
                flatten3_value = min_value;
                flatten2_value = sec_value;
                flatten1_value = max_value;
            end
            else begin
                flatten4_value = min_value;
                flatten3_value = thi_value;
                flatten2_value = sec_value;
                flatten1_value = max_value;
            end
        end
    end
end
//==============================================//
//                  Exp Input                   //
//==============================================//
always @(*) begin
    case(counter1)
        39, 46: exp_in = kernel_buf[18];
        40, 47: exp_in = kernel_buf[17];
        41, 48: exp_in = kernel_buf[17];
        default: exp_in = 0;
    endcase
end
//==============================================//
//               Divider Input                  //
//==============================================//
always @(*) begin
    case(counter1)
        38:begin
            div_Numerator = PE_out[3]; //分子
            div_Denominator = PE_out[1]; //分母
        end
        39, 46:begin
            div_Numerator = PE_out[3];
            div_Denominator = PE_out[2]; 
        end
        40, 47:begin
            div_Numerator = 32'b00111111100000000000000000000000; //1
            div_Denominator = kernel_buf[18];   //e^-x1         
        end
        41, 48:begin
            div_Numerator = 32'b00111111100000000000000000000000; //1
            div_Denominator = PE_out[1]; //1+e^-x1  
        end
        42, 49:begin
            div_Numerator = 32'b00111111100000000000000000000000; //1
            div_Denominator = PE_out[1]; //1+e^-x2 
        end
        43, 50:begin
            div_Numerator = PE_out[4];//e^x1-e^-x1
            div_Denominator = PE_out[5]; //e^x1+e^-x1
        end
        44, 51:begin
            div_Numerator = PE_out[7];//e^x2-e^-x2
            div_Denominator = PE_out[8]; //e^x2+e^-x2
        end
        45:begin
            div_Numerator = PE_out[6];//x_min - x_sec
            div_Denominator = PE_out[1]; //x_max - x_min
        end
        default: begin
            div_Numerator = 0;//x_min - x_sec
            div_Denominator = 0; //x_max - x_min
        end
    endcase
end

//==============================================//
//             Comparators Input                //
//==============================================//
always @(*)begin
    if(CONV2_valid == 2) begin
        case(counter1)
            36:begin
                Cmp_in1 = kernel_buf[26];
                Cmp_in2 = kernel_buf[25];
                Cmp_in3 = PE2_out;
                Cmp_in4 = PE4_out;
            end
            40:begin
                Cmp_in1 = Feat_Map[10];
                Cmp_in2 = Feat_Map[11];
                Cmp_in3 = Feat_Map[14];
                Cmp_in4 = Feat_Map[15];
            end
            41:begin
                Cmp_in1 = conv_ans;
                Cmp_in2 = Feat_Map[15];
                Cmp_in3 = Feat_Map[12];
                Cmp_in4 = Feat_Map[11];
            end
            43:begin
                Cmp_in1 = PE2_out;
                Cmp_in2 = PE3_out;
                Cmp_in3 = PE4_out;
                Cmp_in4 = PE5_out;
            end
            default:begin
                Cmp_in1 = Feat_Map[9];
                Cmp_in2 = Feat_Map[10];
                Cmp_in3 = Feat_Map[13];
                Cmp_in4 = Feat_Map[14];
            end
        endcase
    end
    else begin
        Cmp_in1 = Feat_Map[9];
        Cmp_in2 = Feat_Map[10];
        Cmp_in3 = Feat_Map[13];
        Cmp_in4 = Feat_Map[14];
    end
end
//==============================================//
//                Max pooling                   //
//==============================================//
always @(posedge clk) begin
    if((counter1 > 27 && CONV2_valid == 1) || (counter1 < 33 && CONV2_valid == 2) || CONV2_valid == 3) begin
    end
    else if(counter1 == 43)begin  //stay
        Max_pooling[0] <= cmp_ans7;//min
        Max_pooling[1] <= cmp_ans8;//thi
        Max_pooling[2] <= cmp_ans5;//sec 
        Max_pooling[3] <= cmp_ans6;//max
    end
    else if(counter1[2:0] == 3'b001 || counter1 == 19 || counter1 == 27 || counter1 == 35 || counter1 == 40) begin // 17
        Max_pooling[0] <= cmp_ans6;
        Max_pooling[3] <= Max_pooling[0];
        Max_pooling[2] <= Max_pooling[3];
        Max_pooling[1] <= Max_pooling[2];
    end
end
//==============================================//
//                Feature Map                   //
//==============================================//
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0 ; i<16 ; i=i+1)
            Feat_Map[i] <= 0;
    end
    else if(counter1 > 9) begin
        Feat_Map[15] <= conv_ans;
        for(i=2 ; i<16 ; i=i+1) begin
            Feat_Map[i-1] <= Feat_Map[i];
        end
        if(CONV2_valid == 1 && counter1 >24 && counter1 < 41 )
            Feat_Map[0] <= 0;
        else begin
            Feat_Map[0] <= Feat_Map[1];
        end
    end
end
//==============================================//
//            PE Partial Sum input              //
//==============================================//
always @(*) begin
    case(counter1)
        35:begin
            if(CONV2_valid == 2) begin
                Partial_Suml = PE_out[0];
                Partial_Sum2 = 0;
                Partial_Sum3 = PE_out[2];
            end
            else begin
                Partial_Suml = PE_out[0];
                Partial_Sum2 = PE_out[1];
                Partial_Sum3 = PE_out[2];
            end
        end
        42:begin
            if(CONV2_valid == 2) begin
                Partial_Suml = 0;
                Partial_Sum2 = 0;
                Partial_Sum3 = 0;
            end
            else begin
                Partial_Suml = PE_out[0];
                Partial_Sum2 = PE_out[1];
                Partial_Sum3 = PE_out[2];
            end
        end
        default:begin
            Partial_Suml = PE_out[0];
            Partial_Sum2 = PE_out[1];
            Partial_Sum3 = PE_out[2];
        end
    endcase
end
//==============================================//
//              PE Kernel input                 //
//==============================================//
always @(*) begin
    PE1_kernel = kernel_buf[0];
    PE2_kernel = kernel_buf[1];
    PE3_kernel = kernel_buf[2];
    PE4_kernel = kernel_buf[3];
    PE5_kernel = kernel_buf[4];
    PE6_kernel = kernel_buf[5];
    PE7_kernel = kernel_buf[6];
    PE8_kernel = kernel_buf[7];
    PE9_kernel = kernel_buf[8];
end
//==============================================//
//               PE Img input                   //
//==============================================//
always @(*) begin
    case(counter1)
        1, 17, 33: begin
            PE1_input = (in_valid)? img_row[0] : Weight_buf[0];
            PE2_input = img_row[11];
            PE3_input = img_row[11];
            PE4_input = img_row[12];
            PE5_input = img_row[12];
            PE6_input = img_row[11];
            PE7_input = img_row[13];
            PE8_input = img_row[13];
            PE9_input = img_row[13];
        end
        2, 18, 34: begin
            PE1_input = (in_valid)? img_row[0] : Weight_buf[1];
            PE2_input = (in_valid)? img_row[0] : Weight_buf[2];
            PE3_input = img_row[11];
            PE4_input = img_row[13];
            PE5_input = img_row[13];
            PE6_input = img_row[13];
            PE7_input = img_row[14];
            PE8_input = img_row[14];
            PE9_input = img_row[14];
        end
        3, 19, 35:  begin
            PE1_input = (in_valid)? img_row[1] : Weight_buf[0];
            PE2_input = (in_valid)? img_row[1] : Weight_buf[3];
            PE3_input = (in_valid)? img_row[1] : Weight_buf[1];
            PE4_input = img_row[14];
            PE5_input = img_row[14];
            PE6_input = img_row[14];
            PE7_input = img_row[12];
            PE8_input = img_row[15];
            PE9_input = img_row[15];
        end
        4, 20, 36: begin
            PE1_input = img_row[2];
            PE2_input = (in_valid)? img_row[2] : Weight_buf[2];
            PE3_input = img_row[2];
            PE4_input = (in_valid)? img_row[0] : Weight_buf[3];
            PE5_input = img_row[15];
            PE6_input = img_row[15];
            PE7_input = img_row[12];
            PE8_input = img_row[12];
            PE9_input = img_row[15];
        end
        //row2
        5, 21, 37:  begin
            PE1_input = img_row[0];
            PE2_input = (in_valid)? img_row[3] : 32'b10111111100000000000000000000000;// -1 = 1 01111111 00000000000000000000000
            PE3_input = img_row[3];
            PE4_input = (in_valid)? img_row[0] : 32'b10111111100000000000000000000000;// -1
            PE5_input = img_row[0];
            PE6_input = img_row[15];
            PE7_input = img_row[13];
            PE8_input = img_row[13];
            PE9_input = img_row[13];
        end
        6, 22, 38:  begin
            PE1_input = img_row[0];
            PE2_input = img_row[0];
            PE3_input = img_row[3];
            PE4_input = (in_valid)? img_row[1] : 32'b10111111100000000000000000000000;// -1
            PE5_input = img_row[1];
            PE6_input = img_row[1];
            PE7_input = img_row[14];
            PE8_input = img_row[14];
            PE9_input = img_row[14];
        end
        7, 23, 39:  begin
            PE1_input = img_row[1];
            PE2_input = img_row[1];
            PE3_input = img_row[1];
            PE4_input = img_row[2];
            PE5_input = img_row[2];
            PE6_input = img_row[2];
            PE7_input = img_row[4];
            PE8_input = img_row[15];
            PE9_input = img_row[15];
        end
        8, 24, 40:  begin
            PE1_input = img_row[2];
            PE2_input = (in_valid)? img_row[2] : 32'b00111111100000000000000000000000;// +1
            PE3_input = img_row[2];
            PE4_input = img_row[4];
            PE5_input = img_row[3];
            PE6_input = img_row[3];
            PE7_input = img_row[4];
            PE8_input = img_row[4];
            PE9_input = img_row[15];
        end
        //row3
        9, 25, 41:  begin
            PE1_input = img_row[4];
            PE2_input = (in_valid)? img_row[3] : 32'b00111111100000000000000000000000;// +1
            PE3_input = img_row[3];
            PE4_input = img_row[4];
            PE5_input = img_row[4];
            PE6_input = img_row[3];
            PE7_input = img_row[5];
            PE8_input = img_row[5];
            PE9_input = img_row[5];
        end
        10, 26, 42, 49, 55:  begin
            PE1_input = (in_valid)? img_row[4] : Weight_buf[0];
            PE2_input = (in_valid)? img_row[4] : Weight_buf[1];
            PE3_input = (in_valid)? img_row[3] : Weight_buf[0];
            PE4_input = (in_valid)? img_row[5] : Weight_buf[1];
            PE5_input = (in_valid)? img_row[5] : 32'b10111111100000000000000000000000;// -1
            PE6_input = (in_valid)? img_row[5] : 32'b00111111100000000000000000000000;// +1
            PE7_input = img_row[6];
            PE8_input = img_row[6];
            PE9_input = img_row[6];
        end
        11, 27, 43, 50: begin
            PE1_input = img_row[5];
            PE2_input = (in_valid)? img_row[5] : Weight_buf[2];
            PE3_input = (in_valid)? img_row[5] : Weight_buf[3];
            PE4_input = (in_valid)? img_row[6] : Weight_buf[2];
            PE5_input = (in_valid)? img_row[6] : Weight_buf[3];
            PE6_input = img_row[6];
            PE7_input = img_row[8];
            PE8_input = (in_valid)? img_row[7] : 32'b10111111100000000000000000000000;// -1
            PE9_input = (in_valid)? img_row[7] : 32'b00111111100000000000000000000000;// +1
        end
        12, 28, 44: begin
            PE1_input = img_row[6];
            PE2_input = (in_valid)? img_row[6] : 32'b10111111100000000000000000000000;// -1
            PE3_input = img_row[6];
            PE4_input = img_row[8];
            PE5_input = img_row[7];
            PE6_input = img_row[7];
            PE7_input = (in_valid)? img_row[8] : 32'b10111111100000000000000000000000;// -1
            PE8_input = img_row[8];
            PE9_input = img_row[7];
        end
        //row4
        13, 29, 45: begin
            PE1_input = img_row[8];
            PE2_input = img_row[7];
            PE3_input = img_row[7];
            PE4_input = (in_valid)? img_row[8] : 32'b10111111100000000000000000000000;// -1
            PE5_input = img_row[8];
            PE6_input = img_row[7];
            PE7_input = img_row[9];
            PE8_input = img_row[9];
            PE9_input = img_row[9];
        end
        14, 30, 46: begin
            PE1_input = img_row[8];
            PE2_input = img_row[8];
            PE3_input = img_row[7];
            PE4_input = img_row[9];
            PE5_input = img_row[9];
            PE6_input = img_row[9];
            PE7_input = img_row[10];
            PE8_input = img_row[10];
            PE9_input = img_row[10];
        end
        15, 31, 47: begin
            PE1_input = img_row[9];
            PE2_input = (in_valid)? img_row[9] : 32'b00111111100000000000000000000000;// +1
            PE3_input = img_row[9];
            PE4_input = img_row[10];
            PE5_input = img_row[10];
            PE6_input = img_row[10];
            PE7_input = img_row[12];
            PE8_input = img_row[11];
            PE9_input = img_row[11];
        end
        16, 32, 48: begin
            PE1_input = img_row[10];
            PE2_input = (in_valid)? img_row[10] : 32'b00111111100000000000000000000000;// +1
            PE3_input = img_row[10];
            PE4_input = img_row[12];
            PE5_input = img_row[11];
            PE6_input = img_row[11];
            PE7_input = img_row[12];
            PE8_input = img_row[12];
            PE9_input = img_row[11];
        end
        53:begin
            PE1_input = 0;
            PE2_input = 32'b10111111100000000000000000000000;// -1
            PE3_input = 32'b10111111100000000000000000000000;// -1
            PE4_input = 32'b10111111100000000000000000000000;// -1
            PE5_input = 32'b10111111100000000000000000000000;// -1
            PE6_input = 0;
            PE7_input = 0;
            PE8_input = 0;
            PE9_input = 0;
        end
        54:begin
            PE1_input = 0;
            PE2_input = 0;
            PE3_input = 32'b00111111100000000000000000000000;// +1
            PE4_input = 0;
            PE5_input = 32'b00111111100000000000000000000000;// +1
            PE6_input = 0;
            PE7_input = 0;
            PE8_input = 0;
            PE9_input = 0;
        end
        default:begin
            PE1_input = 0;
            PE2_input = 0;
            PE3_input = 0;
            PE4_input = 0;
            PE5_input = 0;
            PE6_input = 0;
            PE7_input = 0;
            PE8_input = 0;
            PE9_input = 0;
        end
    endcase    
end
//==============================================//
//            Partial Sum (PE out)              //
//==============================================// 
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0 ; i<9 ; i=i+1)
            PE_out[i] <= 0;
    end
    //try
    else if((CONV2_valid == 2 || CONV2_valid == 3) && counter1 > 35) begin //36 ~
        case(counter1)
            36:begin
                PE_out[0] <= cmp_ans6;//max
                PE_out[1] <= PE2_out;
                PE_out[2] <= cmp_ans7;//min
                PE_out[3] <= PE4_out;
                PE_out[4] <= PE5_out;
                PE_out[5] <= PE6_out;
                PE_out[6] <= PE7_out;
                PE_out[7] <= PE8_out;
                PE_out[8] <= PE9_out;
            end
            37:begin

                PE_out[1] <= PE2_out;
                PE_out[2] <= kernel_buf[19];//min
                PE_out[3] <= PE4_out;
                
                PE_out[5] <= PE6_out;
                PE_out[6] <= PE7_out;
                PE_out[7] <= PE8_out;
                PE_out[8] <= PE9_out;
            end
            39, 46:begin
                PE_out[0] <= 32'b00111111100000000000000000000000;// +1
                PE_out[7] <= PE8_out;
                PE_out[8] <= PE9_out;
            end
            40, 47:begin
                PE_out[0] <= 32'b00111111100000000000000000000000;// +1
                PE_out[1] <= PE2_out;
                PE_out[2] <= div_ans;
                PE_out[3] <= div_ans;

                PE_out[8] <= PE9_out;
            end
            41, 48:begin
                PE_out[1] <= PE2_out;
                PE_out[3] <= PE4_out;
                PE_out[4] <= PE5_out;
                PE_out[5] <= exp_out;
                PE_out[6] <= exp_out;
            end
            43:begin
                PE_out[0] <= cmp_ans6;//max
                PE_out[1] <= PE2_out;
                PE_out[2] <= PE3_out;
                PE_out[3] <= PE4_out;
                PE_out[4] <= PE5_out;
                PE_out[5] <= cmp_ans7;//min
                PE_out[7] <= PE8_out;
                PE_out[8] <= PE9_out;
            end
            44:begin
                PE_out[1] <= PE2_out;
                PE_out[2] <= Max_pooling[0];
                PE_out[6] <= PE7_out;
            end
            52:begin
                PE_out[0] <= kernel_buf[26];//flatten1-1
                PE_out[1] <= kernel_buf[25];//flatten1-2
                PE_out[2] <= kernel_buf[24];//flatten1-3
                PE_out[3] <= kernel_buf[23];//flatten1-4
            end
            53:begin
                if(PE2_out[31] == 1)
                    PE_out[1] <= {1'b0,PE2_out[30:0]};
                else
                    PE_out[1] <= PE2_out;
                if(PE4_out[31] == 1)
                    PE_out[3] <= {1'b0,PE4_out[30:0]};
                else
                    PE_out[3] <= PE4_out;
            end
            default:begin
                PE_out[0] <= PE1_out;
                PE_out[1] <= PE2_out;
                PE_out[2] <= PE3_out;
                PE_out[3] <= PE4_out;
                PE_out[4] <= PE5_out;
                PE_out[5] <= PE6_out;
                PE_out[6] <= PE7_out;
                PE_out[7] <= PE8_out;
                PE_out[8] <= PE9_out;
            end
        endcase  
    end
    else begin
        PE_out[0] <= PE1_out;
        PE_out[1] <= PE2_out;
        PE_out[2] <= PE3_out;
        PE_out[3] <= PE4_out;
        PE_out[4] <= PE5_out;
        PE_out[5] <= PE6_out;
        PE_out[6] <= PE7_out;
        PE_out[7] <= PE8_out;
        PE_out[8] <= PE9_out;
    end
end

//==============================================//
//                   Counter                    //
//==============================================// 
always @(posedge clk or negedge rst_n) begin
    if(!rst_n )
        counter1 <= 0;
    else if(counter1 == 48 && current_state == CONV) 
        counter1 <= 17;
    else if(in_valid || current_state == CONV2)
        counter1 <= counter1 +1;
    else
        counter1 <= 0;
end
//==============================================//
//            Img, Weight, Opt  Store           //
//==============================================// 
assign img_address = counter1[3:0];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 16; i = i + 1) begin
            img_row[i] <= 0;  // 在 Reset 時清零
        end
    end   
    else if (in_valid) begin
        img_row[img_address] <= Img;  // 更新指定地址的值
    end
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 4; i = i + 1) begin
            Weight_buf[i] <= 0;  // ✅ 確保 Reset
        end
    end
    else if (next_state == CONV && counter1 < 4) begin
        Weight_buf[counter1] <= Weight;  // ✅ 使用 non-blocking，避免競爭
    end
end

always @(posedge clk ) begin
    if(counter1 == 0 && current_state == IDLE)
        Opt_buf <= Opt;
    else begin
    end
end
//==============================================//
//              Kernel Reg Control              //
//==============================================// 
always @(posedge clk or negedge rst_n) begin //避免組合邏輯迴圈
    if (!rst_n)
        kernel_valid <= 0;  // 重置為 0
    else if (counter1 == 31)
        kernel_valid <= 0;  // when counter1 == 31，counter1 == 0
    else if (next_state == CONV && counter1 == 0)
        kernel_valid <= 1;  // 狀態轉移條件滿足，設為 1
    else
        kernel_valid <= kernel_valid;  // 保持當前值
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0 ; i<27; i=i+1) 
            kernel_buf[i] <= 0;
    end
    else if(counter1 < 16 && next_state == CONV)
        kernel_buf[counter1] <= Kernel;
    else begin
        case(counter1)
            16, 32: begin
                if(CONV2_valid == 2 && counter1 == 32)
                    kernel_buf[0] <= Max_pooling[1];
                else begin                        
                    kernel_buf[0] <= kernel_buf[9];
                    kernel_buf[18] <= kernel_buf[0];
                    if(kernel_valid) // curr_state can change n_state
                    kernel_buf[counter1] <= Kernel;
                    else
                    kernel_buf[9] <= kernel_buf[18];
                end
            end
            17, 33: begin
                if(CONV2_valid == 2 && counter1 == 33) begin
                    kernel_buf[0] <= Max_pooling[1];
                    kernel_buf[1] <= Max_pooling[2];
                end
                else begin
                    kernel_buf[1] <= kernel_buf[10];
                    kernel_buf[19] <= kernel_buf[1];
                    if(kernel_valid)
                        kernel_buf[counter1] <= Kernel;
                    else
                        kernel_buf[10] <= kernel_buf[19];
                end
            end
            18, 34: begin
                if(CONV2_valid == 2 && counter1 == 34) begin
                    kernel_buf[0] <= Max_pooling[2];//9.379*10^2
                    kernel_buf[1] <= Max_pooling[1];//9.234*10^2 
                    kernel_buf[2] <= Max_pooling[2];//9.379*10^2

                    kernel_buf[26] <= PE2_out;//Fully Connected1
                end
                else begin
                    kernel_buf[2] <= kernel_buf[11];
                    kernel_buf[20] <= kernel_buf[2];
                    if(kernel_valid)
                        kernel_buf[9] <= Kernel;
                    else
                        kernel_buf[11] <= kernel_buf[20];
                end
            end
            19, 35: begin
                if(CONV2_valid == 2 && counter1 == 35) begin
                    kernel_buf[1] <= Max_pooling[3]; //1.1104*10^3
                    kernel_buf[3] <= Max_pooling[3]; //1.1104*10^3

                    kernel_buf[25] <= PE2_out;//Fully Connected2
                end
                else begin
                    kernel_buf[3] <= kernel_buf[12];
                    kernel_buf[21] <= kernel_buf[3];
                    if(kernel_valid)
                        kernel_buf[10] <= Kernel;
                    else
                        kernel_buf[12] <= kernel_buf[21];
                end
            end
            20, 36: begin
                if(CONV2_valid == 2 && counter1 == 36) begin
                    kernel_buf[1] <= cmp_ans7;//min
                    kernel_buf[3] <= cmp_ans5;//sec

                    kernel_buf[24] <= PE2_out;//Fully Connected3
                    kernel_buf[23] <= PE4_out;//Fully Connected4

                    kernel_buf[22] <= cmp_ans6;
                    kernel_buf[21] <= cmp_ans5;
                    kernel_buf[20] <= cmp_ans8;
                    kernel_buf[19] <= cmp_ans7;
                end
                else begin
                    kernel_buf[4] <= kernel_buf[13];
                    kernel_buf[22] <= kernel_buf[4];
                    if(kernel_valid)
                        kernel_buf[11] <= Kernel;
                    else
                       kernel_buf[13] <= kernel_buf[22];
                end
            end
            21, 37: begin
                if(CONV2_valid == 2 && counter1 == 37) begin   
                    kernel_buf[2] <= 0;//0                                    
                    kernel_buf[3] <= kernel_buf[20];//after Fully Connected third
                end
                else begin
                    kernel_buf[5] <= kernel_buf[14];
                    kernel_buf[23] <= kernel_buf[5];
                    if(kernel_valid)
                        kernel_buf[12] <= Kernel;
                    else
                        kernel_buf[14] <= kernel_buf[23];
                end
            end
            22, 38: begin   
                if(CONV2_valid == 2 && counter1 == 38) begin
                    kernel_buf[18] <= div_ans;//
                end           
                else begin
                    kernel_buf[6] <= kernel_buf[15];
                    kernel_buf[24] <= kernel_buf[6];
                    if(kernel_valid)
                        kernel_buf[13] <= Kernel;
                    else
                        kernel_buf[15] <= kernel_buf[24];
                end
            end
            23, 39, 46: begin
                if(CONV2_valid == 2 && (counter1 == 39 || counter1 == 46)) begin
                    kernel_buf[1] <= exp_out;//e^-x1

                    kernel_buf[17] <= div_ans;
                    kernel_buf[18] <= exp_out;//e^-x1
                end
                else if(counter1 == 46)begin //dont do anything
                end
                else begin
                    kernel_buf[7] <= kernel_buf[16];
                    kernel_buf[25] <= kernel_buf[7];
                    if(kernel_valid)
                        kernel_buf[14] <= Kernel;
                    else
                        kernel_buf[16] <= kernel_buf[25];
                end
            end
            24, 40, 47: begin
                if(CONV2_valid == 2 && (counter1 == 40 || counter1 == 47)) begin
                    kernel_buf[1] <= exp_out;//e^-x2
                    kernel_buf[3] <= 0;
                    kernel_buf[4] <= 0; 

                    kernel_buf[16] <= exp_out;//e^-x2
                    if(kernel_buf[17][31] == 1)
                        kernel_buf[17] <= {1'b0,kernel_buf[17][30:0]};
                    else
                        kernel_buf[17] <= {1'b1,kernel_buf[17][30:0]};
                end
                else if(counter1 == 47)begin //dont do anything
                end
                else begin
                    kernel_buf[8] <= kernel_buf[17];
                    kernel_buf[26] <= kernel_buf[8];
                    if(kernel_valid)
                        kernel_buf[15] <= Kernel;
                    else
                        kernel_buf[17] <= kernel_buf[26];
                end
            end
            41, 48:begin
                if(CONV2_valid == 2 && (counter1 == 41 || counter1 == 48))begin
                    kernel_buf[0] <= Max_pooling[2];
                    kernel_buf[1] <= Max_pooling[2];
                    kernel_buf[2] <= Max_pooling[0];
                    kernel_buf[3] <= Max_pooling[0];

                    kernel_buf[4] <= kernel_buf[18];//e^-x1,1
                    kernel_buf[5] <= kernel_buf[18];
                    kernel_buf[6] <= 0;
                    kernel_buf[7] <= 0;

                    kernel_buf[17] <= div_ans;// 1/(1+e^-x1)
                end
                else if(counter1 == 48) begin
                    kernel_buf[0] <= kernel_buf[9];
                    kernel_buf[18] <= kernel_buf[0];
                    kernel_buf[9] <= kernel_buf[18];
                end
                else begin
                end
            end
            42, 49:begin
                if(CONV2_valid == 2 || CONV2_valid == 3)begin
                    kernel_buf[1] <= Max_pooling[2];
                    kernel_buf[2] <= Max_pooling[2];
                    kernel_buf[3] <= Max_pooling[0];
                    kernel_buf[4] <= Max_pooling[0];

                    kernel_buf[7] <= kernel_buf[16];//e^-x2,1
                    kernel_buf[8] <= kernel_buf[16];

                    kernel_buf[15] <= div_ans;//1/(1+e^-x2)
                end
                else begin
                end
            end
            43:begin
                if(CONV2_valid == 2)begin
                    kernel_buf[1] <= cmp_ans7;//min
                    kernel_buf[6] <= cmp_ans5;//sec

                    kernel_buf[14] <= div_ans;// (e^x1,1-e^-x1,1)/(e^x1,1+e^-x1,1)

                    kernel_buf[12] <= PE2_out;//Fully Connected1
                    kernel_buf[11] <= PE3_out;//Fully Connected2
                    kernel_buf[10] <= PE4_out;//Fully Connected3
                    kernel_buf[9] <= PE5_out;//Fully Connected4
                end
                else begin
                end
            end
            44, 51:begin
                if(CONV2_valid == 2 || CONV2_valid == 3)begin
                    kernel_buf[2] <= 0;
                    kernel_buf[3] <= Max_pooling[1];//thi
                    kernel_buf[13] <= div_ans;// (e^x2,1-e^-x2,1)/(e^x2,1+e^-x2,1)
                end
                else begin
                end
            end
            45:begin
                if(CONV2_valid == 2)begin
                    kernel_buf[18] <= div_ans;// (x_min - x_sec)/(x_max - x_min)

                    kernel_buf[26] <= flatten1_value;
                    kernel_buf[25] <= flatten2_value;
                    kernel_buf[24] <= flatten3_value;
                    kernel_buf[23] <= flatten4_value;
                end
                else begin
                end
            end
            52:begin
                kernel_buf[1] <= flatten1_value;
                kernel_buf[2] <= flatten2_value;
                kernel_buf[3] <= flatten3_value;
                kernel_buf[4] <= flatten4_value;

                kernel_buf[12] <= flatten1_value;
                kernel_buf[11] <= flatten2_value;
                kernel_buf[10] <= flatten3_value;
                kernel_buf[9]  <= flatten4_value;
            end
            53:begin
                if(PE3_out[31] == 1)
                    kernel_buf[2] <= {1'b0,PE3_out[30:0]};
                else
                    kernel_buf[2] <= PE3_out;
                if(PE5_out[31] == 1)
                    kernel_buf[4] <= {1'b0,PE5_out[30:0]};
                else
                    kernel_buf[4] <= PE5_out;
            end
            54:begin
                kernel_buf[5] <= PE3_out;
            end

            // only save
            25: begin
                if(kernel_valid)
                    kernel_buf[16] <= Kernel;
                else begin
                end
            end
            26: begin
                if(kernel_valid)
                    kernel_buf[17] <= Kernel;
                else begin
                end
            end
        endcase
    end
end
//==============================================//
//            FSM Signal Control                //
//==============================================//
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        CONV2_valid <= 0;
    else if(counter1 == 48)
        CONV2_valid <= CONV2_valid + 1;
    else begin
    end
end
//==============================================//
//                  FSM                         //
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
    case(current_state)
        IDLE: begin
            if(in_valid)
                next_state = CONV;
            else
                next_state = IDLE;
        end
        CONV: begin
            if(CONV2_valid == 2)
                next_state = CONV2;
            else
                next_state = CONV;
        end
        CONV2: begin
            if(counter1 == 54)
                next_state = OUT;
            else
                next_state = CONV2;
        end
        OUT: next_state = IDLE;
        default: next_state = IDLE;
    endcase
end
//==============================================//
//                 Output                       //
//==============================================//
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        out_valid <= 0;
        out <= 0;
    end
    else if(counter1 == 55) begin
        out_valid <= 1;
        out <= PE6_out;
    end
    else begin
        out_valid <= 0;
        out <= 0;
    end
end
//==============================================//
//               DesignWare IP                  //
//==============================================//
// Instance of DW_fp_mult
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance, en_ubr_flag) U_PE1 ( 
            .a(PE1_input),    
            .b(PE1_kernel), 
            .rnd(3'b0), 
            .z(PE1_out), 
            .status() );
// Instance of DW_fp_mac
DW_fp_mac #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U_PE2 (
			.a(PE2_input),
			.b(PE2_kernel),
			.c(Partial_Suml),
			.rnd(3'b0),
			.z(PE2_out),
			.status() );
DW_fp_mac #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U_PE3 (
			.a(PE3_input),
			.b(PE3_kernel),
			.c(Partial_Sum2),
			.rnd(3'b0),
			.z(PE3_out),
			.status() );
DW_fp_mac #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U_PE4 (
			.a(PE4_input),
			.b(PE4_kernel),
			.c(Partial_Sum3),
			.rnd(3'b0),
			.z(PE4_out),
			.status() );
DW_fp_mac #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U_PE5 (
			.a(PE5_input),
			.b(PE5_kernel),
			.c(PE_out[3]),
			.rnd(3'b0),
			.z(PE5_out),
			.status() );
DW_fp_mac #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U_PE6 (
			.a(PE6_input),
			.b(PE6_kernel),
			.c(PE_out[4]),
			.rnd(3'b0),
			.z(PE6_out),
			.status() );
DW_fp_mac #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U_PE7 (
			.a(PE7_input),
			.b(PE7_kernel),
			.c(PE_out[5]),
			.rnd(3'b0),
			.z(PE7_out),
			.status() );
DW_fp_mac #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U_PE8 (
			.a(PE8_input),
			.b(PE8_kernel),
			.c(PE_out[6]),
			.rnd(3'b0),
			.z(PE8_out),
			.status() );
DW_fp_mac #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U_PE9 (
			.a(PE9_input),
			.b(PE9_kernel),
			.c(PE_out[7]),
			.rnd(3'b0),
			.z(PE9_out),
			.status() );
// Instance of DW_fp_add
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)  U_add ( 
            .a(PE_out[8]), 
            .b(Feat_Map[0]), 
            .rnd(3'b0), 
            .z(conv_ans), 
            .status() );
//DW_fp_cmp
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U_COMP1 ( 
            .a(Cmp_in1),
            .b(Cmp_in2), 
            .zctr(1'b0), 
            .aeqb(), 
		    .altb(), 
            .agtb(), 
            .unordered(), 
		    .z0(cmp_ans1), 
            .z1(cmp_ans2), //big
            .status0(), 
		    .status1() );
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U_COMP2 ( 
            .a(Cmp_in3), 
            .b(Cmp_in4), 
            .zctr(1'b0), 
            .aeqb(), 
		    .altb(), 
            .agtb(), 
            .unordered(), 
		    .z0(cmp_ans3), //small
            .z1(cmp_ans4), //big
            .status0(), 
		    .status1() );
            
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U_COMP3 ( 
            .a(cmp_ans2), 
            .b(cmp_ans4), 
            .zctr(1'b0), 
            .aeqb(), 
		    .altb(), 
            .agtb(), 
            .unordered(), 
		    .z0(cmp_ans5), //second
            .z1(cmp_ans6), //big (max)
            .status0(), 
		    .status1() );   
DW_fp_cmp #(inst_sig_width, inst_exp_width, inst_ieee_compliance) U_COMP4 ( 
            .a(cmp_ans1), 
            .b(cmp_ans3), 
            .zctr(1'b0), 
            .aeqb(), 
		    .altb(), 
            .agtb(), 
            .unordered(), 
		    .z0(cmp_ans7), //min
            .z1(cmp_ans8), //third
            .status0(), 
		    .status1() );     
// Instance of DW_fp_div
DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, faithful_round, en_ubr_flag) U_div ( 
            .a(div_Numerator), 
            .b(div_Denominator), 
            .rnd(3'b0), 
            .z(div_ans), 
            .status() );
// Instance of DW_fp_exp
DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) U_exp (
			.a(exp_in),
			.z(exp_out),
			.status() );
          
endmodule
