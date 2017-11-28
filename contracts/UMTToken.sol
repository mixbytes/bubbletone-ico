pragma solidity 0.4.15;


import 'mixbytes-solidity/contracts/token/CirculatingToken.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'mixbytes-solidity/contracts/token/MintableToken.sol';
import './mixins/MultiControlledMixin.sol';


/// @title ICOPlate coin contract
contract UMTToken is MintableToken, CirculatingToken, MultiControlledMixin {
    using SafeMath for uint256;

    event Burn(address indexed to, uint256 amount);

    function UMTToken(address funds, address sale)
    MintableToken()
    CirculatingToken()
    {
        require(funds != 0);

        totalSupply = 1000000;

        balances[sale] = 500000;
        Transfer(this, sale, 500000);

        balances[funds] = 500000;
        Transfer(this, funds, 500000);

        enableCirculation();
    }

    /// @dev mint actually transfers tokens from local balance to owner's
    function mint(address _to, uint256 _amount) external onlyControllers {
        uint nFreeTokens = balances[msg.sender];
        require(nFreeTokens >= _amount);

        balances[_to] = balances[_to].add(_amount);
        balances[msg.sender] = balances[msg.sender].sub(_amount);

        Transfer(this, _to, _amount);
    }

    /// @dev burns tokens from address. Owner of the token can burn them
    function burn(uint256 _amount) public {
        uint256 balance = balanceOf(msg.sender);
        require(balance > 0);
        require(_amount <= balance);
        totalSupply = totalSupply.sub(_amount);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        Burn(msg.sender, _amount);
        Transfer(msg.sender, this, _amount);
    }

    // FIELDS
    string public constant name = 'Universal Mobile Token';
    string public constant symbol = 'UMT';
    uint8 public constant decimals = 18;
}
