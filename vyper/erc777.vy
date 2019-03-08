# Author: Sören Steiger, github.com/ssteiger
# License: MIT

# ERC777 Token Standard (https://eips.ethereum.org/EIPS/eip-777)


# NOTICE: This contract is a work-in-progress and should not be used in production!


# INTERFACES:
# Interface for ERC777Tokens sender contracts
contract ERC777TokensSender:
    def tokensToSend(
        _operator: address,
        _from: address,
        _to: address,
        _amount: uint256,
        _data: bytes[256],
        _operatorData: bytes[256]
    ) -> bytes32: constant

# Interface for ERC777Tokens recipient contracts
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
# TODO:
# https://github.com/ethereum/EIPs/issues/777#issuecomment-461967464
# https://github.com/ethereum/EIPs/issues/777#issuecomment-465987000
Minted: event({
    _operator: indexed(address),
    _to: indexed(address),
    _amount: uint256,
    _operatorData: bytes[256]
})

# TODO:
# https://github.com/ethereum/EIPs/issues/777#issuecomment-461967464
Burned: event({
    _operator: indexed(address), # Address which triggered the burn.
    _from: indexed(address),     # Token holder whose tokens are burned.
    _amount: uint256,            # Token holder whose tokens are burned.
    _data: bytes[256],           # Information provided by the token holder.
    _operatorData: bytes[256]    # Information provided by the operator.
})

AuthorizedOperator: event({
    _operator: indexed(address),   # Address which became an operator of tokenHolder.
    _tokenHolder: indexed(address) # Address of a token holder which authorized the operator address as an operator.
})

RevokedOperator: event({
    _operator: indexed(address),   # Address which was revoked as an operator of tokenHolder.
    _tokenHolder: indexed(address) # Address of a token holder which revoked the operator address as an operator.
})

Sent: event({
    _operator: indexed(address), # Address which triggered the send.
    _from: indexed(address),     # Token holder.
    _to: indexed(address),       # Token recipient.
    _amount: uint256,            # Number of tokens to send.
    _data: bytes[256],           # Information provided by the token holder.
    _operatorData: bytes[256]    # Information provided by the operator.
})


# STATE VARIABLES:
# NOTE: this is not defined in the spec
owner: public(address)

name: public(string[32])
symbol: public(string[16])
totalSupply: public(uint256)
granularity: public(uint256)

balanceOf: map(address, uint256)
# The token MAY define default operators.
# A default operator is an implicitly authorized operator for all token holders.
defaultOperators: public(map(address, bool))
operators: public(map(address, map(address, bool)))

supportedInterfaces: public(map(bytes32, bool))

# ERC165 interface ID of ERC165
# TODO: shorten this -> maybe: constant(bytes32) = convert(1ffc9a7, bytes32)
ERC165_INTERFACE_ID: constant(bytes32) = 0x0000000000000000000000000000000000000000000000000000000001ffc9a7
# TODO: implement this
#ERC777_INTERFACE_ID: constant(bytes32) = bytes32(keccak256(this))


# METHODS:
# TODO:
# see: https://github.com/ethereum/vyper/issues/1332
@public
def __init__(_name: string[32],
             _symbol: string[16],
             _totalSupply: uint256,
             _granularity: uint256,
             _defaultOperators: address[4]
            ):
    # owner is allowed to perform mint()
    # NOTE: this is not defined in the spec
    self.owner = msg.sender
    # set token name and symbol
    self.name = _name
    self.symbol = _symbol
    # NOTE: granularity MUST be greater or equal to 1
    assert _granularity > 0
    self.granularity = _granularity
    # NOTE: The token MUST define default operators at creation time
    #       The token contract MUST NOT add or remove default operators ever
    for i in range(4):
        if _defaultOperators[i] != ZERO_ADDRESS:
            self.defaultOperators[_defaultOperators[i]] = True
    # set supported interfaces
    self.supportedInterfaces[ERC165_INTERFACE_ID] = True
    # TODO:
    #self.supportedInterfaces[ERC777_INTERFACE_ID] = True
    # mint tokens
    self.totalSupply = _totalSupply
    self.balanceOf[msg.sender] = _totalSupply
    # fire minted event
    operatorData: bytes[256] = ""
    log.Minted(msg.sender, msg.sender, _totalSupply, operatorData)


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
def authorizeOperator(_operator: address):
    # NOTE: A token holder MAY have multiple operators at the same time.
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
    isOperator: bool = (self.operators[_tokenHolder])[_operator]
    # at least one of the above
    isOperatorFor: bool = (isSelf or isDefaultOperator or isOperator)
    return isOperatorFor


# TODO: verify that this check works
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
    # NOTE: This makes the call (call executes) and returns the bytestring.
    returnValue: bytes32 = ERC777TokensSender(_from).tokensToSend(_operator, _from, _to, _amount, _data, _operatorData)
    assert returnValue == method_id("tokensToSend(address,address,address,uint256,bytes,bytes)", bytes32)


# TODO: verify that this check works
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
    # NOTE: This makes the call (call executes) and returns the bytestring.
    returnValue: bytes32 = ERC777TokensRecipient(_to).tokensReceived(_operator, _from, _to, _amount, _data, _operatorData)
    assert returnValue == method_id("tokensReceived(address,address,address,uint256,bytes,bytes)", bytes32)


