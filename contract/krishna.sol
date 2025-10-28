// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title CrowdFundChain
 * @dev A decentralized crowdfunding platform for transparent project funding
 */
contract CrowdFundChain {
    
    struct Campaign {
        address payable creator;
        string title;
        string description;
        uint256 goalAmount;
        uint256 raisedAmount;
        uint256 deadline;
        bool withdrawn;
        bool active;
    }
    
    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => mapping(address => uint256)) public contributions;
    
    uint256 public campaignCount;
    
    event CampaignCreated(
        uint256 indexed campaignId,
        address indexed creator,
        string title,
        uint256 goalAmount,
        uint256 deadline
    );
    
    event ContributionMade(
        uint256 indexed campaignId,
        address indexed contributor,
        uint256 amount
    );
    
    event FundsWithdrawn(
        uint256 indexed campaignId,
        address indexed creator,
        uint256 amount
    );
    
    event RefundIssued(
        uint256 indexed campaignId,
        address indexed contributor,
        uint256 amount
    );
    
    /**
     * @dev Create a new crowdfunding campaign
     * @param _title Campaign title
     * @param _description Campaign description
     * @param _goalAmount Funding goal in wei
     * @param _durationInDays Campaign duration in days
     */
    function createCampaign(
        string memory _title,
        string memory _description,
        uint256 _goalAmount,
        uint256 _durationInDays
    ) public returns (uint256) {
        require(_goalAmount > 0, "Goal amount must be greater than 0");
        require(_durationInDays > 0, "Duration must be greater than 0");
        require(bytes(_title).length > 0, "Title cannot be empty");
        
        uint256 deadline = block.timestamp + (_durationInDays * 1 days);
        
        campaigns[campaignCount] = Campaign({
            creator: payable(msg.sender),
            title: _title,
            description: _description,
            goalAmount: _goalAmount,
            raisedAmount: 0,
            deadline: deadline,
            withdrawn: false,
            active: true
        });
        
        emit CampaignCreated(
            campaignCount,
            msg.sender,
            _title,
            _goalAmount,
            deadline
        );
        
        campaignCount++;
        return campaignCount - 1;
    }
    
    /**
     * @dev Contribute funds to a campaign
     * @param _campaignId The ID of the campaign to contribute to
     */
    function contribute(uint256 _campaignId) public payable {
        Campaign storage campaign = campaigns[_campaignId];
        
        require(campaign.active, "Campaign is not active");
        require(block.timestamp < campaign.deadline, "Campaign has ended");
        require(msg.value > 0, "Contribution must be greater than 0");
        
        contributions[_campaignId][msg.sender] += msg.value;
        campaign.raisedAmount += msg.value;
        
        emit ContributionMade(_campaignId, msg.sender, msg.value);
    }
    
    /**
     * @dev Withdraw funds if campaign goal is reached (creator only)
     * @param _campaignId The ID of the campaign
     */
    function withdrawFunds(uint256 _campaignId) public {
        Campaign storage campaign = campaigns[_campaignId];
        
        require(msg.sender == campaign.creator, "Only creator can withdraw");
        require(campaign.active, "Campaign is not active");
        require(block.timestamp >= campaign.deadline, "Campaign is still ongoing");
        require(campaign.raisedAmount >= campaign.goalAmount, "Goal not reached");
        require(!campaign.withdrawn, "Funds already withdrawn");
        
        campaign.withdrawn = true;
        campaign.active = false;
        
        uint256 amount = campaign.raisedAmount;
        campaign.creator.transfer(amount);
        
        emit FundsWithdrawn(_campaignId, campaign.creator, amount);
    }
    
    /**
     * @dev Get refund if campaign goal is not reached
     * @param _campaignId The ID of the campaign
     */
    function getRefund(uint256 _campaignId) public {
        Campaign storage campaign = campaigns[_campaignId];
        
        require(block.timestamp >= campaign.deadline, "Campaign is still ongoing");
        require(campaign.raisedAmount < campaign.goalAmount, "Goal was reached");
        require(contributions[_campaignId][msg.sender] > 0, "No contribution found");
        
        uint256 contributedAmount = contributions[_campaignId][msg.sender];
        contributions[_campaignId][msg.sender] = 0;
        
        campaign.active = false;
        payable(msg.sender).transfer(contributedAmount);
        
        emit RefundIssued(_campaignId, msg.sender, contributedAmount);
    }
    
    /**
     * @dev Get campaign details
     * @param _campaignId The ID of the campaign
     */
    function getCampaign(uint256 _campaignId) public view returns (
        address creator,
        string memory title,
        string memory description,
        uint256 goalAmount,
        uint256 raisedAmount,
        uint256 deadline,
        bool withdrawn,
        bool active
    ) {
        Campaign storage campaign = campaigns[_campaignId];
        return (
            campaign.creator,
            campaign.title,
            campaign.description,
            campaign.goalAmount,
            campaign.raisedAmount,
            campaign.deadline,
            campaign.withdrawn,
            campaign.active
        );
    }
    
    /**
     * @dev Get contributor's contribution amount
     * @param _campaignId The ID of the campaign
     * @param _contributor Address of the contributor
     */
    function getContribution(uint256 _campaignId, address _contributor) 
        public 
        view 
        returns (uint256) 
    {
        return contributions[_campaignId][_contributor];
    }
}
