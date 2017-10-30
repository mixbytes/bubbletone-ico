pragma solidity 0.4.15;

import 'mixbytes-solidity/contracts/token/CirculatingToken.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';


/// @title coin contract
contract Token is CirculatingToken, Ownable {
    using SafeMath for uint256;

    event ControllerSet(address controller);
    event ControllerRetired(address was);
    event ControllerDisabledForever();
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed to, uint256 amount);

    modifier onlyController {
        require(msg.sender == m_controller);
        _;
    }

    /// @dev Allows token transfers
    function startCirculation() external onlyController {
        assert(enableCirculation());    // must be called once
    }

    /// @dev sets the controller
    function setController(address _controller) external onlyOwner {
        require(!m_isSetControllerDisabled);
        m_controller = _controller;
        ControllerSet(m_controller);
    }

    /// @dev disable setting controllers forever
    function detachControllerForever() external onlyOwner {
        require(!m_isSetControllerDisabled);

        m_controller = address(0);
        m_isSetControllerDisabled = true;
        ControllerDisabledForever();
    }

    /// @dev ability for controller to step down
    function detachController() external onlyController {
        require(!m_isSetControllerDisabled);
        address was = m_controller;
        m_controller = address(0);
        ControllerRetired(was);
    }

    /// @dev mints new tokens
    function mint(address _to, uint256 _amount) external onlyController {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(this, _to, _amount);
        Mint(_to, _amount);
    }

    /// @dev burns tokens from address
    function burn(address _to, uint256 _amount) external onlyController {
        totalSupply = totalSupply.sub(_amount);
        balances[_to] = balances[_to].sub(_amount);
        Burn(_to, _amount);
    }

    // FIELDS
    string public constant name = 'Universal Mobile Token';
    string public constant symbol = 'UMT';
    uint8 public constant decimals = 18;

    /// @notice address of entity entitled to mint new tokens
    address public m_controller;
    bool public m_isSetControllerDisabled = false;
}
