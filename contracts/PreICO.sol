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
    event SetTime(uint time, bool isStart);

    /// @notice all params are set by owners to start sale
    modifier everythingIsSetByOwners() {
        require(m_StartTime != 0 && m_EndTime != 0 && address(m_token) != address(0));

        if (hasNextSale()) {
            require(address(m_nextSale) != address(0));
        }

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
    function buy() public payable {     // don't mark as external!
        buyInternal(msg.sender, msg.value);
    }

    /// PUBLIC METHODS

    /// @notice set token address
    function setToken(address _token) public onlymanyowners(keccak256(msg.data))
    requiresState(State.INIT)
    {
        // Could be called only once
        require(address(m_token) == address(0));

        m_token = UMTToken(_token);
        SetToken(_token);
    }

    /// @notice set next sale address to transfer lasting tokens after sale
    function setNextSale(address sale) public onlymanyowners(keccak256(msg.data))
    requiresState(State.INIT)
    {
        // Could be called only once
        require(m_nextSale == address(0));

        m_nextSale = sale;
        SetNextSale(sale);
    }

    /// @notice set start time of the sale
    function setStartTime(uint _time) public onlymanyowners(keccak256(msg.data))
    requiresState(State.INIT)
    {
        require(_time >= getCurrentTime());

        if (m_EndTime != 0)
            require(_time < m_EndTime);

        m_StartTime = _time;

        SetTime(_time, true);
    }

    /// @notice set end time of the sale
    function setEndTime(uint _time) public onlymanyowners(keccak256(msg.data))
    requiresState(State.INIT)
    {
        require(_time >= getCurrentTime());

        if (m_StartTime != 0)
            require(_time > m_StartTime);

        m_EndTime = _time;

        SetTime(_time, false);
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

    /// @dev payment processing
    function buyInternal(address investor, uint payment)
    internal
    nonReentrant
    everythingIsSetByOwners()
    {
        require(payment >= getMinInvestment());

        if (getCurrentState() == State.INIT && getCurrentTime() >= getStartTime())
            changeState(State.RUNNING);

        require(State.RUNNING == m_state);

        if (getCurrentTime() >= getEndTime())
            finish();

        uint tokensAllowed = getMaximumTokensWei().sub(m_tokensSold);

        if (tokensAllowed == 0)
            finish();

        if (m_finished) {
            // saving provided gas
            investor.transfer(payment);
            return;
        }

        uint tokens = calculateTokens(investor, payment);

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

        processRemainingTokens();

        m_finished = true;
    }

    /// @notice transfers all remaining tokens to the next sale or burns tokens if there is no next sale
    function processRemainingTokens() internal {
        uint currentBalance = m_token.balanceOf(address(this));
        if (0 == currentBalance)
            return;

        if (hasNextSale()) {
            assert(m_nextSale != address(0));

            m_token.transfer(m_nextSale, currentBalance);
        }
        else {
            // Burn all remaining tokens
            m_token.burn(currentBalance);
        }
    }


    function tokenPriceInCents() internal view returns (uint) {
        return 42;
    }

    function ETHPriceInCents() internal view returns (uint) {
        return m_ETHPriceInCents;
    }

    function setETHPriceInCents(uint price) public onlyowner {
        m_ETHPriceInCents = price;
    }

    /// @notice calculate number of token for given payment
    function calculateTokens(address /*investor*/, uint payment) internal view returns (uint) {
        return payment.mul(ETHPriceInCents()).div(tokenPriceInCents());
    }

    /// @notice calculate amount of ether to be payed for given amount of tokens
    function calculatePrice(uint tokens) internal view returns (uint) {
        return tokens.mul(tokenPriceInCents()).div(ETHPriceInCents());
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

    /// @notice maximum tokens to be sold during sale.
    function getMaximumTokensWei() internal constant returns (uint) {
        return uint(250000000) * uint(1e18);
    }

    /// @notice whether there is a next sale after this
    function hasNextSale() internal constant returns (bool) {
        return true;
    }

    uint public m_StartTime = 0;
    uint public m_EndTime = 0;

    UMTToken public m_token;
    address m_nextSale = address(0);

    uint m_tokensSold;
    uint m_totalPayments;

    bool m_finished = false;

    uint m_ETHPriceInCents = 44800;
}