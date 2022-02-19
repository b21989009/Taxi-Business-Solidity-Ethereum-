// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

/*** By Mehmet Giray Nacakci, 21989009, BBM443 Fall2021 */

/* Recommended to Deploy with 10000000 gas limit and exactly 0 ether. */


contract SharedTaxiBusiness{


    address public carDealer; // owner
    // Since owner does not have much authority without votes of participants, and participants are not known beforehand, 
    // I assumed that the car dealer is the owner. 


    uint manuallyUpdated_contractBalance;


    uint participationFee;
    uint fixedExpenses;

    int carID; // 32 digit    
    // This business is assumed to can have only have one Taxi, bacause participants cannot afford to buy a single car on their own. 

    // as seconds since unix epoch
    uint latest_Repair;
    uint latest_ProfitDistribution;
    uint businessLaunchTime;
    uint latest_driverSalaryPay;


    address[] public participants;    

    mapping (address => uint) private participantsBalances;
    mapping (address => bool) private participants_isRegistered;



    struct CarProposal{

        int proposed_carID;
        uint proposed_price;
        uint proposed_offerValidTime_seconds;  
        int approvalVoteCount;
        uint proposalTimestamp;  // as seconds since unix epoch
    }

    CarProposal proposedCar;
    mapping (address => bool) private participants_didTheyVote_forPurchase;


    struct RepurchaseProposal{

        int ownedCarID;
        uint price;
        uint offerValidTime_seconds;
        int approvalVotes;
        bool isApproved;
        uint offeredAt_Timestamp;
    }

    RepurchaseProposal repurchaseProposedCar;
    mapping (address => bool) private participants_didTheyVote_forRepurchase;



    struct DriverProposal{
        address candidateDriver;
        uint driverExpectedSalary;
        int votes;
    }
 
    DriverProposal proposedDriver;
    mapping (address => bool) private participants_didTheyVote_forNewDriver;

    address driverAddress;
    uint driverSalary;
    uint driverBalance;

    int fireDriverVotes;
    mapping (address => bool) private participants_didTheyVote_forFireDriver;




    constructor(){

        carDealer = msg.sender;

        // Since testing accounts have only 100 ether initially,
        participationFee = 10 ether; // For testing purposes, changed from 100 to 10.
        fixedExpenses = 1 ether;     // For testing purposes, changed from 10 to 1.

        businessLaunchTime = block.timestamp;
  
    }



    function join () public payable{
        require( msg.value == participationFee , "Incorrect join fee! Must be exactly 10 ether"); 
        require( participants.length <= 8 , "Max 9 participants can join.");
        require( participants_isRegistered[msg.sender] == false , "This address has already joined.");

        // The contract has implicitly recieved 10 ethers via join() call by the message sender.
        manuallyUpdated_contractBalance += participationFee; 
  
        participants.push(msg.sender);
        participantsBalances[msg.sender] = 0 ;
        participants_isRegistered[msg.sender] = true;

    } 


    function contractBalance() view public returns (uint) {
        return address(this).balance;                  
    }

 
    modifier onlyDealer(){
        require( msg.sender == carDealer , "Only carDealer can call this function !");
        _;
    }


    function carProposeToBusiness(int p_id, uint ether_price, uint p_offerValidTime) public onlyDealer(){
    
        // delete previous votes for purchase
        for (uint index=0 ; index < participants.length ; index++){
            participants_didTheyVote_forPurchase[participants[index]] = false;
        }

        proposedCar = CarProposal(p_id, (ether_price * 1 ether), p_offerValidTime, 0, block.timestamp);
    
    } 


    modifier onlyParticipants(){
        require( participants_isRegistered[msg.sender] == true , "Only participants can call this function !");
        _;
    }

    function approvePurchaseCar () public onlyParticipants(){

        require( participants_didTheyVote_forPurchase[msg.sender] == false , "This participant already voted !");

        proposedCar.approvalVoteCount ++;
        participants_didTheyVote_forPurchase[msg.sender] = true;

        // Can we purchase the car yet? 
        int howManyVotesNeededForMajority = ( int(participants.length) / 2 ) + 1;  // round towards zero
        if ( proposedCar.approvalVoteCount >= howManyVotesNeededForMajority){
            purchaseCar();
        }

    }


    function purchaseCar() internal {
        
        // Are we in time for purchase? 
        uint time_now = block.timestamp;
        uint deadline = proposedCar.proposalTimestamp + proposedCar.proposed_offerValidTime_seconds;
        require( time_now < deadline , "Offer valid time has passed !");

        // Is the transfer doable ? 
        require(manuallyUpdated_contractBalance >= proposedCar.proposed_price, "Not enough money in contract to buy this car !");
        manuallyUpdated_contractBalance -= proposedCar.proposed_price;
        (bool success, ) = payable(carDealer).call{value: proposedCar.proposed_price}("");
        require(success, "Transfer failed.");

        // car is purchased 
        carID = proposedCar.proposed_carID;
        delete proposedCar; 

        latest_Repair = block.timestamp; // Assume that a newly bought car is perfectly working and taxes are just paid. 

    }



    function repurchaseCarPropose(uint ether_price, uint p_offerValidTime) public onlyDealer(){
    
        // delete previous votes for Repurchase
        for (uint index=0 ; index < participants.length ; index++){
            participants_didTheyVote_forRepurchase[participants[index]] = false;
        }

        repurchaseProposedCar = RepurchaseProposal(carID, (ether_price * 1 ether), p_offerValidTime, 0, false, block.timestamp);
    
    } 


    function approveSellProposal() public onlyParticipants(){

        require( participants_didTheyVote_forRepurchase[msg.sender] == false , "This participant already voted !");

        repurchaseProposedCar.approvalVotes ++;
        participants_didTheyVote_forRepurchase[msg.sender] = true;

        // Can dealer Repurchase the car yet? 
        int howManyVotesNeededForMajority = ( int(participants.length) / 2 ) + 1;  // round towards zero
        if ( repurchaseProposedCar.approvalVotes >= howManyVotesNeededForMajority){
            repurchaseProposedCar.isApproved = true;
        }

    }


    /*** Car dealer buys the car back from contract. Car dealer has to send ether while calling this function. */
    function RepurchaseCar() public payable onlyDealer(){

        require( repurchaseProposedCar.isApproved == true , "Offer not approved by participants yet !");
        
        // Are we in time for Repurchase? 
        uint time_now = block.timestamp;
        uint deadline = repurchaseProposedCar.offeredAt_Timestamp + repurchaseProposedCar.offerValidTime_seconds;
        require( time_now < deadline , "Offer valid time has passed !");

        // Transfer (implicit) 
        require( msg.value == repurchaseProposedCar.price, "Dear dealer, please transfer correct amount of ethers !");
        manuallyUpdated_contractBalance += repurchaseProposedCar.price;
   
        // car is sold
        carID = 0;
        delete repurchaseProposedCar; 

    }



    // A new proposal overwrites previous proposal.  
    function proposeDriver(uint expectedSalary_inEther) public {

        // delete previous driver proposal votes
        for (uint index=0 ; index < participants.length ; index++){
            participants_didTheyVote_forNewDriver[participants[index]] = false;
        }

        proposedDriver = DriverProposal(msg.sender, (expectedSalary_inEther * 1 ether) , 0);

    }


    function approveDriver () public onlyParticipants(){

        require( participants_didTheyVote_forNewDriver[msg.sender] == false , "This participant already voted !");
        
        proposedDriver.votes ++;
        participants_didTheyVote_forNewDriver[msg.sender] == true;

        // Approve yet? 
        int howManyVotesNeededForMajority = ( int(participants.length) / 2 ) + 1;  // round towards zero
        if ( proposedDriver.votes >= howManyVotesNeededForMajority){
            setDriver();
        }

    }

    
    function setDriver() internal {

        driverAddress = proposedDriver.candidateDriver; 
        driverSalary = proposedDriver.driverExpectedSalary;
        delete proposedDriver;

    }


    function proposeFireDriver() public onlyParticipants(){

        // delete previous FireDriver votes
        for (uint index=0 ; index < participants.length ; index++){
            participants_didTheyVote_forFireDriver[participants[index]] = false;
        }

        fireDriverVotes = 0;
    }


    function aproveFireDriver() public onlyParticipants(){

        require( participants_didTheyVote_forFireDriver[msg.sender] == false , "This participant already voted !");

        fireDriverVotes ++;
        participants_didTheyVote_forFireDriver[msg.sender] == true;

        // Can we fire the driver yet? 
        int howManyVotesNeededForMajority = ( int(participants.length) / 2 ) + 1;  // round towards zero
        if ( fireDriverVotes >= howManyVotesNeededForMajority){
            fireDriver();
        }

    }

    
    function fireDriver() internal {

        // Is the transfer doable ? 
        require(manuallyUpdated_contractBalance >= driverBalance, "Not enough money in contract to fire (withdraw) driver !");
        manuallyUpdated_contractBalance -= driverBalance;
        (bool success, ) = payable(driverAddress).call{value: driverBalance}("");
        require(success, "Transfer failed.");

        delete driverAddress;
        driverSalary = 0;
        driverBalance = 0;
        fireDriverVotes = 0;
    }


    modifier onlyDriver(){
        require( msg.sender == driverAddress , "Only Driver can call this function !");
        _;
    }


    function leaveJob() public onlyDriver() returns(string memory){

        fireDriver();
        return "Goodbye";
    }


    // Taxi customer pays for their ride
    function getCharge() public payable {

        manuallyUpdated_contractBalance += msg.value;  // implicit transfer, made explicit

    }


    function getSalary() public onlyDriver(){

        // Can call maximum once a month.  
        uint time_now = block.timestamp;
        uint earliestNextSalaryPay = latest_driverSalaryPay + (30 * 1 days);
        // For the first month, since latest_driverSalaryPay is not set yet (0 by default), driver can get their first salary anytime they want. 
        require( time_now > earliestNextSalaryPay , "It is too early for your next salary !");

        driverBalance += driverSalary;

        // Is the transfer doable ? 
        require(manuallyUpdated_contractBalance >= driverBalance, "Not enough money in contract to withdraw driver money !");
        manuallyUpdated_contractBalance -= driverBalance;
        (bool success, ) = payable(driverAddress).call{value: driverBalance}("");
        require(success, "Transfer failed.");

        driverBalance = 0;
        latest_driverSalaryPay = time_now;

    }



    function carExpenses() public onlyParticipants(){
    
        // Can call maximum once every 6 months.  
        uint time_now = block.timestamp;
        uint earliestNextRepair = latest_Repair + (30 * 6 * 1 days);
        // First repair should be at least 6 months after a new car purchase.
        require( time_now > earliestNextRepair , "It is too early for next repair !");
    

        // pay fixedExpenses to CarDealer
        require(manuallyUpdated_contractBalance >= fixedExpenses, "Not enough money in contract for fixed expenses !");
        manuallyUpdated_contractBalance -= fixedExpenses;
        (bool success, ) = payable(carDealer).call{value: fixedExpenses}("");
        require(success, "Transfer failed.");


        latest_Repair = time_now;
    
    }



    function payDividend() public onlyParticipants(){

        require( participants.length > 0 , "There are no participants !");


        // Can call maximum once in 6 months.  
        uint time_now = block.timestamp;
        uint earliest_NextProfitDistribution = latest_ProfitDistribution + (30 * 6 * 1 days);
        // Initially, since latest_ProfitDistribution is not set yet (0 by default), First profit distribution can be anytime they want.  
        require( time_now > earliest_NextProfitDistribution , "It has been less than 6 months since the latest profit distribution !");


        /* PROFIT */

        uint safetyMoney = 10 * 1 ether; // Always leave at least 10 ethers in contract, to keep the business running. Do not share all profit. 
        uint nextSixMonths = driverSalary * 6  + fixedExpenses;  // Also keep in mind the upcoming expenses.   

        uint totalProfitToShare = manuallyUpdated_contractBalance - safetyMoney - nextSixMonths; 
        require( totalProfitToShare > 0 , "This business has not been very profitable recently !");

        // share profit
        uint profitPerParticipant = totalProfitToShare / participants.length;  
        for (uint index=0 ; index < participants.length ; index++){
            participantsBalances[participants[index]] += profitPerParticipant;
        }

    }


    function getDivident() public onlyParticipants(){

        uint callerBalance = participantsBalances[msg.sender];
        require( callerBalance > 0, "Participant balance is empty !");
        require(manuallyUpdated_contractBalance >= callerBalance, "Not enough money in contract to pay participant!");

        manuallyUpdated_contractBalance -= callerBalance;
        (bool success, ) = payable(msg.sender).call{value: callerBalance}("");
        require(success, "Transfer failed.");

        participantsBalances[msg.sender] = 0;

    }


    // Contract receives money
    receive() external payable{}
    fallback() external payable{}


}
