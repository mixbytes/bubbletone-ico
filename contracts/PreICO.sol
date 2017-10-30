pragma solidity 0.4.15;

import './PreSale.sol';


/// @title pre-sale contract
contract PreICO is PreSale {
    function PreICO(address token, address funds)
    PreSale(token, funds)
    {}

    /// @notice start time of the pre-ICO
    function getStartTime() internal constant returns (uint) {
        // Sun, 15 Nov 2017 0:00:00 GMT
        return 1510704000;
    }

    /// @notice end time of the pre-ICO
    function getEndTime() internal constant returns (uint) {
        // FIXME: need details
        return getStartTime() + (10 days);
    }

    /// @notice minimal amount of investment
    function getMinInvestment() public constant returns (uint) {
        return 20 finney;
    }

    /// @notice starting exchange rate of UMT
    // FIXME: need details
    uint public constant c_UMTperETH = 50000;

    /// @notice additional tokens bonus percent
    // FIXME: need details
    uint public constant c_UMTBonus = 20;
}