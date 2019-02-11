# ERC777 Token Standard (https://eips.ethereum.org/EIPS/eip-777)

# Author: Sören Steiger, github.com/ssteiger
# License: MIT

# NOTICE: This contract is a work-in-progress and should not be used in production!

# TODO: complete implementation of 'defaultOperators'

# Interface for the contract called by safeTransferFrom()
contract ERC777TokensRecipient:
    def tokensReceived(
        _operator: address,
        _from: address,
        _to: address,
        _amount: uint256,
        _data: bytes[256],
        _operatorData: bytes[256]
    ) -> bytes32: constant

# TODO: is this actually needed?
contract ERC777TokensSender:
    def tokensToSend(
        _operator: address,
        _from: address,
        _to: address,
        _amount: uint256,
        _data: bytes[256],
        _operatorData: bytes[256]
    ) -> bytes32: constant

# EVENTS:
# https://github.com/ethereum/EIPs/issues/777#issuecomment-461967464

Minted: event({
    _operator: indexed(address),
    _to: indexed(address),
    _amount: uint256,
    _data: bytes[256]
})

Burned: event({
    _operator: indexed(address),
    _to: indexed(address),
    _amount: uint256,
    _data: bytes[256],
    _operatorData: bytes[256]
})

AuthorizedOperator: event({
    _operator: indexed(address),
    _tokenHolder: indexed(address)
})

RevokedOperator: event({
    _operator: indexed(address),
    _tokenHolder: indexed(address)
})

Sent: event({
    _operator: indexed(address),
    _from: indexed(address),
    _to: indexed(address),
    _amount: uint256,
    _data: bytes[256],
    _operatorData: bytes[256]
})


# STATE VARIABLES:
name: public(string[32])
symbol: public(string[32])
totalSupply: public(uint256)
granularity: public(uint256)

balanceOf: map(address, uint256)
operators: public(map(address, address))

# TODO: use map or use bytes array? how to check inclusion?
defaultOperators: public(map(address, address))
supportedInterfaces: public(map(bytes32, bool))

# ERC165 interface ID of ERC165
# TODO: shorten this -> constant(bytes32) = convert(1ffc9a7, bytes32)
ERC165_INTERFACE_ID: constant(bytes32) = 0x0000000000000000000000000000000000000000000000000000000001ffc9a7
# TODO: implement this
#ERC777_INTERFACE_ID: constant(bytes32) = bytes4(keccak256(this))

# METHODS:
@public
def __init__(_name: string, _symbol: string, _totalSupply: uint256,
             _granularity: uint256, _defaultOperators: bytes[address]=""):
    self.name = _name
    self.symbol = _symbol
    self.totalSupply = _totalSupply
    # MUST be greater or equal to 1
    self.granularity = _granularity
    self.defaultOperators = _defaultOperators
    # set supported interfaces
    self.supportedInterfaces[ERC165_INTERFACE_ID] = True
    # TODO:
    #self.supportedInterfaces[ERC777_INTERFACE_ID] = True
    # mint tokens
    self.balanceOf[msg.sender] = _totalSupply
    # fire minted event
    log.Minted("", msg.sender, msg.sender, _totalSupply, _data, "")


@public
@constant
def supportsInterface(_interfaceID: bytes32) -> bool:
    # Interface detection as specified in ERC165
    # https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
    return self.supportedInterfaces[_interfaceID]


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


# TODO: verify that this check actually works
@constant
def _checkForERC777RecipientInterface(_operator: address, _from: address, _to: address, _amount: uint256, _data: bytes[256]="", _operatorData: bytes[256]=""):
    # check if recipient is a contract and implements the ER777TokenRecipient interface
    # TODO: check if function paramters are correct (next 2 lines)
    returnValue: bytes32 = ERC777TokensRecipient(_to).tokensReceived(_operator, _from, _to, _amount, _data, _operatorData)
    assert returnValue == method_id("tokensReceived(address,address,address,uint256,bytes,bytes)", bytes32)


@public
def send(_to: address, _amount: uint256, _data: bytes[256]=""):
    # TODO: Any minting, send or burning of tokens MUST be a multiple of
    #       the granularity value.
    # NOTE: Any operation that would result in a balance that’s not a multiple
    #       of the granularity value MUST be considered invalid, and the
    #       transaction MUST revert.
    assert _to != ZERO_ADDRESS
    # https://github.com/ethereum/vyper/issues/365
    # check if `_to` is a contract address
    if _to.is_contract:
        self._checkForERC777RecipientInterface("", msg.sender, _to, _amount, _data, "")

    # substract balance from sender
    self.balanceOf[msg.sender] -= _amount
    # add balance to recipient
    self.balanceOf[_to] += _amount
    # fire sent event
    log.Sent("", msg.sender, _to, _amount, _data, "")


@public
def operatorSend(_from: address, _to: address, _amount: uint256, _data: bytes[256]="", _operatorData: bytes[256]=""):
    assert _to != ZERO_ADDRESS
    # check if msg.sender is opeartor for _from
    # TODO: also check for defaultOperators
    assert operators[_from][msg.sender]
    # check if `_to` is a contract address
    if _to.is_contract:
        self._checkForERC777RecipientInterface(msg.sender, _from, _to, _amount, _data, _operatorData)

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
