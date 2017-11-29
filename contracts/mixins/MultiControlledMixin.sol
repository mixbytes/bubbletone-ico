pragma solidity 0.4.18;

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';


/// @title Stateful mixin add state to contact and handlers for it
contract MultiControlledMixin is Ownable {

    event ControllerAdd(address controller);
    event ControllerRetired(address controller);
    event ControllerDisabledForever();

    modifier onlyControllers() {
        require(isController(msg.sender));
        _;
    }

    modifier onlyControllersOrOwners() {
        require(isController(msg.sender) || owner == msg.sender);
        _;
    }

    /// @dev Add address to controllers
    function addController(address _controller) external onlyOwner {
        require(!m_isSetControllerDisabled);
        require(m_controllers.length < getMaxControllers());
        if (!isController(_controller)){
            m_controllers.push(_controller);
            ControllerAdd(_controller);
        }
    }

    /// @dev Detach sender controller address from controllers
    function detachController() external onlyControllers {
        require(!m_isSetControllerDisabled);
        detachControllerInternal(msg.sender);
    }

    /// @dev Detach address from controllers by Owner
    function detachControllerByOwner(address _controller) external onlyOwner {
        require(!m_isSetControllerDisabled);
        detachControllerInternal(_controller);
    }

    /// @dev Detach address from controllers internal function
    function detachControllerInternal(address _controller) internal {
        uint j = 0;
        address[] memory controllersNew = new address[](m_controllers.length-1);
        for (uint i = 0; i < m_controllers.length; ++i) {
            if (m_controllers[i] != _controller) {
                controllersNew[j] = m_controllers[i];
                j++;
            }
        }
        ControllerRetired(_controller);
        m_controllers = controllersNew;
    }

    /// @dev Detach all controllers and disable adding
    function detachControllersForever() external onlyControllersOrOwners {
        require(!m_isSetControllerDisabled);
        m_controllers = new address[](0);
        m_isSetControllerDisabled = true;
        ControllerDisabledForever();
    }

    /// @dev Check if address in controllers
    // FIXME: check gas consuption comparing to using mapping solution
    function isController(address _controller) internal constant returns (bool) {
        for (uint i = 0; i < m_controllers.length; ++i) {
            if (m_controllers[i] == _controller) {
                return true;
            }
        }
        return false;
    }

    function getMaxControllers() public constant returns (uint){
        return 100;
    }

    // FIELDS
    address[] internal m_controllers;
    bool public m_isSetControllerDisabled = false;
}