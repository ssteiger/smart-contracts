# ERC777 Token Standard (https://eips.ethereum.org/EIPS/eip-777)

# Author: Sören Steiger, github.com/ssteiger
# License: MIT

# NOTICE: This contract is a work-in-progress and should not be used in production!

# TODO: complete implementation of 'defaultOperators'

# Interface for the contract called by safeTransferFrom()
contract ERC777TokensSender:
    def tokensToSend(
        _operator: address,
        _from: address,
        _to: address,
        _amount: uint256,
        _data: bytes[256],
        _operatorData: bytes[256]
    ) -> bytes32: constant

contract ERC777TokensRecipient:
    def tokensReceived(
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

# TODO: https://github.com/ethereum/EIPs/issues/777#issuecomment-461967464
Burned: event({
    _operator: indexed(address),
    _from: indexed(address),
    _amount: uint256,
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
# The token MAY define default operators.
# A default operator is an implicitly authorized operator for all token holders.
defaultOperators: public(map(address, bool))
operators: public(map(address, address))

supportedInterfaces: public(map(bytes32, bool))

# ERC165 interface ID of ERC165
# TODO: shorten this -> constant(bytes32) = convert(1ffc9a7, bytes32)
ERC165_INTERFACE_ID: constant(bytes32) = 0x0000000000000000000000000000000000000000000000000000000001ffc9a7
# TODO: implement this
#ERC777_INTERFACE_ID: constant(bytes32) = bytes4(keccak256(this))


# METHODS:
@public
def __init__(_name: string,
             _symbol: string,
             _totalSupply: uint256,
             _granularity: uint256,
             _defaultOperators: bytes[address]=""
           ):
    self.name = _name
    self.symbol = _symbol
    self.totalSupply = _totalSupply
    # MUST be greater or equal to 1
    self.granularity = _granularity
    # The token MUST define default operators at creation time
    # The token contract MUST NOT add or remove default operators ever
    self.defaultOperators = _defaultOperators
    # set supported interfaces
    self.supportedInterfaces[ERC165_INTERFACE_ID] = True
    # TODO:
    #self.supportedInterfaces[ERC777_INTERFACE_ID] = True
    # mint tokens
    self.balanceOf[msg.sender] = _totalSupply
    # fire minted event
    log.Minted(msg.sender, msg.sender, _totalSupply, _data)


# def defaultOperators()
# NOTE: vyper automatically generates a 'defaultOperators()' getter
#       method because `defaultOperators` is declared as public


@public
@constant
def supportsInterface(_interfaceID: bytes32) -> bool:
    # Interface detection as specified in ERC165
    # https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
    return self.supportedInterfaces[_interfaceID]


@public
# TODO: A token holder MAY have multiple operators at the same time
def authorizeOperator(_operator: address):
    self.operators[msg.sender][_operator] = True


@public
def revokeOperator(_operator: address):
    self.operators[msg.sender][_operator] = False


@public
@constant
def isOperatorFor(_operator: address, _tokenHolder: address) -> bool:
    # NOTE: An address MUST always be an operator for itself
    isSelf: bool = _operator == _tokenHolder
    # default operators
    isDefaultOperator: bool = self.defaultOperators[_operator]
    # operators
    isOperator: bool = self.operators[_tokenHolder][_operator]

    isOperatorFor: bool = (isSelf or isDefaultOperator or isOperator)
    return isOperatorFor


# TODO: verify that this check actually works
@private
@constant
def _checkForERC777TokensInterface_Sender(_operator: address,
                                          _from: address,
                                          _to: address,
                                          _amount: uint256,
                                          _data: bytes[256]="",
                                          _operatorData: bytes[256]=""
                                         ):
    # check if token holder registers an `ERC777TokensSender` implementation via ERC820
    # TODO: check if function paramters are correct (next 2 lines)
    # NOTE: This makes the call (call executes) and returns the bytestring
    returnValue: bytes32 = ERC777TokensSender(_from).tokensToSend(_operator, _from, _to, _amount, _data, _operatorData)
    assert returnValue == method_id("tokensToSend(address,address,address,uint256,bytes,bytes)", bytes32)


# TODO: verify that this check actually works
@private
@constant
def _checkForERC777TokensInterface_Recipient(_operator: address,
                                             _from: address,
                                             _to: address,
                                             _amount: uint256,
                                             _data: bytes[256]="",
                                             _operatorData: bytes[256]=""
                                            ):
    # check if recipient implements the `ER777TokenRecipient` interface via ERC820
    # TODO: check if function paramters are correct (next 2 lines)
    # NOTE: This makes the call (call executes) and returns the bytestring
    returnValue: bytes32 = ERC777TokensRecipient(_to).tokensReceived(_operator, _from, _to, _amount, _data, _operatorData)
    assert returnValue == method_id("tokensReceived(address,address,address,uint256,bytes,bytes)", bytes32)


@public
def send(_to: address, _amount: uint256, _data: bytes[256]=""):
    assert _to != ZERO_ADDRESS
    # Any minting, send or burning of tokens MUST be a multiple of
    # the granularity value.
    assert _amount % self.granularity == 0
    # check if `msg.sender` is a contract address
    if msg.sender.is_contract:
        # The token contract MUST call the `tokensToSend` hook of the token holder
        # if the token holder registers an `ERC777TokensSender` implementation via ERC820
        self._checkForERC777TokensInterface_Sender("", msg.sender, _to, _amount, _data, "")

    # check if `_to` is a contract address
    if _to.is_contract:
        # The token contract MUST call the `tokensReceived` hook of the recipient
        # if the recipient registers an `ERC777TokensRecipient` implementation via ERC820
        self._checkForERC777TokensInterface_Recipient("", msg.sender, _to, _amount, _data, "")

    # substract balance from sender
    self.balanceOf[msg.sender] -= _amount
    # add balance to recipient
    self.balanceOf[_to] += _amount
    # fire sent event
    log.Sent("", msg.sender, _to, _amount, _data, "")


@public
def operatorSend(_from: address,
                 _to: address,
                 _amount: uint256,
                 _data: bytes[256]="",
                 _operatorData: bytes[256]=""
               ):
    assert _to != ZERO_ADDRESS
    # Any minting, send or burning of tokens MUST be a multiple of
    # the granularity value.
    assert _amount % self.granularity == 0
    # check if msg.sender is operator for _from
    isDefaultOperator: bool = self.defaultOperators[_from]
    isOperator: bool = self.operators[_from][msg.sender]
    assert (isDefaultOperator or isOperator)
    # check if `_to` is a contract address
    if _to.is_contract:
        # The token contract MUST call the `tokensReceived` hook of the recipient
        # if the recipient registers an `ERC777TokensRecipient` implementation via ERC820
        self._checkForERC777TokensInterface_Recipient(msg.sender, _from, _to, _amount, _data, _operatorData)

    self.balanceOf[_from] -= _amount
    # add balance to recipient
    self.balanceOf[_to] += _amount
    # fire sent event
    log.Sent(msg.sender, _from, _to, _amount, _data, _operatorData)


@public
def burn(_amount: uint256):
    # Any minting, send or burning of tokens MUST be a multiple of
    # the granularity value.
    assert _amount % self.granularity == 0
    # remove amount from sender
    self.balanceOf[msg.sender] -= _amount
    # burn
    self.balanceOf[ZERO_ADDRESS] += _amount
    # update totalSupply
    self.totalSupply -= _amount
    # fire burned event
    # NOTE: quoting @0xjac:
    #       In `Sent`, the `userData` is intended for the recipient not the sender.
    #       With `Burned` there is no recipient so the `userData` would be intended to no one.
    log.Burned(msg.sender, msg.sender, _amount, "")


@public
def operatorBurn(_from: address, _amount: uint256, _operatorData: bytes[256]=""):
    # NOTE: The operator MAY pass information
    # check if msg.sender is operator for _from
    # NOTE: An address MUST always be an operator for itself
    isSelf: bool = msg.sender == _from
    isDefaultOperator: bool = self.defaultOperators[_from]
    isOperator: bool = self.operators[_from][msg.sender]
    assert (isSelf or isDefaultOperator or isOperator)
    # Any minting, send or burning of tokens MUST be a multiple of
    # the granularity value.
    assert _amount % self.granularity == 0
    # remove from balance
    self.balanceOf[_from] -= _amount
    # burn
    self.balanceOf[ZERO_ADDRESS] += _amount
    # update totalSupply
    self.totalSupply -= _amount
    # fire burned event
    log.Burned(msg.sender, _from, _amount, _operatorData)
