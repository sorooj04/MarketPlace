// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;
import "hardhat/console.sol";

interface IERC721{
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    function balanceOf(address _owner) external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable;

    function approve(address _approved, uint256 _tokenId) external;

    function setApprovalForAll(address _operator, bool _approved) external;

    function getApproved(uint256 _tokenId) external view returns (address);

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool);

    function _mint(address to, uint id) external;

    function _burn(uint id) external;

}

interface IERC4907 is IERC721 {
    event UpdateUser(
        uint256 indexed tokenId,
        address indexed user,
        uint64 expires
    );

    function setUser(
        uint256 tokenId,
        address user,
        uint64 expires
    ) external;

    function userOf(uint256 tokenId) external view returns (address);

    function userExpires(uint256 tokenId) external view returns (uint256);

}
contract ERC721 is IERC721{
    mapping(address => uint) public _balanceOf;
    mapping(uint => address) public _ownerOf;
    mapping(uint => address) public _approved;
    mapping(address => mapping(address => bool)) public _isApprovedForAll;

    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0), "invalid address");
        return _balanceOf[_owner];
    }

    function ownerOf(uint256 _tokenId) external view returns (address) {
        address owner = _ownerOf[_tokenId];
        require(owner != address(0), "invalid address");
        return owner;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public payable {
        require(
            _ownerOf[_tokenId] == _from && _from != address(0),
            "Not owner"
        );
        require(_to != address(0), "Incorect _to");
        require(
            msg.sender == _from ||
                _isApprovedForAll[_from][msg.sender] ||
                _approved[_tokenId] == msg.sender,
            "Not Allowed!"
        );

        // require(
        //     block.timestamp > lessees[_tokenId].expires,
        //     "NFT Rented cannot transfer"
        // );
        _beforeTokenTransfer(_tokenId);

        _balanceOf[_from]--;
        _balanceOf[_to]++;
        _ownerOf[_tokenId] = _to;

        delete _approved[_tokenId];
        emit Transfer(_from, _to, _tokenId);
    }

    function approve(address approved, uint256 _tokenId) public {
        console.log(msg.sender);
        address ownedBy = _ownerOf[_tokenId];
        require(
            ownedBy == msg.sender ||
                _isApprovedForAll[ownedBy][msg.sender] == true,
            "You are Not Authorized"
        );
        _approved[_tokenId] = approved;
        emit Approval(ownedBy, approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool approved) external {
        _isApprovedForAll[msg.sender][_operator] = approved;
        emit ApprovalForAll(msg.sender, _operator, approved);
    }

    function getApproved(uint256 _tokenId) external view returns (address) {
        require(_ownerOf[_tokenId] != address(0), "token doesn't exist");
        return _approved[_tokenId];
    }

    function _mint(address to, uint id) external {
        require(to != address(0), "mint to zero address");
        require(_ownerOf[id] == address(0), "already minted");

        _balanceOf[to]++;
        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint id) external {
        address owner = _ownerOf[id];
        require(owner != address(0), "not minted");

        _balanceOf[owner] -= 1;

        delete _ownerOf[id];
        delete _approved[id];

        emit Transfer(owner, address(0), id);
    }

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool)
    {
        return _isApprovedForAll[_owner][_operator];
    }

    function _beforeTokenTransfer(uint256 tokenId) internal virtual {}

}

