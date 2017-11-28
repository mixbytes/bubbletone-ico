pragma solidity 0.4.15;

import './PreICOTestHelper.sol';


/// @title ICOTestHelper ico contract for test purposes. DON'T use it in production!
contract ICOTestHelper is PreICOTestHelper {
    using SafeMath for uint256;

    function ICOTestHelper(address token, address funds)
    PreICOTestHelper(token, funds)
    {
    }
}

