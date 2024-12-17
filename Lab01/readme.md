#### Specifications : cycle time = 20 ns  
#### Function Validity 70%  
#### Performance area 30% 
### ● my   
#### Performance area = 23897.694559    
### ● lessons learned   
#### 1.透過將演算法中某些運算提前或延後能有效降低硬體資源消耗(e.g. 本次lab中先做完排序完再除法，除了降低每個reg的使用量，也減少一半的除法器數量)   
#### 2.Design Compiler會自動將簡單運算做優化，面對這些運算只須簡單描述即可，不用花太多時間著墨(e.g. 常數乘法不須寫為x<<? + x ，DC會自動優化，且DC優化結果時常更好)
