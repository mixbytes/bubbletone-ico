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

    uint m_time;
}
