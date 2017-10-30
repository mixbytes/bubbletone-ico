pragma solidity 0.4.15;

import './Token.sol';
import './mixins/StatefulMixin.sol';
import 'zeppelin-solidity/contracts/ReentrancyGuard.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'mixbytes-solidity/contracts/crowdsale/ExternalAccountWalletConnector.sol';
import 'mixbytes-solidity/contracts/crowdsale/SimpleCrowdsaleBase.sol';


/// @title pre-sale contract
contract PreSale is SimpleCrowdsaleBase, Ownable, StatefulMixin, ExternalAccountWalletConnector {
    using SafeMath for uint256;

    function PreSale(address token, address funds)
        SimpleCrowdsaleBase(token)
        ExternalAccountWalletConnector(funds)
    {}

    /// @notice sale participation
    function buy() public payable {
        if (State.INIT == m_state && getCurrentTime() >= getStartTime())
            changeState(State.RUNNING);

        require(State.RUNNING == m_state);

        return super.buy();
    }

    /// @notice Tests ownership of the current caller.
    /// @return true if it's an owner
    // It's advisable to call it by new owner to make sure that the same erroneous address is not copy-pasted to
    // addOwner/changeOwner and to isOwner.
    function amIOwner() external constant onlyOwner returns (bool) {
        return true;
    }

    // INTERNAL

    function calculateTokens(address /*investor*/, uint payment, uint /*extraBonuses*/) internal constant returns (uint) {
        uint rate = c_UMTperETH.mul(c_UMTBonus.add(100)).div(100);

        return payment.mul(rate);
    }

    /// @notice minimum amount of funding to consider preSale as successful
    function getMinimumFunds() internal constant returns (uint) {
        return 0;
    }

    /// @notice maximum investments to be accepted during preSale. No hard cap
    function getMaximumFunds() internal constant returns (uint) {
        return 0;
    }

    /// @notice start time of the pre-ICO
    function getStartTime() internal constant returns (uint) {
        // Sun, 5 Nov 2017 0:00:00 GMT
        return 1509840000;
    }

    /// @notice end time of the pre-ICO
    function getEndTime() internal constant returns (uint) {
        // FIXME: need details
        return getStartTime() + (12 days);
    }

    /// @notice minimal amount of investment
    function getMinInvestment() public constant returns (uint) {
        return 10 finney;
    }

    function mustApplyTimeCheck(address investor, uint /*payment*/) constant internal returns (bool) {
        return investor != owner;
    }

    /// @notice starting exchange rate of 
    // FIXME: need details
    uint public constant c_UMTperETH = 100000;

    /// @notice additional tokens bonus percent
    // FIXME: need details
    uint public constant c_UMTBonus = 40;
}
