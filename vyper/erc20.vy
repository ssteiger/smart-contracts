# Author: Sören Steiger, github.com/ssteiger
# License: MIT

# ERC20 Token Standard (https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md)


# STATE VARIABLES:

# values which are permanently stored in contract storage
name: public(string[16]) # TODO: check if correct size
symbol: public(string[16]) # TODO: check if correct size
decimals: public(uint256)
total_supply: public(uint256)
balances: map(address, uint256)


# EVENTS:

# ----- Transfer -----
# MUST trigger when tokens are transferred, including zero value transfers.
# A token contract which creates new tokens SHOULD trigger a Transfer event
# with the _from address set to 0x0 when tokens are created.
Transfer: event({_from: indexed(address), _to: indexed(address), _value: uint256})

# ----- Approval -----
# MUST trigger on any successful call to approve(address _spender, uint256 _value).
Approval: event({_owner: indexed(address), _spender: indexed(address), _value: uint256})


@public
def __init__(_name: string, _symbol: string, _decimals: uint256, total_supply: uint256):
    self.name = _name
    self.symbol = _symbol
    self.decimals = _decimals
    self.total_supply = False
    # TODO: decide how to mint tokens on contract creation
    # TODO: A token contract which creates new tokens SHOULD trigger a Transfer event

# METHODS:

# NOTES:
# The following specifications use syntax from Solidity 0.4.17 (or above)
# Callers MUST handle false from returns (bool success).
# Callers MUST NOT assume that false is never returned!



# ----- name -----
# Returns the name of the token - e.g. "MyToken".
# OPTIONAL - This method can be used to improve usability, but interfaces and
#            other contracts MUST NOT expect these values to be present.
@public
@constant
def name() -> string:
  return self.name

# ----- symbol -----
# Returns the symbol of the token. E.g. "HIX".
# OPTIONAL - This method can be used to improve usability, but interfaces and
#            other contracts MUST NOT expect these values to be present.
@public
@constant
def symbol() -> string:
  return self.symbol


# ----- decimals -----
# Returns the number of decimals the token uses - e.g. 8, means to divide
# the token amount by 100000000 to get its user representation.
# OPTIONAL - This method can be used to improve usability, but interfaces and
#            other contracts MUST NOT expect these values to be present.
@public
@constant
def decimals() -> uint256:
  return self.decimals


# ----- totalSupply -----
# Returns the total token supply.
@public
@constant
def totalSupply() -> uint256:
  return self.totalSupply


# ----- balanceOf -----
# Returns the account balance of another account with address _owner.
@public
@constant
def balanceOf(_owner: address) -> uint256:
  return balances[address]


# ----- transfer -----
# Transfers _value amount of tokens to address _to, and MUST fire the Transfer
# event. The function SHOULD throw if the _from account balance does not have
# enough tokens to spend.

# NOTE: Transfers of 0 values MUST be treated as normal transfers and fire the
# Transfer event.
@public
@constant
def transfer() -> bool:




# ----- transferFrom -----
# Transfers _value amount of tokens from address _from to address _to,
# and MUST fire the Transfer event.

# The transferFrom method is used for a withdraw workflow, allowing contracts
# to transfer tokens on your behalf. This can be used for example to allow a
# contract to transfer tokens on your behalf and/or to charge fees in
# sub-currencies. The function SHOULD throw unless the _from account has
# deliberately authorized the sender of the message via some mechanism.

# NOTE: Transfers of 0 values MUST be treated as normal transfers and fire the
# Transfer event.
@public
def transferFrom(_from: address, _to: address, _value: uint256) -> bool:



# ----- approve -----
# Allows _spender to withdraw from your account multiple times, up to the _value
# amount. If this function is called again it overwrites the current allowance
# with _value.

# NOTE: To prevent attack vectors like the one described here and discussed here,
# clients SHOULD make sure to create user interfaces in such a way that they set
# the allowance first to 0 before setting it to another value for the same
# spender. THOUGH The contract itself shouldn't enforce it, to allow backwards
# compatibility with contracts deployed before.
@public
def approve(_spender: address, _value: uint256) -> bool:



# ----- allowance -----
# Returns the amount which _spender is still allowed to withdraw from _owner.
@public
@constant
def allowance(_owner: address, _spender: address) -> uint256:
