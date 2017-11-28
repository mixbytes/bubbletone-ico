pragma solidity 0.4.15;

import './PreICO.sol';


/// @title ICOPlate pre-sale contract
contract ICO is PreICO {
    function ICO(address token, address funds)
    PreICO(token, funds)
    {}

    /// @notice starting exchange rate of UMT
    // FIXME: need details
    uint public constant c_UMTperETH = 50000;

    /// @notice additional tokens bonus percent
    // FIXME: need details
    uint public constant c_UMTBonus = 20;
}