@private
def _transferFunds(_operator: address,
                   _from: address,
                   _to: address,
                   _amount: uint256,
                   _data: bytes[256]="",
                   _operatorData: bytes[256]=""
                  ):
    # NOTE: Any minting, send or burning of tokens MUST be a multiple of the
    #       granularity value.
    assert _amount % self.granularity == 0
    # check if `msg.sender` is a contract address
    if _from.is_contract:
        # NOTE: The token contract MUST call the `tokensToSend` hook of the token holder
        #       if the token holder registers an `ERC777TokensSender` implementation via ERC820.
        #       The token contract MUST call the `tokensToSend` hook before updating the state.
        self._checkForERC777TokensInterface_Sender(_operator, _from, _to, _amount, _data, _operatorData)
    # Update the state
    # update balance of sender
    self.balanceOf[_from] -= _amount
    # update balance of recipient
    self.balanceOf[_to] += _amount
    # only check for `tokensReceived` hook if transfer is not a burn
    if _to != ZERO_ADDRESS:
        # check if recipient is a contract address
        if _to.is_contract:
            # NOTE: The token contract MUST call the `tokensReceived` hook of the recipient
            #       if the recipient registers an `ERC777TokensRecipient` implementation via ERC820.
            #       The token contract MUST call the `tokensReceived` hook after updating the state.
            self._checkForERC777TokensInterface_Recipient(_operator, _from, _to, _amount, _data, _operatorData)


@public
def send(_to: address,        # Token recipient.
         _amount: uint256,    # Number of tokens to send.
         _data: bytes[256]="" # Information provided by the token holder.
        ):
    assert _to != ZERO_ADDRESS
    # NOTE: The operator and the token holder MUST both be the msg.sender
    self._transferFunds(msg.sender, msg.sender, _to, _amount, _data)
    # fire sent event
    log.Sent(msg.sender, msg.sender, _to, _amount, _data, "")


@public
def operatorSend(_from: address,              # Token holder (or 0x0 to set from to msg.sender).
                 _to: address,                # Token recipient.
                 _amount: uint256,            # Number of tokens to send.
                 _data: bytes[256]="",        # Information provided by the token holder.
                 _operatorData: bytes[256]="" # Information provided by the operator.
                ):
    assert _to != ZERO_ADDRESS
    # check if msg.sender is operator for _from
    isOperatorFor: bool = self.isOperatorFor(msg.sender, _from)
    assert isOperatorFor
    self._transferFunds(msg.sender, _from, _to, _amount, _data, _operatorData)
    # fire sent event
    log.Sent(msg.sender, _from, _to, _amount, _data, _operatorData)


@public
def burn(_amount: uint256,    # Number of tokens to burn.
         _data: bytes[256]="" # Information provided by the token holder.
        ):
    # burn tokens
    self._transferFunds(msg.sender, msg.sender, ZERO_ADDRESS, _amount, _data)
    # fire burned event
    log.Burned(msg.sender, msg.sender, _amount, _data, "")


@public
def operatorBurn(_from: address,              # Token holder whose tokens will be burned.
                 _amount: uint256,            # Number of tokens to burn.
                 _data: bytes[256]="",        # Information provided by the token holder.
                 _operatorData: bytes[256]="" # Information provided by the operator.
                ):
    # _from: Token holder whose tokens will be burned (or 0x0 to set from to msg.sender).
    if _from == ZERO_ADDRESS:
        fromAddress: address = msg.sender
    else:
        fromAddress: address = _from
    # check if msg.sender is operator for _from
    isOperatorFor: bool = self.isOperatorFor(msg.sender, fromAddress)
    assert isOperatorFor
    # burn tokens
    self._transferFunds(msg.sender, fromAddress, ZERO_ADDRESS, _amount, _data, _operatorData)
    # fire burned event
    log.Burned(msg.sender, fromAddress, _amount, _data, _operatorData)


# NOTE: ERC777 intentionally does not define specific functions to mint tokens.
@public
def mint(_operator: address,
         _to: address,
         _amount: uint256,
         _operatorData: bytes[256]=""
        ):
    # only owner is allowed to mint
    # NOTE: this is not defined in the spec
    assert msg.sender == self.owner #or self.defaultOperators[msg.sender]
    # NOTE: The token contract MUST revert if the address of the recipient is 0x0
    assert _to != ZERO_ADDRESS
    # NOTE: Any minting, send or burning of tokens MUST be a multiple of the
    #       granularity value.
    assert _amount % self.granularity == 0
    # mint tokens
    # add minted tokens to balance of recipient
    self.balanceOf[_to] += _amount
    # update total supply
    self.totalSupply += _amount
    # check if recipient is a contract address
    if _to.is_contract:
        # NOTE: The token contract MUST revert if the recipient is a contract, and
        #       does not implement the `ERC777TokensRecipient` interface via ERC820.
        #       The token contract MUST call the `tokensReceived` hook after
        #       updating the state.
        #
        #       The data and operatorData MUST be immutable during the entire
        #       mint process—hence the same data and operatorData MUST be used
        #       to call the tokensReceived hook and emit the Minted event.
        #       The data field MUST be empty.
        #
        #       from: token holder for a send and 0x for a mint
        self._checkForERC777TokensInterface_Recipient(_operator, ZERO_ADDRESS, _to, _amount, "", _operatorData)
    # fire minted event
    log.Minted(msg.sender, _to, _amount, _operatorData)
