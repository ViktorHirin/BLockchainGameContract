// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TriviaGame {

    address public m_admin = address(0x888a5aE84c92814d51DA6b18Ef8AA1313c0F408b); // admin wallet address
    address public m_manager;
    uint256 public m_gameId = 0;   // Game ID
    uint256 public minBetAmount = 100 * 1e18;
    address coinAddress;
    event SendGameId(uint256 _id);

    struct User {
        uint256 gameId;
        string name;
        address addr;
        uint256 startTimeStamp;
        uint256 closeTimeStamp;
        uint256 spendAmount;
        uint256 rewardAmount;
    }

    User[] public users;
    mapping(uint256 => User) public userInfo;
   
    constructor() {
        m_manager = payable(msg.sender);
    }

    modifier onlyByOwner {
        require(msg.sender == m_manager, "Unauthorised Access!");
        _;
    }

    function startRound(string memory _name, uint256 _betAmount) public returns (uint256){
        require(_betAmount >= minBetAmount, "Token amount must be greater than 100 $Lemonz");
        m_gameId += 1;
        payWithLemonHaze(msg.sender, m_admin, _betAmount);
        User storage user = userInfo[m_gameId];
        user.name = _name;
        user.gameId = m_gameId;
        user.addr = msg.sender;
        user.spendAmount = _betAmount;
        user.startTimeStamp = block.timestamp;
        users.push(user);
        emit SendGameId(m_gameId);
        return m_gameId;
    }

    function endRound(uint256 _gameId, uint256 _reward) public {
        require(_gameId > 0, "Game Id is required");
        userInfo[_gameId].rewardAmount = _reward;
        userInfo[_gameId].closeTimeStamp = block.timestamp;
        users[_gameId - 1].rewardAmount = _reward;
        users[_gameId - 1].closeTimeStamp = block.timestamp;
        claim(userInfo[_gameId].addr, _reward);
    }

    function payWithLemonHaze(address _from, address _to, uint256 _amount) internal {
        IERC20 LemonHaze = IERC20(coinAddress);
        uint256 allowance = LemonHaze.allowance(_from, address(this));
        require(allowance >= _amount, "The amount of tokens are smaller than allowed amount");
        require(LemonHaze.balanceOf(_from) >= _amount, "balance is too small, you can't pay for playing a game.");
        LemonHaze.transferFrom(_from, _to, _amount);
    }

    function claim(address _to, uint256 _amount) internal {
        IERC20 LemonHaze = IERC20(coinAddress);
        require(LemonHaze.balanceOf(address(this)) >= _amount, "The balance of Game contract is too small, you can't reward coins now.");
        LemonHaze.transfer(_to, _amount);
    }

    function setAdminAddress(address _address) public onlyByOwner {
        m_admin = payable(_address);
    }

    function setMinBetAmount(uint256 _amount) public onlyByOwner {
        minBetAmount = _amount;
    }

    function getAdminAddress() public view returns(address) {
        return m_admin;
    }

    function setCoinAddress(address _address) public onlyByOwner {
        coinAddress = _address;
    }


    function getUsers() public view returns (User[] memory) {
        return users;
    }

    function getBalanceOfCoin() public view returns (uint256) {
        IERC20 LemonHaze = IERC20(coinAddress);
        return LemonHaze.balanceOf(address(this));
    }

}