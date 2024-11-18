//////////////////////////////////////////////////////////////////////////////////
// ID = 1/3 {W [ A ] } 
// if Triode A = 2(V_GS-1) - V_DS^2 , if Saturation A = (V_GS-1)^2
// gm = 2/3 {W [B]}
//if Triode B = V_DS , if Saturation B = (V_GS - 1)
//this module just return A or B
//////////////////////////////////////////////////////////////////////////////////
module ID_gm_Calculation(
    W,
    mode,
    V_GS,
    V_DS,
    ID_gm
    );
input mode; // mode:0  transconductance , mode :1 current
input [2:0] V_GS, V_DS, W;
output [8:0] ID_gm;
//================================================================
//    DESIGN
//================================================================
wire [2:0] VGS_minus1 = V_GS - 1;
wire Tri_Sat = (VGS_minus1 > V_DS)? 1 : 0; // 1:Triode mode  0:Saturation mode

wire [2:0] value = (Tri_Sat)? V_DS : VGS_minus1;
wire [5:0] square_value = value * value;

reg [5:0] ID_gm_temp;
always @(*)begin
    if(!mode) begin //gm
        if(Tri_Sat)
            ID_gm_temp = 2 * V_DS;
        else
            ID_gm_temp = 2 * VGS_minus1;
    end
    else begin //ID
        if(Tri_Sat)
            ID_gm_temp = (VGS_minus1<<1)*V_DS - square_value;
        else
            ID_gm_temp = square_value;
    end
end

assign ID_gm = ID_gm_temp * W;
endmodule
