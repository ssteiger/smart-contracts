# ERC777 Token Standard (https://github.com/ethereum/EIPs/issues/777)

# Author: Sören Steiger, github.com/ssteiger
# License: MIT


# EVENTS:
# https://github.com/ethereum/EIPs/issues/777#issuecomment-461967464
Minted: event({
    operator: indexed(address),
    to: indexed(address),
    amount: uint256,
    data: bytes[256]
})

Burned: event({
    operator: indexed(address),
    to: indexed(address),
    amount: uint256,
    data: bytes[256],
    operatorData: bytes[256]
})

AuthorizedOperator: event({operator: indexed(address), tokenHolder: indexed(address)})

RevokedOperator: event({operator: indexed(address), tokenHolder: indexed(address)})

Sent: event({
    operator: indexed(address),
    from: indexed(address),
    to: indexed(address),
    amount: uint256,
    data: bytes[256],
    operatorData: bytes[256]
})


# STATE VARIABLES:
name: public(string[32])
symbol: public(string[32])
total_supply: public(uint256)
granularity: public(uint256)

balanceOf: map(address, uint256)
operators: public(map(address, address))
defaultOperators: public(map(address, bool))


# METHODS:
@public
@constant
def defaultOperators() -> address[]:



@public
def authorizeOperator(_operator: address):
    self.operators[msg.sender][_operator] = True


@public
def revokeOperator(_operator: address):
    self.operators[msg.sender][_operator] = False


@public
@constant
def isOperatorFor(_operator: address, _tokenHolder: address) -> bool:
    return self.operators[_tokenHolder][_operator]


@public
def send(_to: address, _amount: uint256, _data: bytes[256]):
    # substract balance from sender
    self.balanceOf[msg.sender] -= _amount
    # add balance to recipient
    self.balanceOf[_to] += _amount
    # fire sent event
    log.Sent("", msg.sender, _to, _amount, _data, "")


@public
def operatorSend(_from: address, _to: address, _amount: uint256,
                 _data: bytes[256], _operatorData: bytes[256]):
    # check if msg.sender is allowed to do this
    assert operators[_from][msg.sender]
    # substract balance from sender
    self.balanceOf[_from] -= _amount
    # add balance to recipient
    self.balanceOf[_to] += _amount
    # fire sent event
    log.Sent(msg.sender, _from, _to, _amount, _data, _operatorData)


@public
def burn(_amount: uint256):
    # substract amount from sender
    self.balanceOf[msg.sender] -= _amount
    # burn
    self.balanceOf[ZERO_ADDRESS] += _amount
    # fire burned event
    log.Burned("", msg.sender, _to, _amount, _data, "")


@public
def operatorBurn(_from: address, _amount: uint256, _operatorData: bytes[256]):
    # substract amount
    self.balanceOf[_from] -= _amount
    # burn
    self.balanceOf[ZERO_ADDRESS] += _amount
    # fire burned event
    log.Burned(msg.sender, _from, _to, _amount, _data, _operatorData)
