pragma solidity 0.4.15;


/// @title Stateful mixin add state to contact and handlers for it
contract StatefulMixin {
    enum State { INIT, RUNNING, PAUSED, FAILED, SUCCEEDED }

    event StateChanged(State _state);

    modifier requiresState(State _state) {
        require(m_state == _state);
        _;
    }

    modifier exceptsState(State _state) {
        require(m_state != _state);
        _;
    }

    function changeState(State _newState) internal {
        assert(m_state != _newState);

        if (State.INIT == m_state) {
            assert(State.RUNNING == _newState);
        }
        else if (State.RUNNING == m_state) {
            assert(State.PAUSED == _newState || State.FAILED == _newState || State.SUCCEEDED == _newState);
        }
        else if (State.PAUSED == m_state) {
            assert(State.RUNNING == _newState || State.FAILED == _newState);
        }
        else assert(false);

        m_state = _newState;
        StateChanged(m_state);
    }

    function getCurrentState() internal constant returns(State) {
        return m_state;
    }

    /// @dev state of sale
    State public m_state = State.INIT;
}