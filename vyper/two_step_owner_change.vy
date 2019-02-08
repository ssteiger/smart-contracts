# Author: Sören Steiger, github.com/ssteiger
# License: MIT

# ----------------------------------------------------------
# Two step owner change:

# 1. step: Signal intent to change owner of this contract
# 2. step: Executed actual change (within the next n minutes)

# ---------------------- from the docs ----------------------
# Public variables:

# By declaring the variable public, the variable is callable
# by external contracts.
# Initializing the variables without the public function
# defaults to a private declaration and thus only accessible
# to methods within the same contract.
# The public function additionally creates a ‘getter’
# function for the variable, accessible through an external
# call such as contract.varibale_name().

# Time-related variables:

# Type      | Unit  | Base type | Description
# ----------------------------------------------------------
# timestamp | 1 sec | uint256   | represents a point in time
# timedelta | 1 sec | uint256   | is a number of seconds
# ----------------------------------------------------------

# owner of this contract
owner: public(address)
# flag for indicating if 1. step has been completed
flag_init: public(bool)
# time when 1. step was completed
# is used to check if time between 1. step and 2. step is inside window
time_of_initialization: public(timestamp)
# time allowed to pass between completion of 1. step and completion of 2. step
window: public(timedelta)
# helper for temporally storing the address of the new owner
new_owner_candidate: public(address)


@public
def __init__():
    self.owner = msg.sender
    self.flag_init = False


@public
def initiate_change_owner(_address: address):
    # check if sender is allowed to make this change
    assert self.owner == msg.sender
    # update new owner candidate
    self.new_owner_candidate = _address
    # update initialization time, used for checking against window
    self.time_of_initialization = block.timestamp
    # mark 1. step as completed
    self.flag_init = True


@public
def change_owner(_newOwner: address):
    # check if sender is allowed to make this change
    assert self.owner == msg.sender
    # check if first step of process has been completed
    assert self.flag_init == True
    # check if call is inside the specified window
    assert (block.timestamp - self.time_of_initialization) < self.window
    # check if intent of 1. step matches intent of 2. step
    assert self.new_owner_candidate == _newOwner
    # set new owner
    self.owner = _newOwner
    # done
    # reset 1. step flag
    self.flag_init = False


@public
def set_time_window(_new_duration: timedelta):
    # _new_duration [in number of seconds]
    # check if sender is allowed to make this change
    assert self.owner == msg.sender
    # reset 1. step flag
    self.flag_init = False
    # update the allowed time frame between 1. step and 2. step
    self.window = _new_duration