contract ERC4907 is ERC721, IERC4907 {
    struct Lessee {
        address user;
        uint expires;
    }

    mapping(uint256 => Lessee) internal lessees;

    function setUser(
        uint256 tokenId,
        address user,
        uint64 expires
    ) public {
        require(user != address(0), "no user");
        address owner = _ownerOf[tokenId];
        require(owner != address(0), " not valid NFT");
        require(
            (msg.sender == owner ||
                _isApprovedForAll[owner][msg.sender] ||
                msg.sender == _approved[tokenId]),
            "Not Alowed"
        );
        Lessee storage info = lessees[tokenId];
        info.user = user;
        info.expires = block.timestamp + expires;
        emit UpdateUser(tokenId, user, expires);
    }

    function userOf(uint256 tokenId) public view returns (address) {
        if (uint256(lessees[tokenId].expires) >= block.timestamp) {
            return lessees[tokenId].user;
        } else {
            return address(0);
        }
    }

    function userExpires(uint256 tokenId) public view returns (uint256) {
        return lessees[tokenId].expires;
    }

    function _beforeTokenTransfer(uint256 tokenId) internal virtual override{
        require(
            block.timestamp > lessees[tokenId].expires,
            "NFT Rented cannot transfer because it is Rented!"
        );

        console.log("child contract before executed");
    }
}

contract NFTMarketPlace {
    struct Item {
        address seller;
        // address tokenContract;
        uint tokenId;
        uint price;
        bool status;
    }

    mapping(uint => uint) public marketMappingKeys;
    mapping(uint => bool) public alreadyExixts;
    Item[] public market;
    address payable public owner;
    uint public itemId;
    uint public listingfee;
    address public tokenContract;

    constructor(address _tokenContract, uint _listingfee) {
        owner = payable(msg.sender);
        itemId = 0;
        listingfee = _listingfee;
        tokenContract = _tokenContract;
    }

    event NFTListed(
        address sender,
        address _tokenContract,
        uint _tokenId,
        uint _price,
        uint itemId
    );

    function listNFT(
        // address _tokenContract,
        uint _tokenId,
        uint _price
    ) external payable {
        address tokenOwner = IERC4907(tokenContract).ownerOf(_tokenId);

        require(
            tokenOwner == msg.sender ||
                IERC4907(tokenContract).isApprovedForAll(
                    tokenOwner,
                    msg.sender
                ),
            "Youre not owner"
        );
        require(
            IERC4907(tokenContract).getApproved(_tokenId) == address(this),
            "Approve this contract first"
        );
        require(msg.value >= listingfee, "Not Enough Listing Fee");
        require(alreadyExixts[_tokenId] == false,"already Listed For sale");

        Item memory item = Item({
            seller: msg.sender,
            tokenId: _tokenId,
            price: _price,
            status: true
        });

        marketMappingKeys[_tokenId] = itemId;
        market.push(item);
        alreadyExixts[_tokenId] = true;

        emit NFTListed(msg.sender, tokenContract, _tokenId, _price, itemId);
        ++itemId;
    }

    function buyNFT(uint _tokenId) external payable {
        require(
            msg.value >= market[marketMappingKeys[_tokenId]].price,
            "Insufficient balance Transfered!"
        );
        require(market[marketMappingKeys[_tokenId]].status, "Already sold");
        IERC4907(tokenContract).transferFrom(
            market[marketMappingKeys[_tokenId]].seller,
            msg.sender,
            market[marketMappingKeys[_tokenId]].tokenId
        );

        market[marketMappingKeys[_tokenId]].status = false;
        delete alreadyExixts[_tokenId];
        (bool success, ) = market[marketMappingKeys[_tokenId]].seller.call{value: msg.value}("");
        require(success, "Failed to send funds to the seller");

        // delete market[marketMappingKeys[_tokenId]];
    }

    function deleteNFT(uint _tokenId) public {
        require(msg.sender == market[marketMappingKeys[_tokenId]].seller, "not auhorized");
        delete alreadyExixts[_tokenId];
        delete market[marketMappingKeys[_tokenId]];
    }

    function updateNFT(uint _tokenId) public {
        require(
            msg.sender == market[marketMappingKeys[_tokenId]].seller || msg.sender == owner,
            "not auhorized"
        );
        market[marketMappingKeys[_tokenId]].status = false;
         delete alreadyExixts[_tokenId];
    }

    function withraw() public {
        require(msg.sender == owner, "Only Owner");
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Failed to send funds to the Owner");
    }

    function getAllItemsForSale() public view returns (Item[] memory) {
        return market;
    }

}
