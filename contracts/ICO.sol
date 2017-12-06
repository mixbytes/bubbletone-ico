pragma solidity 0.4.18;

import './PreICO.sol';


/// @title ICOPlate pre-sale contract
contract ICO is PreICO {
    function ICO(address[] _owners, address funds, address pool)
    PreICO(_owners, funds, pool)
    {
    }

    /// @notice set token address
    function setToken(address _token) public onlymanyowners(keccak256(msg.data)) {
        require(address(m_token) == address(0));

        m_token = UMTToken(_token);
        SetToken(_token);

        m_tokensAtStart = m_token.balanceOf(address(this));

        // m_tokensHardCap = m_token.balanceOf(address(this));
        //assert(m_tokensHardCap != 0);
    }

    /// @notice maximum tokens to be sold during sale.
    //function getMaximumTokensWei() internal constant returns (uint) {
    //    return m_tokensHardCap;
    //}

    /// @notice whether there is a next sale after this
    function hasNextSale() internal constant returns (bool) {
        return false;
    }

    event X(uint i);

    function tokenPriceInCents() internal view returns (uint) {
        if (getCurrentTime() < getStartTime() + 5 days) return 50;
        if (getCurrentTime() < getStartTime() + 10 days) return 55;
        if (getCurrentTime() < getStartTime() + 15 days) return 60;
        if (getCurrentTime() < getStartTime() + 20 days) return 65;
        if (getCurrentTime() < getStartTime() + 25 days) return 70;
        if (getCurrentTime() < getStartTime() + 30 days) return 75;
        if (getCurrentTime() < getStartTime() + 35 days) return 80;
        if (getCurrentTime() < getStartTime() + 40 days) return 85;
        if (getCurrentTime() < getStartTime() + 45 days) return 90;
        if (getCurrentTime() < getStartTime() + 50 days) return 95;
        return 100;
    }

    //uint m_tokensHardCap;
}