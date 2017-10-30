pragma solidity 0.4.15;

import '../PreSale.sol';


/// @title PreSaleTestHelper pre-sale contract for test purposes. DON'T use it in production!
contract PreSaleTestHelper is PreSale {
    using SafeMath for uint256;

    function PreSaleTestHelper(address token, address funds)
    PreSale(token, funds)
    {
    }

    function getCurrentTime() internal constant returns (uint) {
        return m_time;
    }

    function setTime(uint time) external onlyOwner {
        m_time = time;
    }

    uint m_time;
}

