#### Performance = Area * Computation time
#### Coputation time = Latency * clock cycle time
### ● my   
#### clock cycle time = 50 ns  
#### Area =  567975.503269
### ● 演算法架構  
#### 使用Systolic Array Weight Stay Stationnary實現，使用9個PE完成Convolution(8個DW_fp_MAC與1個DW_fp_mult)，經過兩層DW_fp_cmp完成Max-Pooling並存於暫存器中，
#### 並於MAC做完Convolution閒置時繼續完成Fully Connected，之後交替使用除法器與MAC完成Normalization，最後輪由使用DW_fp_exp與除法器完成Activation function，並
#### 繼續使用MAC完成L1 distance並輸出。
#### 我認為本次Lab的學習的重點有兩個: 1.在思考演算法時，規劃不同的時序餵入電路中，盡可能的共用硬體 2.在切pipeline時，規劃合理的運算時間，將每個stage切的平均一點。
#### 由於本次Lab使用的Design Ware IP面積較大，因此我只開了一個div與exp並交替使用，以增加2個cycle的代價減少一個(一個div與exp)。
### ● 待優化事項  
#### //
