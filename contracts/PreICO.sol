pragma solidity 0.4.18;

import './UMTToken.sol';
import './mixins/StatefulMixin.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'mixbytes-solidity/contracts/crowdsale/ExternalAccountWalletConnector.sol';
import 'mixbytes-solidity/contracts/ownership/multiowned.sol';
import 'zeppelin-solidity/contracts/ReentrancyGuard.sol';
import "./oraclize/usingOraclize.sol";


/// @title pre-ico contract
contract PreICO is multiowned, ReentrancyGuard, StatefulMixin, ExternalAccountWalletConnector, usingOraclize {
    using SafeMath for uint256;

    event SetToken(address token);
    event SetNextSale(address sale);
    event SellTokens(address investor, uint tokens, uint payment);
    event SetTime(uint time, bool isStart);

    event NewOraclizeQuery(string description);
    event NewETHPrice(uint price);

    /// @notice all params are set by owners to start sale
    modifier everythingIsSetByOwners() {
        require(m_StartTime != 0 && m_EndTime != 0 && address(m_token) != address(0));

        if (hasNextSale()) {
            require(address(m_nextSale) != address(0));
        }

        _;
    }


    /** Last recorded funds */
    uint256 public m_lastFundsAmount;

    /**
     * Automatic check for unaccounted withdrawals
     * @param _investor optional refund parameter
     * @param _payment optional refund parameter
     */
    modifier fundsChecker(address _investor, uint _payment) {
        uint atTheBeginning = getTotalInvestmentsStored();
        if (atTheBeginning < m_lastFundsAmount) {
            changeState(State.PAUSED);
            if (_payment > 0) {
                _investor.transfer(_payment);     // we cant throw (have to save state), so refunding this way
            }
            // note that execution of further (but not preceding!) modifiers and functions ends here
        } else {
            _;

            if (getTotalInvestmentsStored() < atTheBeginning) {
                changeState(State.PAUSED);
            } else {
                m_lastFundsAmount = getTotalInvestmentsStored();
            }
        }
    }


    function PreICO(address[] _owners, address funds, address pool) public
    multiowned(_owners, 2)
    ExternalAccountWalletConnector(funds)
    {
        require(3 == _owners.length);

        require(pool != address(0));

        m_pool = pool;

        // Use it when testing with testrpc and etherium bridge. Don't forget to change address
        //OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
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

        m_tokensAtStart = m_token.balanceOf(address(this));

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
        updateETHPriceInCents();
    }

    /// @notice update price if ETH in cents
    function updateETHPriceInCents() payable {
        if (oraclize_getPrice("URL") > this.balance) {
            NewOraclizeQuery("Oraclize request fail. Not enough ether");
        } else {
            NewOraclizeQuery("Oraclize query was sent");
            oraclize_query(
                m_ETHPriceInCentsUpdate,
                "URL",
                "json(https://api.coinmarketcap.com/v1/ticker/ethereum/?convert=USD).0.price_usd"
            );
        }
    }

    /// @notice pause regular price update
    function turnOffETHPriceUpdate() public exceptsState(State.SUCCEEDED) onlyowner
    {
        isEHTPriceUpdateOn = false;
    }

    function turnOnETHPriceUpdate() public exceptsState(State.SUCCEEDED) onlyowner
    {
        if (!isEHTPriceUpdateOn) {
            isEHTPriceUpdateOn = true;
            updateETHPriceInCents();
        }
    }

    /// @notice Called on ETH price update by Oraclize
    function __callback(bytes32 myid, string result, bytes proof) {
        if (msg.sender != oraclize_cbAddress())
            throw;

        uint newPrice = parseInt(result).mul(100);

        require(newPrice > 0);

        m_ETHPriceInCents = newPrice;

        NewETHPrice(m_ETHPriceInCents);

        if (isEHTPriceUpdateOn && (m_state == State.INIT || m_state == State.RUNNING))
            updateETHPriceInCents();
    }

    /// INTERNAL METHODS

    /// @dev payment processing
    function buyInternal(address investor, uint payment)
    internal
    nonReentrant
    everythingIsSetByOwners()
    fundsChecker(investor, payment)
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

        m_token.transfer(m_pool, m_tokensSold);

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

    //function getETHPriceInCents() public view returns (uint) {
    //    return m_ETHPriceInCents;
    //}

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
        return m_tokensAtStart.div(2);
    }

    /// @notice whether there is a next sale after this
    function hasNextSale() internal constant returns (bool) {
        return true;
    }

    uint public m_StartTime = 0;
    uint public m_EndTime = 0;

    UMTToken public m_token;

    address m_nextSale = address(0);
    address m_pool = address(0);

    uint m_tokensSold;
    uint m_tokensAtStart;
    uint m_totalPayments;

    bool m_finished = false;

    uint m_ETHPriceInCents = 44800;

    /// @dev Whether update ETH price every N seconds
    bool isEHTPriceUpdateOn = true;
    // @dev Update ETH price in cents every hour
    uint constant m_ETHPriceInCentsUpdate = 3600;
}