pragma solidity 0.4.18;

import './PreICO.sol';


/// @title ICOPlate pre-sale contract
contract ICO is PreICO {
    function ICO(address[] _owners, address funds)
    PreICO(_owners, funds)
    {
    }

    function transferTokensToNextSale() internal {
        // No next sale after ICO
    }

    /// @notice set token address
    function setToken(address _token) public onlymanyowners(keccak256(msg.data)) {
        require(address(m_token) == address(0));

        m_token = UMTToken(_token);
        SetToken(_token);

        m_tokensHardCap = m_token.balanceOf(address(this));

        assert(m_tokensHardCap != 0);

        if (m_tokensHardCap > 250000000)
            m_tokensHardCap = 250000000;
    }

    function finish() internal {
        super.finish();

        // Burn all lasting tokens
        uint tokensLeft = m_token.balanceOf(address(this));
        if (0 != tokensLeft)
            m_token.burn(tokensLeft);
    }

    /// @notice maximum tokens to be sold during sale.
    function getMaximumTokens() internal constant returns (uint) {
        return m_tokensHardCap;
    }

    /// @notice whether there is a next sale after this
    function hasNextSale() internal constant returns (bool) {
        return false;
    }

    /// @notice starting exchange rate of UMT
    // FIXME: need details
    uint public constant c_UMTperETH = 50000;
    uint m_tokensHardCap;
}