pragma solidity 0.4.18;

import '../PreICO.sol';

/// @title PreICOTestHelper pre-ico contract for test purposes. DON'T use it in production!
contract PreICOTestHelper is PreICO {
    using SafeMath for uint256;

    function PreICOTestHelper(address[] _owners, address funds, address pool) public
    PreICO(_owners, funds, pool)
    {
    }

    function getCurrentTime() internal constant returns (uint) {
        return m_time;
    }

    function setTime(uint time) external onlyowner {
        m_time = time;
    }

    function getMaximumTokensWei() internal constant returns (uint) {
        return uint(2500) * uint(1e18);
    }

    function calculateTokensPublic(address investor, uint payment) public view returns (uint) {
        return calculateTokens(investor, payment);
    }

    function getTokensSold() public constant returns (uint) {
        return m_tokensSold;
    }

    uint m_time;

    uint constant m_ETHPriceInCentsUpdate = 10;
}

