// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DegenGame is ERC20, Ownable {

    Player[] allPlayers;

    struct Player {
        address player;
        string username;
        bool isRegistered;
    }

    struct GameItem {
        address owner;
        uint256 itemId;
        string name;
        uint256 amount;
    }

    mapping(address => Player) public players;
    mapping(uint256 => GameItem) public gameItems;
    mapping(address => mapping (uint256 => GameItem)) public itemOwners;

    event Registers(address player, bool success);
    event PlayerTransfers(address sender, address recipient, uint256 amount);
    event TokenBurnt(address owner, uint256 _amount);
    event ItemRedeemed(address newOwner, uint256 itemId, string name);

    constructor() ERC20("Degen", "DGN") Ownable(msg.sender) {
        addGameProp();
        _mint(address(this), 100000);
    }


    function addGameProp() private {
        gameItems[1] = GameItem (address(this), 1, "item1", 100);
        itemOwners[address(this)][1] = gameItems[1];
        gameItems[2] = GameItem (address(this), 2, "item2", 200);
        itemOwners[address(this)][2] = gameItems[2];
        gameItems[3] = GameItem (address(this), 3, "item3", 300);
        itemOwners[address(this)][3] = gameItems[3];
        gameItems[4] = GameItem (address(this), 4, "item4", 400);
        itemOwners[address(this)][4] = gameItems[4];
        gameItems[5] = GameItem (address(this), 5, "item5", 500);
        itemOwners[address(this)][5] = gameItems[5];
    }


    modifier addressZeroCheck() {
        if (msg.sender == address(0)) revert("ADDRESS_ZERO_NOT_ALLOWED");
        _;
    }

    modifier isRegistered() {
         if (players[msg.sender].isRegistered == false) 
            revert("YOU_ARE_NOT_REGISTERED");
            _;
    }

    function playerRegister(string memory _username) external addressZeroCheck {
      
        if (players[msg.sender].player != address(0)) revert("ALREADY_REGISTERED");
        if (msg.sender == owner()) revert("OWNER_CANNOT_REGISTER");

        Player memory _player = Player(msg.sender, _username, true);

        players[msg.sender] = _player;
        allPlayers.push(_player);

        emit Registers(msg.sender, true);
    }

    function distributeTokens() external onlyOwner {
        Player[] memory _players = allPlayers;

        for (uint i = 0; i < _players.length; i++) {
            _transfer(address(this), _players[i].player, 1000);
        }
    }


    function transferToken(address _recipient, uint256 _amount) external isRegistered addressZeroCheck {
        if (players[_recipient].isRegistered == false) 
            revert("RECIPIENT_NOT_A_PLAYER");
    
        if (!transfer(_recipient, _amount)) 
            revert("TRANSFER_FAILED");

        emit PlayerTransfers(msg.sender, _recipient, _amount);
    }

    function balance() external isRegistered view returns (uint256) {

        return balanceOf(msg.sender);
    }

    function lockAccount(address player) external onlyOwner {
        Player storage _player = players[player];

        if (_player.player == address(0) || !_player.isRegistered)
            revert("PLAYER_DOES_NOT_EXIST");

        _player.isRegistered = false;
    }

    function openAccount(address player) external onlyOwner {
        Player storage _player = players[player];
        if (_player.player == address(0)) revert("PLAYER_DOES_NOT_EXIST");
        if (_player.isRegistered) revert("PLAYER_NOT_SUSPENDED");

        _player.isRegistered = true;
    }

    function playerBurnsToken(uint256 _amount) external addressZeroCheck isRegistered  {

        _burn(msg.sender, _amount);

        emit TokenBurnt(msg.sender, _amount);
    }

 

    function redeemItem(uint256 itemId) external isRegistered addressZeroCheck {

        GameItem storage _gameItem = gameItems[itemId];

        if (_gameItem.owner == address(0)) revert("ITEM_DOES_NOT_EXIST");

        uint256 itemAmount = _gameItem.amount;

        if (balanceOf(msg.sender) < itemAmount) revert("INSUFFICIENT_BALANCE");

        transfer(address(this), itemAmount);

        _gameItem.owner = msg.sender;

        itemOwners[msg.sender][itemId] = _gameItem;

        emit ItemRedeemed(msg.sender, itemId, _gameItem.name);
    }
}
