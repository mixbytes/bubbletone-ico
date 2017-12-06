pragma solidity 0.4.18;


import 'mixbytes-solidity/contracts/token/CirculatingToken.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';


/// @title Universal Mobile Token contract
contract UMTToken is CirculatingToken {
    using SafeMath for uint256;

    event Burn(address indexed to, uint256 amount);
    event Activate(address sender);

    function UMTToken(address funds, address sale) public
    CirculatingToken()
    {
        require(funds != address(0));

        totalSupply = startFundsBalance + startSaleBalance;

        balances[funds] = startFundsBalance;
        Transfer(this, funds, startFundsBalance);

        balances[sale] = startSaleBalance;
        Transfer(this, sale, startSaleBalance);

        enableCirculation();
    }

    /// @dev burns tokens from address. Owner of the token can burn them
    function burn(uint256 _amount) public {
        uint256 balance = balanceOf(msg.sender);
        require(balance > 0);
        require(_amount <= balance);
        totalSupply = totalSupply.sub(_amount);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        Burn(msg.sender, _amount);
        Transfer(msg.sender, address(0), _amount);
    }

    // FIELDS
    string public constant name = 'Universal Mobile Token';
    string public constant symbol = 'UMT';
    uint8 public constant decimals = 18;

    /// @dev starting balance of funds
    uint internal constant startFundsBalance = uint(500000000) * (uint(10) ** uint(decimals));

    /// @dev starting balance to be sold
    uint internal constant startSaleBalance = uint(500000000) * (uint(10) ** uint(decimals));
}
