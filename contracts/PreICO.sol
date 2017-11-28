pragma solidity 0.4.15;

import './UMTToken.sol';
import './mixins/StatefulMixin.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'mixbytes-solidity/contracts/crowdsale/ExternalAccountWalletConnector.sol';
import 'mixbytes-solidity/contracts/crowdsale/SimpleCrowdsaleBase.sol';
import 'mixbytes-solidity/contracts/ownership/multiowned.sol';


/// @title pre-ico contract
contract PreICO is SimpleCrowdsaleBase, multiowned, StatefulMixin, ExternalAccountWalletConnector {
    using SafeMath for uint256;

    function PreICO(address token, address funds)
    SimpleCrowdsaleBase(token)
    ExternalAccountWalletConnector(funds)
    {
    }

    /// Public methods
    function getToken() public constant returns (UMTToken) {
        return UMTToken(address(m_token));
    }

    /// @notice set start time of the sale
    function setStartTime(uint _time) public onlymanyowners(sha3(msg.data)) {
        require(_time >= getCurrentTime());

        // Check if sale has already started
        if (m_StartTime != 0)
            require(getCurrentTime() < m_StartTime);

        if (m_EndTime != 0)
            require(_time < m_EndTime);

        m_StartTime = _time;
    }

    /// @notice set end time of the sale
    function setEndTime(uint _time) public onlymanyowners(sha3(msg.data)) {
        require(_time >= getCurrentTime());

        // Check if sale has already started
        if (m_StartTime != 0)
            require(getCurrentTime() < m_StartTime);

        if (m_StartTime != 0)
            require(_time > m_StartTime);

        m_EndTime = _time;
    }

    /// @notice pauses sale
    function pause() external requiresState(State.RUNNING) onlyowner
    {
        changeState(State.PAUSED);
    }

    /// @notice resume paused sale
    function unpause() external requiresState(State.PAUSED) onlymanyowners(sha3(msg.data))
    {
        changeState(State.RUNNING);
    }

    /// Internal methods
    function calculateTokens(address /*investor*/, uint payment, uint /*extraBonuses*/) internal constant returns (uint) {
        uint rate = c_UMTperETH.mul(c_UMTBonus.add(100)).div(100);

        return payment.mul(rate);
    }

    function buyInternal(address investor, uint payment, uint extraBonuses)
    internal
    exceptsState(State.PAUSED)
    {
        // Owners should set up dates of sale
        require(m_StartTime > 0 && m_EndTime > 0);

        if (getCurrentState() == State.INIT && getCurrentTime() >= getStartTime())
            changeState(State.RUNNING);

        require(State.RUNNING == m_state);

        super.buyInternal(investor, payment, extraBonuses);
    }

    /// @notice start time of the sale
    function getStartTime() internal constant returns (uint) {
        return m_StartTime;
    }

    /// @notice end time of the sale
    function getEndTime() internal constant returns (uint) {
        return m_EndTime;
    }

    /// @notice minimal amount of investment
    function getMinInvestment() public constant returns (uint) {
        // FIXME: need details
        return 20 finney;
    }

    /// @notice minimum amount of funding to consider preICO as successful
    function getMinimumFunds() internal constant returns (uint) {
        return 0;
    }

    /// @notice maximum investments to be accepted during preICO.
    function getMaximumFunds() internal constant returns (uint) {
        return 0;
    }

    function wcOnCrowdsaleSuccess() internal {
        getToken().detachController();
        changeState(State.SUCCEEDED);
    }

    /// @dev called in case crowdsale failed
    function wcOnCrowdsaleFailure() internal {
        // Impossible
        assert(false);
    }

    /// @notice starting exchange rate of UMT
    // FIXME: need details
    uint public constant c_UMTperETH = 50000;

    /// @notice additional tokens bonus percent
    // FIXME: need details
    uint public constant c_UMTBonus = 20;

    uint public m_StartTime = 0;
    uint public m_EndTime = 0;

}