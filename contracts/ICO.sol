pragma solidity 0.4.18;

import './PreICO.sol';


/// @title ICOPlate pre-sale contract
contract ICO is PreICO {
    /// @notice all params are set by owners to start sale
    modifier everythingIsSetByOwners() {
        require(m_StartTime != 0 && m_EndTime != 0 && address(m_token) != address(0));
        _;
    }

    function ICO(address[] _owners, address funds)
    PreICO(_owners, funds)
    {}

    function transferTokensToNextSale() internal {
        // No next sale after ICO
    }

    /// @notice starting exchange rate of UMT
    // FIXME: need details
    uint public constant c_UMTperETH = 50000;
}