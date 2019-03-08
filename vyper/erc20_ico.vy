# Author: Sören Steiger, github.com/ssteiger
# License: MIT

# ICO for an ERC20 Token
# https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md

# WARNING: This contract has not been tested and should not be
#         used in production!

# TODO: Check that the ZERO_ADDRESS is the correct 'from' address
#       for ERC20Token().transfer() (line 135)

contract ERC20Token:
    def transfer(to: address, value: uint256) -> bool: modifying
    def totalSupply() -> uint256: constant


# EVENTS:
FundingReceived: event({_from: indexed(address), _amount: wei_value})
TokensTransfered: event({_to: indexed(address), _amount: uint256})
GoalReached: event({_totalAmountRaised: wei_value})
FundsTransfered: event({_to: indexed(address), _amount: wei_value})
FundsWithdrawn: event({_to: indexed(address), _amount: wei_value})


# STATE VARIABLES:
contractOperator: public(address)

erc20TokenContract: public(address)
erc20TotalSupply: public(uint256)

fundingGoal: public(wei_value)
pricePerToken: public(wei_value)

openAtBlock: public(uint256)
durationInBlocks: public(uint256)

fundingGoalReached: public(bool)

# allows backers to reclaim their ether if ico
# is closed and fundingGoalReached is not reached
balanceOf: map(address, wei_value)


# CONSTANTS
ZERO_WEI: constant(wei_value) = as_wei_value(0, 'wei')


@public
def __init__(_erc20TokenContract: address,
             _fundingGoalInEther: uint256,
             _openAtBlock: uint256,
             _durationInBlocks: uint256
           ):
    self.contractOperator = msg.sender
    self.erc20TokenContract = _erc20TokenContract

    self.fundingGoal = as_wei_value(_fundingGoalInEther, 'ether')
    self.erc20TotalSupply = ERC20Token(_erc20TokenContract).totalSupply()
    self.pricePerToken = self.fundingGoal / self.erc20TotalSupply

    self.openAtBlock = _openAtBlock
    self.durationInBlocks = _durationInBlocks

    self.fundingGoalReached = False


# https://vyper.readthedocs.io/en/v0.1.0-beta.8/structure-of-a-contract.html#default-function
@public
@payable
def __default__():
    # check that ico has not been completed
    assert not self.fundingGoalReached

    # check if ico is running
    assert block.number >= self.openAtBlock
    assert block.number < (self.openAtBlock + self.durationInBlocks)

    currentBalance: uint256(wei) = self.balance

    if (self.balance + msg.value) >= self.fundingGoal:
        # calculate surplus
        surplus: wei_value
        surplus = (self.balance + msg.value) - self.fundingGoal
        # add correct value to backers balance
        self.balanceOf[msg.sender] += (msg.value - surplus)
        log.FundingReceived(msg.sender, msg.value - surplus)
        # mark ICO as successfully completed
        self.fundingGoalReached = True
        # fire token goal reached event
        log.GoalReached(self.fundingGoal)
        # return surplus to backer
        send(msg.sender, surplus)
    else:
        # add value to backers balance
        self.balanceOf[msg.sender] += msg.value
        # check if everything worked
        assert self.balanceOf[msg.sender] == (currentBalance + msg.value)
        # fire funding received event
        log.FundingReceived(msg.sender, msg.value)


@public
def withdraw():
    # check if ICO duration has passed
    assert block.number >= (self.openAtBlock + self.durationInBlocks)
    # check if funding goal has not been reached
    assert not self.fundingGoalReached
    # check if backer has funds to withdraw
    assert self.balanceOf[msg.sender] > ZERO_WEI
    # get amount of ether the backer has contributed
    amount: wei_value
    amount = self.balanceOf[msg.sender]
    # set amount of claimable ether of backer to zero
    self.balanceOf[msg.sender] = ZERO_WEI
    # return ether to backer
    send(msg.sender, amount)
    log.FundsWithdrawn(msg.sender, amount)


@public
def claimTokens():
    # check if ICO has been successfully completed
    assert self.fundingGoalReached
    # calculate the amount of tokens the backer can claim
    claimableAmount: uint256
    # TODO: test/verify that no conversion errors are happening here
    claimableAmount = as_unitless_number(self.balanceOf[msg.sender] / self.pricePerToken)
    assert as_wei_value((claimableAmount * self.pricePerToken), "wei") == self.balanceOf[msg.sender]
    # set amount of claimable tokens of backer to zero
    self.balanceOf[msg.sender] = ZERO_WEI
    # send tokens to backer
    # WARNING: make sure that in the ERC20 Token Contract the ZERO_ADDRESS
    #          initially ownes all tokens
    ERC20Token(self.erc20TokenContract).transfer(ZERO_ADDRESS, claimableAmount)
    # fire token transfer event
    log.TokensTransfered(msg.sender, claimableAmount)


@public
def moveFunds(_to: address):
    # only allow the contract operator to move funds
    assert msg.sender == self.contractOperator
    # only allow transfer if ICO has been successfully completed
    assert self.fundingGoalReached
    # fire funds transfer event
    log.FundsTransfered(_to, self.balance)
    # transfer all ether in this contract
    send(_to, self.balance)


@public
def cancelICO():
    # only allow contractOperator to perform this operation
    assert msg.sender == self.contractOperator
    # only if ico has not started
    assert block.number < self.openAtBlock
    # delete this contract
    selfdestruct(msg.sender)
