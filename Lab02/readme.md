#### Performance = Area * Execution Cycles  
### ● my   
#### Execution Cycles = 230 cycles(all pattern is 1 execution Cycles)  
#### Area =  
### ● 演算法架構  
#### Mode0: 透過斜率與當前y座標計算出梯形的兩邊界(y．△x )/△y，並透過加法器在每次更新邊界的前1個cycle做累加，避免了乘法器的使用。  
#### Mode1 & 2: 由於此兩種模式均需要重複使用多次乘加運算，因此利用pipeline的概念，規劃出在不同cycle將訊號送進同1個硬體當中，並共用給兩種Mode使用，用以節省面積。  
### ● 待優化事項  
#### Mode0 與 Mode1&2的reg和wire還可以繼續做硬體共用，另外除法與餘數運算可以透過Call Design ware IP的方式同時計算出來，不必分開運算。  
### ● RTL Simulation Result
----------------------------------------------------------------------------------------------------------------------
                                                  Congratulations!
                                           You have passed all patterns!
                                           Your execution cycles =   230 cycles
                                           Your clock period = 12.0 ns
                                           Total Latency = 2760.0 ns
----------------------------------------------------------------------------------------------------------------------
