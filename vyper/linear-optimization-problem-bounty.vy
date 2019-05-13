# Author: Sören Steiger, github.com/ssteiger
# License: MIT

# NOTE: This is a work in progress and should not be used in production!

# EVENTS:
NewSolutionFound: event({_solverAddress: indexed(address), _solution: uint256})
BountyTransferred: event({_to: indexed(address), _amount: wei_value})
BountyIncreased: event({_amount: wei_value})
CompetitionTimeExtended: event({_to: uint256})


# STATE VARIABLES:
owner: public(address)

x1: public(uint256)
x2: public(uint256)

bestSolution: public(uint256)
solverAddress: public(address)

durationInBlocks: public(uint256)
competitionEnd: public(uint256)
claimPeriode: public(uint256)


# METHODS:
@public
def __init__(_durationInBlocks: uint256):
    self.owner = msg.sender
    self.bestSolution = 0
    self.durationInBlocks = _durationInBlocks
    self.competitionEnd = block.number + _durationInBlocks
    self.solverAddress = ZERO_ADDRESS
    # set claim periode to three days
    # assuming an average blocktime of 14 seconds -> 86400/14
    self.claimPeriode = 6172


@public
@payable
def __default__():
    # return any funds sent to the contract address directly
    send(msg.sender, msg.value)


@private
def _calculateNewSolution(_x1: uint256, _x2: uint256) -> uint256:
    # check new parameters against constraints
    assert _x1 <= 4
    assert 2 * _x2 <= 12
    assert (3 * _x1) + (2 * _x2) <= 18
    assert _x1 > 0 and _x2 > 0
    # calculate and return new solution
    return (3 * _x1) + (5 * _x2)


@public
def submitSolution(_x1: uint256, _x2: uint256) -> uint256:
    newSolution: uint256
    newSolution = self._calculateNewSolution(_x1, _x2)
    assert newSolution > self.bestSolution
    # save the solution and it's values
    self.x1 = _x1
    self.x2 = _x2
    self.bestSolution = newSolution
    self.solverAddress = msg.sender
    log.NewSolutionFound(msg.sender, newSolution)
    return newSolution


@public
def claimBounty():
    assert block.number > self.competitionEnd
    if (self.solverAddress == ZERO_ADDRESS):
        # no solution was found -> extend duration of competition
        self.competitionEnd = block.number + self.durationInBlocks
    else:
        assert block.number < (self.competitionEnd + self.claimPeriode)
        assert msg.sender == self.solverAddress
        send(self.solverAddress, self.balance)
        # extend duration of competition
        self.competitionEnd = block.number + self.durationInBlocks
        log.BountyTransferred(self.solverAddress, self.balance)


@public
@payable
def topUpBounty():
    log.BountyIncreased(msg.value)


@public
def extendCompetition():
    assert block.number > (self.competitionEnd + self.claimPeriode)
    # extend duration of competition
    self.competitionEnd = block.number + self.durationInBlocks
    # reset solverAddress
    self.solverAddress = ZERO_ADDRESS
    log.CompetitionTimeExtended(self.competitionEnd)
