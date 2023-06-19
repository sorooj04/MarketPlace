// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;
import "hardhat/console.sol";

interface IERC4907 {
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
    event UpdateUser(
        uint256 indexed tokenId,
        address indexed user,
        uint64 expires
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

    function setUser(
        uint256 tokenId,
        address user,
        uint64 expires
    ) external;

    function userOf(uint256 tokenId) external view returns (address);

    function userExpires(uint256 tokenId) external view returns (uint256);

    function _mint(address to, uint id) external;

    function _burn(uint id) external;
}

contract ERC4907 is IERC4907 {
    struct Lessee {
        address user;
        uint expires;
    }

    mapping(address => uint) public _balanceOf;
    mapping(uint => address) public _ownerOf;
    mapping(uint => address) public _approved;
    mapping(address => mapping(address => bool)) public _isApprovedForAll;

    mapping(uint256 => Lessee) internal lessees;

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

        require(
            block.timestamp > lessees[_tokenId].expires,
            "NFT Rented cannot transfer"
        );

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
}

contract NFTMarketPlace {
    struct Item {
        address seller;
        address tokenContract;
        uint tokenId;
        uint price;
        bool status;
    }
    mapping(uint => Item) public market;
    address payable public owner;
    uint public itemId;
    uint public listingfee;

    constructor() {
        owner = payable(msg.sender);
        itemId = 0;
        listingfee = 1 wei;
    }

    event NFTListed(
        address sender,
        address _tokenContract,
        uint _tokenId,
        uint _price,
        uint itemId
    );

    function listNFT(
        address _tokenContract,
        uint _tokenId,
        uint _price
    ) external payable returns (uint) {
        address tokenOwner = IERC4907(_tokenContract).ownerOf(_tokenId);

        require(
            tokenOwner == msg.sender ||
                IERC4907(_tokenContract).isApprovedForAll(
                    tokenOwner,
                    msg.sender
                ),
            "Youre not owner"
        );
        require(
            IERC4907(_tokenContract).getApproved(_tokenId) == address(this),
            "Approve this contract first"
        );
        require(msg.value >= listingfee, "Not Enough Listing Fee");

        Item memory item = Item({
            seller: msg.sender,
            tokenContract: _tokenContract,
            tokenId: _tokenId,
            price: _price,
            status: true
        });

        // IERC4907(_tokenContract).approve(address(this), _tokenId);

        market[itemId] = item;

        emit NFTListed(msg.sender, _tokenContract, _tokenId, _price, itemId);
        uint currentId = itemId;
        ++itemId;
        return currentId;
    }

    function buyNFT(uint _itemId) external payable {
        require(
            msg.value >= market[_itemId].price,
            "Insufficient balance Transfered!"
        );
        require(market[_itemId].status, "Already sold");
        IERC4907(market[_itemId].tokenContract).transferFrom(
            market[_itemId].seller,
            msg.sender,
            market[_itemId].tokenId
        );

        market[_itemId].status = false;
        (bool success, ) = market[_itemId].seller.call{value: msg.value}("");
        require(success, "Failed to send funds to the seller");

        delete market[_itemId];
    }

    function deleteNFT(uint _itemId) public {
        require(msg.sender == market[_itemId].seller, "not auhorized");
        delete market[_itemId];
    }

    function updateNFT(uint _itemId) public {
        require(
            msg.sender == market[_itemId].seller || msg.sender == owner,
            "not auhorized"
        );
        market[_itemId].status = false;
    }

    function withraw() public {
        require(msg.sender == owner, "Only Owner");
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Failed to send funds to the Owner");
    }
}
