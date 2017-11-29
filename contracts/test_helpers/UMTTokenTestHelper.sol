pragma solidity 0.4.18;

import '../UMTToken.sol';


/// @title UMTTokenTestHelper token test helper. DON'T use it in production!
contract UMTTokenTestHelper is UMTToken {
    function UMTTokenTestHelper(address funds, address sale) public
    UMTToken(funds, sale)
    {
    }
}

