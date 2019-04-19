# EVENTS:
Deposit: event({_from: indexed(address), _amount: wei_value})
Transfer: event({_to: indexed(address), _amount: uint256})

# STATE VARIABLES:
owner: public(address)
operators: map(address, bool)

whiteList: map(address, bool)
blackList: map(address, bool)


@public
def __init__():
    self.owner = msg.sender


@public
@payable
def __default__():
    log.Deposit(msg.sender, msg.value)


#--------- transfer methods ---------
# owner and operators can do a safe transfer
@public
def safeTransfer(_to: address, _amount: uint256) -> bool:
    assert (self.operators[msg.sender] or msg.sender == self.owner)
    assert self.whiteList[_to]
    assert not self.blackList[_to]
    send(_to, _amount)
    log.Transfer(_to, _amount)
    return True

# only owner can do transfer
@public
def transfer(_to: address, _amount: uint256) -> bool:
    assert msg.sender == self.owner
    send(_to, _amount)
    log.Transfer(_to, _amount)
    return True


# --------- operator methods ---------
@public
def isOperator(_operator: address) -> bool:
    return self.operators[_operator]

@public
def addOperator(_operator: address) -> bool:
    assert msg.sender == self.owner
    self.operators[_operator] = True
    return True

@public
def removeOperator(_operator: address) -> bool:
    assert msg.sender == self.owner
    self.operators[_operator] = False
    return True


# ---------  white/black list methods ---------
@public
def addToWhiteList(_candidate: address) -> bool:
    assert msg.sender == self.owner
    self.whiteList[_candidate] = True
    return True

@public
def removeFromWhiteList(_candidate: address) -> bool:
    assert msg.sender == self.owner
    self.whiteList[_candidate] = False
    return True

@public
def addToBlackList(_candidate: address) -> bool:
    assert msg.sender == self.owner
    self.blackList[_candidate] = True
    return True

@public
def removeFromBlackList(_candidate: address) -> bool:
    assert msg.sender == self.owner
    self.blackList[_candidate] = False
    return True
