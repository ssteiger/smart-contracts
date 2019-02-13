# Author: Sören Steiger, github.com/ssteiger
# License: MIT

# ICO for ERC721 Tokens
# https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md

# WARNING: This contract has not been tested and should not be
#          used in production!


contract ERC721Contract:
    def mint(_to: address, _tokenId: uint256) -> bool: modifying


# EVENTS:
NFTSold: event({_from: indexed(address), _amount: wei_value})
NFTSoldThresholdReached: event({_nftSoldCount: uint256})
AllNFTsSold: event({_nftSoldCount: uint256})

NFTClaimed: event({_to: indexed(address), _tokenId: uint256})
AllNFTsClaimed: event({_totalNftsClaimed: uint256})

FundsTransfered: event({_to: indexed(address), _amount: wei_value})
FundsWithdrawn: event({_to: indexed(address), _amount: wei_value})


# STATE VARIABLES:
contractOperator: public(address)

erc721TokenContract: public(address)

nrOfNftsToSell: public(uint256)
minAmountToSell: public(uint256)
pricePerNFT: public(wei_value)

openAtBlock: public(uint256)
durationInBlocks: public(uint256)

nftSoldCount: public(uint256)
nftClaimedCount: public(uint256)

# allows backers to reclaim their ether if
# ico is closed and funding goal was not reached
weiBalanceOf: map(address, wei_value)
claimableNftBalanceOf: map(address, uint256)


# CONSTANTS
ZERO_WEI: constant(wei_value) = as_wei_value(0, 'wei')


@public
def __init__(_erc721TokenContract: address,
             _nrOfNftsToSell: uint256,
             _minAmountToSell: uint256,
             _pricePerNFT: uint256, # in wei
             _openAtBlock: uint256,
             _durationInBlocks: uint256
    ):
    self.contractOperator = msg.sender
    self.erc721TokenContract = _erc721TokenContract

    self.nrOfNftsToSell = _nrOfNftsToSell
    self.minAmountToSell = _minAmountToSell
    self.pricePerNFT = as_wei_value(_pricePerNFT, 'wei')

    self.openAtBlock = _openAtBlock
    self.durationInBlocks = _durationInBlocks

    self.nftSoldCount = 0
    self.nftClaimedCount = 0


@public
@payable
def __default__():
    # if there are nfts left to buy
    assert self.nftSoldCount <= self.nrOfNftsToSell
    # if ico is running
    assert block.number >= self.openAtBlock
    assert block.number < (self.openAtBlock + self.durationInBlocks)
    assert msg.value >= self.pricePerNFT
    # if backer overpaid
    if (msg.value > self.pricePerNFT):
        # calculate surplus
        surplus: wei_value
        surplus = msg.value - self.pricePerNFT
        # add correct value to backers balance
        self.weiBalanceOf[msg.sender] += (msg.value - surplus)
        # return surplus to backer
        send(msg.sender, surplus)
    else:
        # backer sent exact amount
        # add value to backer balance
        self.weiBalanceOf[msg.sender] += msg.value

    self.claimableNftBalanceOf[msg.sender] += 1
    self.nftSoldCount += 1
    # fire funding received event
    log.NFTSold(msg.sender, msg.value)

    if (self.nftSoldCount == self.minAmountToSell):
        log.NFTSoldThresholdReached(self.nftSoldCount)
    if (self.nftSoldCount == self.nrOfNftsToSell):
        log.AllNFTsSold(self.nftSoldCount)


# METHODS:
@public
def withdraw():
    # if ICO duration has passed
    assert block.number >= (self.openAtBlock + self.durationInBlocks)
    # if threshold was not reached
    assert self.nftSoldCount < self.minAmountToSell
    # if backer has funds to withdraw
    assert self.weiBalanceOf[msg.sender] > ZERO_WEI
    # get amount of ether backer can withdraw
    amount: wei_value
    amount = self.weiBalanceOf[msg.sender]
    # set amount of claimable ether of backer to zero
    self.weiBalanceOf[msg.sender] = ZERO_WEI
    # return ether to backer
    send(msg.sender, amount)
    log.FundsWithdrawn(msg.sender, amount)


@public
def claimNFToken():
    # TODO: currently backers have to call this for each of their
    #       nft's they can claim.
    #       can this be optimized?
    # if min threshold was reached
    assert self.nftSoldCount >= self.minAmountToSell
    # if ICO has been successfully completed
    soldOut: bool = self.nftSoldCount == self.nrOfNftsToSell
    durationPassed: bool = block.number >= (self.openAtBlock + self.durationInBlocks)
    assert (soldOut or durationPassed)
    # if backer has nft's to claim
    assert self.claimableNftBalanceOf[msg.sender] > 0
    # reduce amount of claimable tokens of backer by 1
    self.claimableNftBalanceOf[msg.sender] -= 1
    # determine tokenId
    tokenId: uint256 = self.nftClaimedCount
    self.nftClaimedCount += 1
    # send nft to backer
    # WARNING: make sure that mint() is implemented in the ERC721 Token Contract
    #          and this contract is allowed to mint()
    ERC721Contract(self.erc721TokenContract).mint(msg.sender, tokenId)
    # fire token transfer event
    log.NFTClaimed(msg.sender, tokenId)

    if (self.nftClaimedCount == self.nftSoldCount):
        log.AllNFTsClaimed(tokenId)


@public
def moveFunds(_to: address):
    # only allow contractOperator to move funds
    assert msg.sender == self.contractOperator
    # if min threshold has been reached
    assert self.nftSoldCount >= self.minAmountToSell
    # if ICO has been successfully completed
    soldOut: bool = self.nftSoldCount == self.nrOfNftsToSell
    durationPassed: bool = block.number >= (self.openAtBlock + self.durationInBlocks)
    assert (soldOut or durationPassed)
    # fire funds transfer event
    log.FundsTransfered(_to, self.balance)
    # transfer all ether in this contract
    send(_to, self.balance)


@public
def cancelICO():
    # only allow contractOperator to perform this operation
    assert msg.sender == self.contractOperator
    # if ico has not started
    assert block.number < self.openAtBlock
    # delete this contract
    # NOTE: parameter: the address to send the contracts left ether to
    selfdestruct(msg.sender)
