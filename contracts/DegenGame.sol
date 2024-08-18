// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/*
Your task is to create a ERC20 token and deploy it on the Avalanche network for Degen Gaming. The smart contract should have the following functionality:

Minting new tokens: The platform should be able to create new tokens and distribute them to players as rewards. Only the owner can mint tokens.
Transferring tokens: Players should be able to transfer their tokens to others.
Redeeming tokens: Players should be able to redeem their tokens for items in the in-game store.
Checking token balance: Players should be able to check their token balance at any time.
Burning tokens: Anyone should be able to burn tokens, that they own, that are no longer needed.
*/


import "contracts/Err.sol";
import "contracts/Degen.sol";

contract DegenGame is Degen {

    address public owner;
    Player[] allPlayers;

    enum Level {
        BEGINNER,
        INTERMEDIATE,
        PRO
    }

    struct Player {
        address playerId;
        string playerNick;
        Level level;
        uint256 registerAt;
        bool isRegistered;
    }

    struct GameProp {
        address currentOwner;
        bytes32 propId;
        string propName;
        uint256 worth;
    }

    mapping(address => Player) public players;
    mapping(bytes32 => GameProp) public gameProps;
    mapping(address => mapping(bytes32 => GameProp)) public playerProps;

    event PlayerRegisters(address player, bool success);
    event RewardDistributed(Player[] allPlayers, uint256 totalRewards, uint256 arrayLenth);
    event PlayerP2P(address sender, address recipient, uint256 amount);
    event TokenBurnt(address owner, uint256 _amount);
    event PropCreated(address currentOwner, string _propName, bytes32 propId, uint256 _worth);
    event PropBought(address newOwner, bytes32 _propId, string propName);


    constructor () Degen() {
        owner = msg.sender;
    }

    function addressZeroCheck() private view {
        if (msg.sender == address(0)) revert Err.ZERO_ADDRESS_NOT_ALLOWED();
    }

    function isRegistered() private view {
        if (!players[msg.sender].isRegistered) revert Err.YOU_ARE_NOT_REGISTERED();
    }

    function playerRegister(string memory _playerNick) external {
        addressZeroCheck();
        if (players[msg.sender].playerId != address(0)) revert Err.YOU_HAVE_REGISTERED();
        if (msg.sender == s_owner) revert Err.OWNER_CANNOT_REGISTER();

        Player storage _player = players[msg.sender];
        _player.playerId = msg.sender;
        _player.playerNick = _playerNick;
        _player.level = Level.BEGINNER;
        _player.registerAt = block.timestamp;
        _player.isRegistered = true;

        allPlayers.push(_player);

        emit PlayerRegisters(msg.sender, true);
    }

    //this is just to simulate player level change
    function changePlayerLevel(address _playerId, Level _level) external {
        onlyOwner();
        players[_playerId].level = _level;
    }

    function ditributeRewardToPlayers() external {
        onlyOwner();
        if (allPlayers.length <= 0) revert Err.N0_PLAYERS_TO_REWARD();
        uint256 totalRewards;

        for (uint8 i = 0; i < allPlayers.length; i++) {
            Player memory _player = players[allPlayers[i].playerId];
            Level _level = _player.level;

            if (_level == Level.PRO) {
                uint _amount = 1000 * 5;
                mint(_player.playerId, _amount);
                totalRewards += _amount;
            } else if (_level == Level.INTERMEDIATE) {
                uint _amount = 1000 * 3;
                mint(_player.playerId, _amount);
                totalRewards += _amount;
            } else if (_level == Level.BEGINNER) {
                uint _amount = 1000;
                mint(_player.playerId, _amount);
                totalRewards += _amount;
            }
        }

        //Note, allPlayers array is not updated. I just used it to get the length
        emit RewardDistributed(allPlayers, totalRewards, allPlayers.length);
    }


    function playerP2PTransfer(address _recipient, uint256 _amount) external returns (bool) {
        addressZeroCheck();
        isRegistered();

        if (transfer(_recipient, _amount)) {
            emit PlayerP2P(msg.sender, _recipient, _amount);
            return true;
        }

        revert Err.TRANSFER_FAILED();
    }


    function playerCheckTokenBalance() external view returns (uint256) {
        addressZeroCheck();
        isRegistered();

        return balanceOf(msg.sender);
    }

    function suspendPlayer(address player) external {
        onlyOwner();
        Player storage _player = players[player];
        if (_player.playerId == address(0) || !_player.isRegistered) revert Err.PLAYER_DOES_NOT_EXIST();

        _player.isRegistered = false;
    }

    function forgivePlayer(address player) external {
        onlyOwner();
        Player storage _player = players[player];
        if (_player.playerId == address(0)) revert Err.PLAYER_DOES_NOT_EXIST();
        if (_player.isRegistered) revert Err.PLAYER_NOT_SUSPENDED();

        _player.isRegistered = true;
    }

    function playerBurnsTheirToken(uint256 _amount) external {
        addressZeroCheck();
        isRegistered();

        burn(_amount);

        emit TokenBurnt(msg.sender, _amount);
    }


    function addGameProp(string calldata _propName, uint256 _worth) external {
        onlyOwner();

        bytes32 propId = keccak256(abi.encodePacked(_propName, _worth));
        GameProp storage _gameStorage = gameProps[propId];
        _gameStorage.currentOwner = address(this);
        _gameStorage.propId = propId;
        _gameStorage.propName = _propName;
        _gameStorage.worth = _worth;


        emit PropCreated(address(this), _propName, propId, _worth);
    }

    function playerBuysProp(bytes32 _propId) external {
        isRegistered();

        GameProp storage _gameProp = gameProps[_propId];

        if (_gameProp.currentOwner == address(0)) revert Err.PROP_DOES_NOT_EXIST();

        uint256 propWorth = _gameProp.worth;

        if (balanceOf(msg.sender) < propWorth) revert Err.INSUFFICIENT_BALANCE();

        transfer(address(this), propWorth);

        _gameProp.currentOwner = msg.sender;

        playerProps[msg.sender][_propId] = _gameProp;

        emit PropBought(msg.sender, _propId, _gameProp.propName);
    }
}