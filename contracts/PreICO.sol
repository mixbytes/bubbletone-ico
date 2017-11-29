pragma solidity 0.4.18;

import './UMTToken.sol';
import './mixins/StatefulMixin.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'mixbytes-solidity/contracts/crowdsale/ExternalAccountWalletConnector.sol';
import 'mixbytes-solidity/contracts/ownership/multiowned.sol';
import 'zeppelin-solidity/contracts/ReentrancyGuard.sol';


/// @title pre-ico contract
contract PreICO is multiowned, ReentrancyGuard, StatefulMixin, ExternalAccountWalletConnector {
    using SafeMath for uint256;

    event SetToken(address token);
    event SetNextSale(address sale);
    event SellTokens(address investor, uint tokens, uint payment);

    /// @notice all params are set by owners to start sale
    modifier everythingIsSetByOwners() {
        require(m_StartTime != 0 && m_EndTime != 0 && address(m_token) != address(0) && m_nextSale != address(0));
        _;
    }

    function PreICO(address[] _owners, address funds) public
    multiowned(_owners, 2)
    ExternalAccountWalletConnector(funds)
    {
        require(3 == _owners.length);
    }

    // fallback function as a shortcut
    function() payable {
        require(0 == msg.data.length);
        buy();  // only internal call here!
    }

    /// @notice crowdsale participation
    function buy() public payable {     // dont mark as external!
        buyInternal(msg.sender, msg.value);
    }

    /// PUBLIC METHODS

    /// @notice set token address
    function setToken(address _token) public onlymanyowners(keccak256(msg.data)) {
        // Could be called only once
        require(address(m_token) == address(0));

        m_token = UMTToken(_token);
        SetToken(_token);
    }

    /// @notice set next sale address to transfer lasting tokens after sale
    function setNextSale(address sale) public onlymanyowners(keccak256(msg.data)) {
        // Could be called only once
        require(m_nextSale == address(0));

        m_nextSale = sale;
        SetNextSale(sale);
    }

    /// @notice set start time of the sale
    function setStartTime(uint _time) public onlymanyowners(keccak256(msg.data)) {
        require(_time >= getCurrentTime());

        // Check if sale has already started
        if (m_StartTime != 0)
            require(getCurrentTime() < m_StartTime);

        if (m_EndTime != 0)
            require(_time < m_EndTime);

        m_StartTime = _time;
    }

    /// @notice set end time of the sale
    function setEndTime(uint _time) public onlymanyowners(keccak256(msg.data)) {
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
    function unpause() external requiresState(State.PAUSED) onlymanyowners(keccak256(msg.data))
    {
        changeState(State.RUNNING);
    }

    /// INTERNAL METHODS

    /// @notice claculate number of token by goven paymen
    function calculateTokens(address /*investor*/, uint payment) internal constant returns (uint) {
        uint rate = c_UMTperETH;

        return payment.mul(rate);
    }

    /// @notice calculate amount of ether to be payed for given amount of tokens
    function calculatePrice(uint tokens) internal constant returns (uint) {
        return tokens.div(c_UMTperETH);
    }

    /// @dev payment processing
    function buyInternal(address investor, uint payment)
    internal
    nonReentrant
    exceptsState(State.PAUSED)
    everythingIsSetByOwners()
    {
        if (getCurrentState() == State.INIT && getCurrentTime() >= getStartTime())
            changeState(State.RUNNING);

        require(State.RUNNING == m_state);

        if (getCurrentTime() >= getEndTime())
            finish();

        if (m_finished) {
            // saving provided gas
            investor.transfer(payment);
            return;
        }

        uint currentBalance = m_token.balanceOf(address(this));

        uint tokens = calculateTokens(investor, payment);
        uint tokensAllowed = getMaximumTokens().sub(m_tokensSold);

        assert(0 != tokensAllowed);

        uint change;
        bool shouldFinish = false;
        if (tokens >= tokensAllowed) {
            uint paymentAllowed = calculatePrice(tokensAllowed);
            tokens = tokensAllowed;
            change = payment.sub(paymentAllowed);
            payment = paymentAllowed;
            shouldFinish = true;
        }

        m_token.transfer(investor, tokens);
        storeInvestment(investor, payment);

        m_tokensSold = m_tokensSold.add(tokens);
        m_totalPayments = m_totalPayments.add(payment);

        SellTokens(investor, tokens, payment);

        // issue tokens
        if (shouldFinish)
            finish();

        if (change > 0)
            investor.transfer(change);
    }

    function finish() internal {
        if (m_finished)
            return;

        changeState(State.SUCCEEDED);

        transferTokensToNextSale();

        m_finished = true;
    }

    /// @notice transfers all lasting tokens to the next sale after finish
    function transferTokensToNextSale() internal {
        assert(m_nextSale != address(0));

        uint currentBalance = m_token.balanceOf(address(this));
        m_token.transfer(m_nextSale, currentBalance);
    }

    /// @notice start time of the sale
    function getStartTime() internal constant returns (uint) {
        return m_StartTime;
    }

    /// @notice end time of the sale
    function getEndTime() internal constant returns (uint) {
        return m_EndTime;
    }

    /// @dev to be overridden in tests
    function getCurrentTime() internal constant returns (uint) {
        return now;
    }

    /// @notice minimal amount of investment
    function getMinInvestment() public constant returns (uint) {
        return 10 finney;
    }

    /// @notice minimum amount of funding to consider preICO as successful
    function getMinimumFunds() internal constant returns (uint) {
        return 0;
    }

    /// @notice maximum tokens to be sold during sale.
    function getMaximumTokens() internal constant returns (uint) {
        return 250000000;
    }

    /// @notice starting exchange rate of UMT
    // FIXME: need details
    uint public constant c_UMTperETH = 50000;

    uint public m_StartTime = 0;
    uint public m_EndTime = 0;

    UMTToken public m_token;
    address m_nextSale = address(0);

    uint m_tokensSold;
    uint m_totalPayments;

    bool m_finished = false;
}