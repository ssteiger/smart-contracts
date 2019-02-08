# Author: Sören Steiger, github.com/ssteiger
# License: MIT

# ERC777 Token Standard (https://github.com/ethereum/EIPs/issues/777)


# EVENTS:
Minted: event({operator: indexed(address), to: indexed(address), amount: uint256, data: bytes, operatorData: bytes)
Burned: event({operator: indexed(address), to: indexed(address), amount: uint256, data: bytes, operatorData: bytes)

AuthorizedOperator: event({operator: indexed(address), tokenHolder: indexed(address)})
RevokedOperator: event({operator: indexed(address), tokenHolder: indexed(address)})
Sent: event({operator: indexed(address), from: indexed(address), to: indexed(address), amount: uint256, data: bytes, operatorData: bytes})



# STATE VARIABLES:
name: public(string[16]) # TODO: is this an acceptable size?
symbol: public(string[16]) # TODO: is this an acceptable size?
total_supply: public(uint256)
granularity: public(uint256)

balanceOf: map(address, uint256)
# TODO: map for operators

# METHODS:

@public
@constant
def defaultOperators() -> address[]:

@public
def authorizeOperator(operator: address):

@public
def revokeOperator(operator: address):

@public
@constant
def isOperatorFor(operator: address, tokenHolder: address) -> bool:

@public
def send(to: address, amount: uint256, data: bytes):

@public
def operatorSend(from: address, to: address, amount: uint256, data: bytes, operatorData: bytes):

@public
def burn(amount: uint256):

@public
def operatorBurn(from: address, amount: uint256, operatorData: bytes):
