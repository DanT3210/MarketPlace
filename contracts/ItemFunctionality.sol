// SPDX-License-Identifier:MIT

pragma solidity ^0.8.15;
//@Title: Online Trade Marker (blockchain eBay)
//@author: Dant3210
//@notice: Functions Contract
//@dev: Contract under development (work in progress )
//@version: remix

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ItemFunctionality is Ownable, ReentrancyGuard{ 


    event TransferSingle(address operator, address from,address to,uint256 id,uint256 amount);
    event TransferBatch(address operator, address from, address to,uint256[] ids,uint256[] amounts);
    event ApprovalForAll(address owner, address operator, bool approved);

    // Mapping from token ID to account quantity
    mapping(uint256 => mapping(address => uint256)) private _itemQTY;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    constructor() {
    }

   
    function uri(uint256) public view virtual returns (string memory) {
        return _uri;
    }

    function item_qty(address account, uint256 id) public view virtual returns (uint256) {
        require(account != address(0), "ERROR: address zero is not a valid owner");
        return _itemQTY[id][account];
    }

    function item_qtyOfBatch(address[] memory accounts, uint256[] memory ids)public view virtual returns (uint256[] memory){
        require(accounts.length == ids.length, "ERROR: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = item_qty(accounts[i], ids[i]);
        }

        return batchBalances;
    }


    function setApprovalForAll(address operator, bool approved) internal virtual {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address account, address operator) internal view virtual returns (bool) {
        return _operatorApprovals[account][operator];
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount) internal virtual {
        require(from == _msgSender() || isApprovedForAll(from, _msgSender()),"ERROR: caller is not token owner or approved");
        _safeTransferFrom(from, to, id, amount);
    }

    function safeBatchTransferFrom(address from, address to,uint256[] memory ids, uint256[] memory amounts) internal virtual{
        require(from == _msgSender() || isApprovedForAll(from, _msgSender()), "ERROR: caller is not token owner or approved");
        _safeBatchTransferFrom(from, to, ids, amounts);
    }

    function _safeTransferFrom(address from, address to, uint256 id, uint256 amount) internal virtual {
        require(to != address(0), "ERROR: transfer to the zero address");

        address operator = _msgSender();
        //uint256[] memory ids = _asSingletonArray(id);
        //uint256[] memory amounts = _asSingletonArray(amount);

        uint256 fromBalance = _itemQTY[id][from];
        require(fromBalance >= amount, "ERROR: insufficient balance for transfer");
        unchecked {
            _itemQTY[id][from] = fromBalance - amount;
        }
        _itemQTY[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);
    }

    function _safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(ids.length == amounts.length, "ERROR: ids and amounts length mismatch");
        require(to != address(0), "ERROR: transfer to the zero address");

        address operator = _msgSender();

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _itemQTY[id][from];
            require(fromBalance >= amount, "ERROR: insufficient QTY for transfer");
            unchecked {
                _itemQTY[id][from] = fromBalance - amount;
            }
            _itemQTY[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);
    }

    function _setURI(string memory newuri) internal virtual onlyOwner{
        _uri = newuri;
    }

    //PUBLISH SINGLE ITEM//
    function _mint(address to, uint256 id, uint256 amount) internal virtual {
        require(to != address(0), "ERROR: mint to the zero address");

        address operator = _msgSender();
        //uint256[] memory ids = _asSingletonArray(id);
        //uint256[] memory amounts = _asSingletonArray(amount);

        _itemQTY[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);
    }

    //PUBLIS BATCH ITEMS//
    function _mintBatch( address to,uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(to != address(0), "ERROR: mint to the zero address");
        require(ids.length == amounts.length, "ERROR: ids and amounts length mismatch");

        address operator = _msgSender();

        for (uint256 i = 0; i < ids.length; i++) {
            _itemQTY[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);
    }

    //REMOVED SINGLE ITEM//
    function _burn(address from, uint256 id, uint256 amount) internal virtual {
        require(from != address(0), "ERROR: burn from the zero address");

        address operator = _msgSender();
        //uint256[] memory ids = _asSingletonArray(id);
        //uint256[] memory amounts = _asSingletonArray(amount);

        uint256 fromBalance = _itemQTY[id][from];
        require(fromBalance >= amount, "ERROR: burn amount exceeds balance");
        unchecked {
            _itemQTY[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    //REMOVE BATCH ITEMS//
    function _burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(from != address(0), "ERROR: burn from the zero address");
        require(ids.length == amounts.length, "ERROR: ids and amounts length mismatch");

        address operator = _msgSender();

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _itemQTY[id][from];
            require(fromBalance >= amount, "ERROR: burn amount exceeds balance");
            unchecked {
                _itemQTY[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERROR: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }    
}