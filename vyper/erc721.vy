# Author: Sören Steiger, github.com/ssteiger
# License: MIT

# ERC721 Token Standard
# https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md


# EVENTS:

# @dev This emits when ownership of any NFT changes by any mechanism.
# This event emits when NFTs are created (`from` == 0) and destroyed
# (`to` == 0). Exception: during contract creation, any number of NFTs
# may be created and assigned without emitting Transfer. At the time of
# any transfer, the approved address for that NFT (if any) is reset to none.
Transfer: event({
    _from: indexed(address),
    _to: indexed(address),
    _tokenId: indexed(uint256)
})


# @dev This emits when the approved address for an NFT is changed or
# reaffirmed. The zero address indicates there is no approved address.
# When a Transfer event emits, this also indicates that the approved
# address for that NFT (if any) is reset to none.
Approval: event({
    _owner: indexed(address),
    _approved: indexed(address),
    _tokenId: indexed(uint256)
})


# @dev This emits when an operator is enabled or disabled for an owner.
# The operator can manage all NFTs of the owner.
ApprovalForAll: event({
    _owner: indexed(address),
    _approved: indexed(address),
    _approved: bool)
})



# STATE VARIABLES:

# @notice Count all NFTs assigned to an owner
# @dev NFTs assigned to the zero address are considered invalid, and this
# function throws for queries about the zero address.
# @param _owner An address for whom to query the balance
# @return The number of NFTs owned by `_owner`, possibly zero
# function balanceOf(address _owner) external view returns (uint256);
balanceOf: public(map(address, uint256))

# @notice Find the owner of an NFT
# @dev NFTs assigned to zero address are considered invalid, and queries
# about them do throw.
# @param _tokenId The identifier for an NFT
# @return The address of the owner of the NFT
# function ownerOf(uint256 _tokenId) external view returns (address);
ownerOf: public(map(uint256, address))

supportedInterfaces: public(map(bytes32, bool))

# ERC165 interface ID of ERC165
ERC165_INTERFACE_ID: constant(bytes32) = 0x0000000000000000000000000000000000000000000000000000000001ffc9a7




# METHODS:
@public
def __init__():
    self.supportedInterfaces[ERC165_INTERFACE_ID] = True


# @notice Transfers the ownership of an NFT from one address to another address
# @dev Throws unless `msg.sender` is the current owner, an authorized
# operator, or the approved address for this NFT. Throws if `_from` is
# not the current owner. Throws if `_to` is the zero address. Throws if
# `_tokenId` is not a valid NFT. When transfer is complete, this function
# checks if `_to` is a smart contract (code size > 0). If so, it calls
# `onERC721Received` on `_to` and throws if the return value is not
# `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
# @param _from The current owner of the NFT
# @param _to The new owner
# @param _tokenId The NFT to transfer
# @param data Additional data with no specified format, sent in call to `_to`
# function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable;
@public
@payable
def safeTransferFrom(_from: address, _to: address, _tokenId: uint256, _data bytes[256]=""):
		# Throws if `_to` is the zero address.
		assert _to != ZERO_ADDRESS
		# Throws if `_from` is not the current owner.
		# TODO: check if is approved
		# TODO: update/reset approvals
		assert self.ownerOf[_tokenId] == _from

		# assign token to _to
		self.ownerOf[_tokenId] = _to
		# updated balances
		self.balanceOf[_from] -= 1
		self.balanceOf[_to] += 1
		# log transfer
		log.Transfer(_from, _to, _tokenId)

		# When transfer is complete,
		# this function checks if `_to` is a smart contract (code size > 0)
		if _to.is_contract:
				#  If so, it calls `onERC721Received` on `_to`
				#  and throws if the return value is not
				# `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
				returnValue: bytes32 = ERC777TokensRecipient(_to).tokensReceived("", msg.sender, _to, _amount, _data, "")
				assert returnValue == method_id("onERC721Received(address,address,uint256,bytes)", bytes32)



# @notice Transfers the ownership of an NFT from one address to another address
# @dev This works identically to the other function with an extra data parameter,
# except this function just sets data to "".
# @param _from The current owner of the NFT
# @param _to The new owner
# @param _tokenId The NFT to transfer
# function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;


# @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
# TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
# THEY MAY BE PERMANENTLY LOST
# @dev Throws unless `msg.sender` is the current owner, an authorized
# operator, or the approved address for this NFT. Throws if `_from` is
# not the current owner. Throws if `_to` is the zero address. Throws if
# `_tokenId` is not a valid NFT.
# @param _from The current owner of the NFT
# @param _to The new owner
# @param _tokenId The NFT to transfer
# function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
@public
@payable
def transferFrom(_from: address, _to: address, _tokenId: uint256):


# @notice Change or reaffirm the approved address for an NFT
# @dev The zero address indicates there is no approved address.
# Throws unless `msg.sender` is the current NFT owner, or an authorized
# operator of the current owner.
# @param _approved The new approved NFT controller
# @param _tokenId The NFT to approve
# function approve(address _approved, uint256 _tokenId) external payable;
@public
@payable
def approve(_approved: address, _tokenId: uint256):


# @notice Enable or disable approval for a third party ("operator") to manage
# all of `msg.sender`'s assets
# @dev Emits the ApprovalForAll event. The contract MUST allow
# multiple operators per owner.
# @param _operator Address to add to the set of authorized operators
# @param _approved True if the operator is approved, false to revoke approval
# function setApprovalForAll(address _operator, bool _approved) external;
@public
def setApprovalForAll(_operator: address, _approved: bool):


# @notice Get the approved address for a single NFT
# @dev Throws if `_tokenId` is not a valid NFT.
# @param _tokenId The NFT to find the approved address for
# @return The approved address for this NFT, or the zero address if there is none
# function getApproved(uint256 _tokenId) external view returns (address);
@public
def getApproved(_tokenId: uint256) -> address:


# @notice Query if an address is an authorized operator for another address
# @param _owner The address that owns the NFTs
# @param _operator The address that acts on behalf of the owner
# @return True if `_operator` is an approved operator for `_owner`, false otherwise
# function isApprovedForAll(address _owner, address _operator) external view returns (bool);
@public
def isApprovedForAll(_owner: address, _operator: address) -> bool:
