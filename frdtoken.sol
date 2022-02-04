pragma solidity ^0.8.0;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";

abstract contract ERC20Interface {
    function transfer(address recipient, uint amount) virtual public returns (bool success);
    function buyToken(uint amount, uint256 _txCounter) virtual public returns (bool success);
    function sellToken(uint amount) virtual public returns (bool success);
    function changePrice(uint price) virtual public returns (bool success);
    function getBalance() virtual public view returns (uint);

    event Transfer(address indexed sender, address indexed receiver, uint amount);
    event Purchase(address indexed buyer, uint amount);
    event Sell(address indexed seller, uint amount);
    event Price(uint price);
}

abstract contract customLib {
    function customSend(uint256 value, address payable receiver) virtual public payable returns(bool);
}

contract FRDToken is ERC20Interface {
    string public symbol;
    string public name;
    uint private tokenSupply;
    uint256 public tokenPrice;
    uint256 private transactionCounter;
    address private owner;
    mapping(address => uint) balances;

    customLib lib = customLib(0xc0b843678E1E73c090De725Ee1Af6a9F728E2C47);
    function callLib(uint256 value, address payable receiver) public payable returns (bool) {
        return lib.customSend(value, receiver);
    }

    modifier ownerOnly() {
        require(msg.sender == owner);
        _;
    }

    using SafeMath for uint;
    constructor() public payable {
        symbol = "FRD";
        name = "FRDToken";
        tokenSupply = 100000000;
        balances[msg.sender] = tokenSupply;
        emit Transfer(address(0), msg.sender, tokenSupply);
    }

    function transactionOrder() public {
        owner = msg.sender;
        tokenPrice = 10;
        transactionCounter = 0;
    }

    function buyToken(uint amount, uint256 _txCounter) public override returns (bool success) {
	    require(amount > 0, "You need to send some ether");
	    require(amount <= tokenSupply, "There is no enough token available");
        require(_txCounter == transactionCounter);
        transfer(msg.sender, amount);
        emit Purchase(msg.sender, amount);
        tokenPrice *= 2;
        return true;
    }

    function sellToken(uint amount) public override returns (bool success) {
        require(amount > 0, "You need to sell some tokens");
        balances[msg.sender] -= amount;
        balances[address(this)] += amount;
        emit Sell(msg.sender, amount);
        payable(msg.sender).transfer(amount.mul(tokenPrice));
        return true;
    }
    
    function transfer(address recipient, uint amount) public override returns (bool success) {
        balances[msg.sender] = balances[msg.sender].add(amount);
        balances[recipient] = balances[recipient].add(amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function changePrice(uint price) ownerOnly() public override returns (bool success){
        tokenPrice = price;
        transactionCounter += 1;
        emit Price(price);
        return true;
    }

    function getBalance() public override view returns (uint) {
        return tokenSupply.sub(balances[address(0)]);
    }

    function getTransactionCounter() public view returns (uint) {
        return transactionCounter;
    }
}