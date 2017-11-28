pragma solidity 0.4.15;

import '../UMTToken.sol';


/// @title UMTTokenTestHelper token test helper. DON'T use it in production!
contract UMTTokenTestHelper is UMTToken {
    function UMTTokenTestHelper(address funds)
    UMTToken(funds)
    {
    }

    /// @notice Gets controllers
    /// @return memory array of controllers
    function getControllers() public constant returns (address[]) {
        return m_controllers;
    }

    /// For Crowdsale.js
    function m_controller() public constant returns (address) {
        return m_controllers[0];
    }
}

