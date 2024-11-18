`timescale 1ns / 1ps

module SMC(
	// Input Ports
	mode,
	W_0, V_GS_0, V_DS_0,
	W_1, V_GS_1, V_DS_1,
	W_2, V_GS_2, V_DS_2,
	W_3, V_GS_3, V_DS_3,
	W_4, V_GS_4, V_DS_4,
	W_5, V_GS_5, V_DS_5,
	// Output Ports
	out_n
);

//==============================================//
//          Input & Output Declaration          //
//==============================================//
input [2:0] W_0, V_GS_0, V_DS_0;
input [2:0] W_1, V_GS_1, V_DS_1;
input [2:0] W_2, V_GS_2, V_DS_2;
input [2:0] W_3, V_GS_3, V_DS_3;
input [2:0] W_4, V_GS_4, V_DS_4;
input [2:0] W_5, V_GS_5, V_DS_5;
input [1:0] mode;
output [7:0] out_n;         
//================================================================
//    DESIGN
//================================================================
wire [8:0] Id_gm_0, Id_gm_1, Id_gm_2, Id_gm_3, Id_gm_4, Id_gm_5; // maby 6-bits is ok
ID_gm_Calculation CAL0(.W(W_0), .mode(mode[0]), .V_GS(V_GS_0), .V_DS(V_DS_0), .ID_gm(Id_gm_0));
ID_gm_Calculation CAL1(.W(W_1), .mode(mode[0]), .V_GS(V_GS_1), .V_DS(V_DS_1), .ID_gm(Id_gm_1));
ID_gm_Calculation CAL2(.W(W_2), .mode(mode[0]), .V_GS(V_GS_2), .V_DS(V_DS_2), .ID_gm(Id_gm_2));
ID_gm_Calculation CAL3(.W(W_3), .mode(mode[0]), .V_GS(V_GS_3), .V_DS(V_DS_3), .ID_gm(Id_gm_3));
ID_gm_Calculation CAL4(.W(W_4), .mode(mode[0]), .V_GS(V_GS_4), .V_DS(V_DS_4), .ID_gm(Id_gm_4));
ID_gm_Calculation CAL5(.W(W_5), .mode(mode[0]), .V_GS(V_GS_5), .V_DS(V_DS_5), .ID_gm(Id_gm_5));


reg [8:0] ID_gm0, ID_gm1, ID_gm2, ID_gm3, ID_gm4, ID_gm5;
always @(*)begin
    ID_gm0 = Id_gm_0;
    ID_gm1 = Id_gm_1;
    ID_gm2 = Id_gm_2;
    ID_gm3 = Id_gm_3;
    ID_gm4 = Id_gm_4;
    ID_gm5 = Id_gm_5;
end

reg [8:0] sort_temp [0:5];
integer i;
always @(*) begin
    sort_temp[0] = ID_gm0;
    sort_temp[1] = ID_gm1;
    sort_temp[2] = ID_gm2;
    sort_temp[3] = ID_gm3;
    sort_temp[4] = ID_gm4;
    sort_temp[5] = ID_gm5;
    if(sort_temp[1] < sort_temp[5]) begin
		{sort_temp[5],  sort_temp[1]} = 
		{sort_temp[1],  sort_temp[5]};
	end
	else begin
		{sort_temp[5],  sort_temp[1]} = 
		{sort_temp[5],  sort_temp[1]};
	end
	if(sort_temp[0] < sort_temp[4]) begin
		{sort_temp[4],  sort_temp[0]} = 
		{sort_temp[0],  sort_temp[4]};
	end
	else begin
		{sort_temp[4],  sort_temp[0]} = 
		{sort_temp[4],  sort_temp[0]};
	end
	if(sort_temp[3] < sort_temp[5]) begin
		{sort_temp[5],  sort_temp[3]} = 
		{sort_temp[3],  sort_temp[5]};
	end
	else begin
		{sort_temp[5],  sort_temp[3]} = 
		{sort_temp[5],  sort_temp[3]};
	end
	if(sort_temp[2] < sort_temp[4]) begin
		{sort_temp[4],  sort_temp[2]} = 
		{sort_temp[2],  sort_temp[4]};
	end
	else begin
		{sort_temp[4],  sort_temp[2]} = 
		{sort_temp[4],  sort_temp[2]};
	end
	if(sort_temp[1] < sort_temp[3]) begin
		{sort_temp[3],  sort_temp[1]} = 
		{sort_temp[1],  sort_temp[3]};
	end
	else begin
		{sort_temp[3],  sort_temp[1]} = 
		{sort_temp[3],  sort_temp[1]};
	end
	if(sort_temp[0] < sort_temp[2]) begin
		{sort_temp[0],  sort_temp[2]} = 
		{sort_temp[2],  sort_temp[0]};
	end
	else begin
		{sort_temp[0],  sort_temp[2]} = 
		{sort_temp[0],  sort_temp[2]};
	end
	if(sort_temp[4] < sort_temp[5]) begin
		{sort_temp[4],  sort_temp[5]} = 
		{sort_temp[5],  sort_temp[4]};
	end
	else begin
		{sort_temp[4],  sort_temp[5]} = 
		{sort_temp[4],  sort_temp[5]};
	end
	if(sort_temp[2] < sort_temp[3]) begin
		{sort_temp[2],  sort_temp[3]} = 
		{sort_temp[3],  sort_temp[2]};
	end
	else begin
		{sort_temp[2],  sort_temp[3]} = 
		{sort_temp[2],  sort_temp[3]};
	end
	if(sort_temp[0] < sort_temp[1]) begin
		{sort_temp[0],  sort_temp[1]} = 
		{sort_temp[1],  sort_temp[0]};
	end
	else begin
		{sort_temp[0],  sort_temp[1]} = 
		{sort_temp[0],  sort_temp[1]};
	end
	if(sort_temp[1] < sort_temp[4]) begin
		{sort_temp[1],  sort_temp[4]} = 
		{sort_temp[4],  sort_temp[1]};
	end
	else begin
		{sort_temp[1],  sort_temp[4]} = 
		{sort_temp[1],  sort_temp[4]};
	end
	if(sort_temp[3] < sort_temp[4]) begin
		{sort_temp[3],  sort_temp[4]} = 
		{sort_temp[4],  sort_temp[3]};
	end
	else begin
		{sort_temp[3],  sort_temp[4]} = 
		{sort_temp[3],  sort_temp[4]};
	end
	if(sort_temp[1] < sort_temp[2]) begin
		{sort_temp[2],  sort_temp[1]} = 
		{sort_temp[1],  sort_temp[2]};
	end
	else begin
		{sort_temp[2],  sort_temp[1]} = 
		{sort_temp[2],  sort_temp[1]};
	end

	if(mode) begin  //max
		sort_temp[0] = sort_temp[0];
		sort_temp[1] = sort_temp[1];
		sort_temp[2] = sort_temp[2];
	end
	else begin  //min
		sort_temp[0] = sort_temp[3];
		sort_temp[1] = sort_temp[4];
		sort_temp[2] = sort_temp[5];
	end
end

wire [7:0] n_0 = sort_temp[0]/3;
wire [7:0] n_1 = sort_temp[1]/3;
wire [7:0] n_2 = sort_temp[2]/3;

//wire [14:0] out_buff = (mode[0])? 3*n_0 + 4*n_1 + 5*n_2 : 8*(n_0 + n_1 + n_2);
assign out_n =(mode[0])? (3*n_0 + 4*n_1 + 5*n_2 ) / 12 :  (n_0 + n_1 + n_2) / 3;

endmodule
