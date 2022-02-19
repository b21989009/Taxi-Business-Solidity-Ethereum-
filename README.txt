
 Shared Taxi Business 

   By Mehmet Giray Nacakci, 21989009, BBM443 Fall2021 


* If nacakci.sol does not work, the same code is in nacakci.txt


TESTING NOTES
_____________


*  Compiling with solidity 0.8.7, deploying on JavaScript VM (London).

*  Recommended to Deploy with 10000000 gas limit and exactly 0 ether. 

*  No compilation errors. 

*  Runtime testing of functions are successful. 

     How I tested functions ?
     
      -> Select different accounts from drop-down menu to be the message sender.
      -> Write amount of money to send to contract into "VALUE" box.
      -> Enter function parameters in the box next to the function's button. 
      -> click button of function. 


      *  The change in these external test accounts' balances are instantly visible in the drop-down menu. 
     
      *  Use contractBalance() function button to check contract's balance. 
      
      *  Console logs every detail of transactions (calls). 




IMPLEMENTATION DETAILS
______________________


*    I implemented all the functions that are stated in project guide. 

*    Since owner does not have much authority without votes of participants, and participants are not known beforehand, I assumed that the car dealer is the owner (who deploys the contract). 

    
*    Since testing accounts on Remix IDE have only 100 ether initially, for more convenient testing, 
        participationFee is changed from 100 to 10 ether. 
        fixedExpenses    is changed from 10  to 1  ether. 	



*    Clearing previous votes:

    -> How do we delete purchase or repurchase offers when valid time has passed and not enough people voted ? 
    -> How do we eventually get rid of proposeDriver and ProposeFireDriver votings? 

    Solution: Reset votes and proposal data when a new proposal of same kind is called. No need to check time. 



*    Money variables all keep wei. Function inputs receive ether amount and multiply by ether to convert to wei. 

*    Time variables all use unix time in seconds. Multiplied by days when needed. 
    


*    A newly bought car will not need its first maintenance before 6 months. 
          (lines : 178 and 363)

*    A newly hired driver can request their first salary whenever they want. 
          (line : 340)


*    In repurchaseCar(), carDealer buys the car back from contract. Car dealer has to send ether while calling this function.

*    In payDividend(), profit is shared in a way that business will not run out of money. 



