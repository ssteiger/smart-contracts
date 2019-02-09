# ERC777 Token Standard (https://eips.ethereum.org/EIPS/eip-777)

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

AuthorizedOperator: event({
    operator: indexed(address),
    tokenHolder: indexed(address)
})

RevokedOperator: event({
    operator: indexed(address),
    tokenHolder: indexed(address)
})

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
totalSupply: public(uint256)
granularity: public(uint256)

balanceOf: map(address, uint256)
operators: public(map(address, address))
defaultOperators: bytes[address]


@public
def __init__(_name: string, _symbol: string, _totalSupply: uint256,
             _granularity: uint256, _defaultOperators: bytes[address]=""):
    self.name = _name
    self.symbol = _symbol
    self.totalSupply = _totalSupply
    # MUST be greater or equal to 1
    self.granularity = _granularity
    self.defaultOperators = _defaultOperators
    # mint tokens
    self.balanceOf[msg.sender] = _totalSupply
    # fire minted event
    log.Minted("", msg.sender, msg.sender, _totalSupply, _data, "")


# METHODS:
@public
def authorizeOperator(_operator: address):
    self.operators[msg.sender][_operator] = True


@public
def revokeOperator(_operator: address):
    self.operators[msg.sender][_operator] = False


@public
@constant
def isOperatorFor(_operator: address, _tokenHolder: address) -> bool:
    # TODO: also return defaultOperators
    return self.operators[_tokenHolder][_operator]


@public
def send(_to: address, _amount: uint256, _data: bytes[256]=""):
    """
    TODO: Any minting, send or burning of tokens MUST be a multiple of
          the granularity value.
    NOTE: Any operation that would result in a balance that’s not a multiple
          of the granularity value MUST be considered invalid, and the
          transaction MUST revert.
    """
    assert _to != ZERO_ADDRESS
    # TODO: check if recipient is a contract and implements
    #       ER777TokenRecipient interface
    # substract balance from sender
    self.balanceOf[msg.sender] -= _amount
    # add balance to recipient
    self.balanceOf[_to] += _amount
    # fire sent event
    log.Sent("", msg.sender, _to, _amount, _data, "")


@public
def operatorSend(_from: address, _to: address, _amount: uint256,
                 _data: bytes[256]="", _operatorData: bytes[256]=""):
    assert _to != ZERO_ADDRESS
    # check if msg.sender is opeartor for _from
    # TODO: also check for defaultOperators
    assert operators[_from][msg.sender]
    # TODO: check if recipient is a contract and implements
    #       ER777TokenRecipient interface
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
    # update totalSupply
    self.totalSupply -= _amount
    # fire burned event
    log.Burned("", msg.sender, _to, _amount, _data, "")


@public
def operatorBurn(_from: address, _amount: uint256, _operatorData: bytes[256]=""):
    # check if msg.sender is opeartor for _from
    # TODO: also check for defaultOperators
    assert operators[_from][msg.sender]
    # substract amount
    self.balanceOf[_from] -= _amount
    # burn
    self.balanceOf[ZERO_ADDRESS] += _amount
    # update totalSupply
    self.totalSupply -= _amount
    # fire burned event
    log.Burned(msg.sender, _from, _to, _amount, _data, _operatorData)
