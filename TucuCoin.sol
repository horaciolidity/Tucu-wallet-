/**
 *Submitted for verification at polygonscan.com on 2024-05-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TucuCoin {
    string public name = "TucuCoin";
    string public symbol = "Tucu";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 private _reward;
    uint256 private _buyFee;
    uint256 private _sellFee;
    uint256 private _rewardSetTime;
    address public owner;
    bool private paused = false;

    mapping(address => uint256) public balanceOf;
    mapping(address => bool) private hasClaimedReward;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event RewardSet(uint256 reward);
    event BuyFeeSet(uint256 buyFee);
    event SellFeeSet(uint256 sellFee);
    event Minted(address indexed account, uint256 amount);
    event Burned(address indexed account, uint256 amount);
    event FeeTaken(address indexed from, uint256 amount, string feeType);
    event RewardClaimed(address indexed account, uint256 amount);
    event Paused();
    event Unpaused();

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier nonReentrant() {
        uint256 _status;
        require(_status != 1, "ReentrancyGuard: reentrant call");
        _status = 1;
        _;
        _status = 0;
    }

    modifier onlyNonContract() {
        require(tx.origin == msg.sender, "Contract calls are not allowed");
        _;
    }

    constructor() {
        owner = msg.sender;
        _mint(owner, 1000000 * 10 ** uint256(decimals)); // Initial supply of 1 million Tucu
    }

    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "ERC20: mint to the zero address");
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function mint(address to, uint256 amount) external onlyOwner whenNotPaused {
        _mint(to, amount);
        emit Minted(to, amount);
    }

    function burn(uint256 amount) external onlyNonContract whenNotPaused {
        _burn(msg.sender, amount);
        emit Burned(msg.sender, amount);
    }

    function _burn(address from, uint256 amount) internal {
        require(from != address(0), "ERC20: burn from the zero address");
        require(balanceOf[from] >= amount, "ERC20: burn amount exceeds balance");
        balanceOf[from] -= amount;
        totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }

    function setReward(uint256 reward) external onlyOwner {
        _reward = reward;
        _rewardSetTime = block.timestamp;
        emit RewardSet(reward);
    }

    function setBuyFee(uint256 buyFee) external onlyOwner {
        _buyFee = buyFee;
        emit BuyFeeSet(buyFee);
    }

    function setSellFee(uint256 sellFee) external onlyOwner {
        _sellFee = sellFee;
        emit SellFeeSet(sellFee);
    }

    function transfer(address recipient, uint256 amount) public whenNotPaused nonReentrant returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(balanceOf[sender] >= amount, "ERC20: transfer amount exceeds balance");

        uint256 fee = _buyFee;
        if (recipient == owner) {
            fee = _sellFee;
        }

        if (fee > 0) {
            uint256 feeAmount = (amount * fee) / 10000;
            amount -= feeAmount;
            balanceOf[sender] -= feeAmount;
            balanceOf[owner] += feeAmount;
            emit Transfer(sender, owner, feeAmount);
            emit FeeTaken(sender, feeAmount, recipient == owner ? "sell" : "buy");
        }

        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function claimReward() external whenNotPaused nonReentrant {
        require(!hasClaimedReward[msg.sender], "Reward already claimed");
        hasClaimedReward[msg.sender] = true;
        _mint(msg.sender, _reward);
        emit RewardClaimed(msg.sender, _reward);
    }

    function withdraw(uint256 amount) external onlyOwner nonReentrant {
        require(address(this).balance >= amount, "Insufficient balance");
        payable(msg.sender).transfer(amount);
    }

    function pause() external onlyOwner {
        paused = true;
        emit Paused();
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused();
    }

    receive() external payable {
        require(msg.value > 0, "Cannot deposit 0");
        // Custom logic for deposit handling
    }
}
