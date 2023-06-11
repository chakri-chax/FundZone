 // SPDX-License-Identifier: MIT

pragma solidity>=0.8.0 <0.9.0;

//******************************************* FLOW OF CODE ***************************************//

// Step 1 : Deploy  ***************** The Deployed One Cosidered as Owner and also Farmer
// Step 2 : Invest  ***************** Investers can be annyone except Owner and must be more than 0 wei
// Step 3 : Deposit ***************** After Work by owner he must deposit funds with Either profit or loss
// Step 4 : Farmer Profit *********** The first step after Deposit is profit shares to Farmer/owner 
// Step 5 : Claim Funds ************* Investers claim their funds 
// Step 6 : Flush to Farmers ******** After claimed by Investers, a small amount wei may remains it flushes to farmer

contract FundsToFarmer {
    uint TotalProfit;
    uint TotalLoss;

    uint Investercount = 0;
    address payable owner;
    address[] iList;

    address payable sendTo;
    uint depositTotalAmount;
    uint resultDepAmt;
    bool deposited = false;
    bool profitTakenByFarmer = false;
    bool Isinvested;
    bool isProfit = false;

    uint public totalInvestAmt;

    uint deployTime;
    uint endTime;

    struct InvesterData {
        address addr;
        string name;
        uint amt;
        uint Investercount;
    }

    constructor() {
        owner = payable(msg.sender);

        deployTime = block.timestamp; //1683804740
        endTime = deployTime + 30 seconds;
    }

    /* ****************************** Mappings ************************************/
    mapping(address => InvesterData) investerInfo;
    mapping(address => uint) Iamt;
    mapping(address => bool) isInvester;
    mapping(address => bool) isClaimed;
    mapping(address => bool) isHeInvest;


    event DepositBy(address from, uint256 amount);
    event InvestBy(address from, uint256 amount);
    event shareProfitsToFarmerBy(uint256 amount);
    event ClaimedDetailsOfInvestor(address from, uint256 amount);

    /* ****************************** Modifiers ************************************/

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not a owner");
        _;
    }
    modifier IsInvester() {
        require(
            isInvester[msg.sender] == true,
            "Sorry, you are not a Invester"
        );
        _;
    }
    modifier moreThanZero() {
        require(msg.value > 0, "Amount must be more than 0 wei");
        _;
    }
    modifier IstimeAvailabe() {
        require(IstimeAvailabeToInvest() == true, "Time up to invest");
        _;
    }
    modifier IsInvestmentOver() {
        require(
            IstimeAvailabeToInvest() == false,
            "Investment time not completed"
        );
        _;
    }
    

    modifier notClaimed() {
        require(
            isClaimed[msg.sender] == false,
            "You already claimed your funds"
        );
        _;
    }

    modifier IsDeposited() {
        require(deposited == true, "Funds Not Yet Deposit by Farmer");
        _;
    }


    modifier ProfitTakenByFarmer() {
        require(
            profitTakenByFarmer == false,
            "You already took the profit, Dont act smart aa!!"
        );
        _;
    }
  

    modifier IsProfitCame() {
        require(isProfit == true, "Profits not available");
        _;
    }

    modifier allInvestersTaken() {
        (Investercount == 0, "Investers still yet not taken Funds");
        _;
    }
    
    modifier OneTimeInvestment() {
        require(
            isHeInvest[msg.sender] == false,
            "Only One Time investemt accepted"
        );
        _;
    }

    /* ******************************Investment Starts ************************************/

    function _1_Invest(string memory _name) public payable moreThanZero IstimeAvailabe OneTimeInvestment {
        require(msg.sender != owner, "Owners not allowed to Invest,sorry");
        InvesterData storage invester = investerInfo[msg.sender];
        invester.addr = msg.sender;
        invester.amt = msg.value;

        iList.push(invester.addr);
        totalInvestAmt += invester.amt;
        owner.transfer(invester.amt);
        invester.Investercount = ++Investercount;
        Iamt[invester.addr] = invester.amt;
        //invester.name = InvesterNameByExternal(invester.Investercount);
        invester.name = _name;
        isInvester[invester.addr] = true;
        isHeInvest[msg.sender] = true;

        emit InvestBy(msg.sender, msg.value);
    }

    function _2_DepositAmount()
        public
        payable
        onlyOwner
        IsInvestmentOver
        moreThanZero
    {
        require(deposited == false, "Already Deposited");
        depositTotalAmount = msg.value;
        resultDepAmt = depositTotalAmount;
        deposited = true;
        

        emit DepositBy(owner, depositTotalAmount);
    }

    function _3_ShareProfitsToFarmer()
        public
        payable
        onlyOwner
        notClaimed
        ProfitTakenByFarmer
    {
        require(depositTotalAmount > totalInvestAmt, "No Profits to share");
        TotalProfit = address(this).balance - totalInvestAmt;
        uint QuarterProfit = TotalProfit / 4;
        owner.transfer(QuarterProfit);
        TotalProfit -= QuarterProfit;
        profitTakenByFarmer = true;

        emit shareProfitsToFarmerBy(QuarterProfit);
    }

    function _4_ClaimFunds()
        public
        payable
        notClaimed
        IsInvester
        IsDeposited
        returns (uint)
    {
        require(msg.sender != owner, "Owners not allowed");
        uint ShareToInvester;

        if (depositTotalAmount > totalInvestAmt) {
            require(
                profitTakenByFarmer == true,
                "profit not yet Taken by Farmer"
            );
            address investor = msg.sender;
            uint InvestByInvester = Iamt[msg.sender]; //Iamt[invester.addr]
            uint BP = setBasisPoints();
            uint TotalProfit = (TotalProfit * BP);
            uint ShareToInvester = (TotalProfit / 1000000000000000000) +
                InvestByInvester;

            address payable toInvester = payable(msg.sender);
            toInvester.transfer(ShareToInvester);
            isClaimed[msg.sender] = true;
            Investercount --;

            emit ClaimedDetailsOfInvestor(msg.sender, ShareToInvester);
        } else if (depositTotalAmount < totalInvestAmt) {
            uint InvestByInvester = Iamt[msg.sender]; //Iamt[invester.addr]
            uint BP = setBasisPoints();
            address payable toInvester = payable(msg.sender);
            uint ShareToInvester;

            TotalLoss = totalInvestAmt - depositTotalAmount;
            TotalLoss = (TotalLoss * BP);
            ShareToInvester =InvestByInvester - (TotalLoss / 1000000000000000000);
            toInvester.transfer(ShareToInvester);
            isClaimed[msg.sender] = true;
            emit ClaimedDetailsOfInvestor(msg.sender, ShareToInvester);
        }

        return (ShareToInvester);
    }

    function _5_FlushToFarmer() public payable onlyOwner  {
        require (Investercount == 0,"Claimed Funds not yet completed by all Investers");
        require (address(this).balance > 0 wei,"No Funds to Flush");
        sendTo = payable(owner);
        sendTo.transfer(address(this).balance);
    }

    //****************** Helper Functions *************************

    function GetInvestorDetails(
        address _addr
    )
        public
        IsInvester
        view
        returns (address, string memory Name, uint Invested, uint Id) 
    {
        InvesterData storage get = investerInfo[_addr];
        uint amt = get.amt;
        uint iId = get.Investercount;
        string memory name = get.name;
        return (_addr, name, amt, iId);
    }

    function setBasisPoints() internal view returns (uint) {
        uint InvestByInvester = Iamt[msg.sender]; //Iamt[invester.addr]
        uint BasisPoints = (InvestByInvester * 1000000000000000000) /
            totalInvestAmt;
        return BasisPoints;
    }

    function IstimeAvailabeToInvest()
        public
        view
        returns (bool TimeAvailbilityIs)
    {
        if (endTime < block.timestamp) {
            bool result = false;
            return result;
        } else if (endTime > block.timestamp) {
            bool result = true;
            return result;
        }
    }
    
    

    function Result()
        public IsDeposited
        view
        returns (uint Total_Investment  , string memory Status , uint ResultIS)
    {
        
        if (resultDepAmt < totalInvestAmt) {
            uint Loss = totalInvestAmt - resultDepAmt;
            string memory result = "Loss";
            return (totalInvestAmt,result,Loss);

        } else if (resultDepAmt > totalInvestAmt) {
            string memory result = "Profit";
            uint profit = resultDepAmt - totalInvestAmt;
            return (totalInvestAmt, result,profit);
        } else {
            string memory result = "neither PROFIT nor LOSS";
            return (totalInvestAmt, result,0);
        }
    }
}
