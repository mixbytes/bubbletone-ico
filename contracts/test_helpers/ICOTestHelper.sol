pragma solidity 0.4.18;

import '../ICO.sol';

/// @title ICOTestHelper ico contract for test purposes. DON'T use it in production!
contract ICOTestHelper is ICO {
    using SafeMath for uint256;

    function ICOTestHelper(address[] _owners, address funds) public
    ICO(_owners, funds)
    {
    }

    function getCurrentTime() internal constant returns (uint) {
        return m_time;
    }

    function setTime(uint time) external onlyowner {
        m_time = time;
    }

    function getMaximumTokensWei() internal constant returns (uint) {
        return uint(2000) * uint(1e18);
    }

    function calculateTokensPublic(address investor, uint payment) public view returns (uint) {
        return calculateTokens(investor, payment);
    }

    uint m_time;
}
