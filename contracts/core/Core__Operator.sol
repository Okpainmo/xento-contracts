// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../Base__Operator.sol";
import "../interfaces/IAdminManagement__Core.sol";

contract Core__Operator is Base__Operator {
    error OperatorCore__ZeroAddressError();
    error OperatorCore__AccessDenied_AdminOnly();
    error OperatorCore__NonMatchingAdminAddress();
    error OperatorCore__ZeroTokenDecimalsError();

    event Logs(string message, uint256 timestamp, string indexed contractName);

    string private constant CONTRACT_NAME = "Core__Operator";
    address private immutable i_owner;

    function _verifyIsAddress(address _address) internal pure override  {
        if (_address == address(0)) {
            revert OperatorCore__ZeroAddressError();
        }
    }

    constructor(address _adminManagementCoreContractAddress) {
        _verifyIsAddress(_adminManagementCoreContractAddress);

        s_adminManagementCoreContractAddress = _adminManagementCoreContractAddress;
        s_adminManagementContract__Base = IAdminManagement__Base(s_adminManagementCoreContractAddress);

        i_owner = msg.sender;

        emit Logs(
            "contract deployed successfully with constructor chores completed",
            block.timestamp,
            CONTRACT_NAME
        );
    }

    function getContractName() public pure returns (string memory) {
        return CONTRACT_NAME;
    }

    function getContractOwner() public view returns (address) {
        return i_owner;
    }

    function updateAdminManagementCoreContractAddress(address _newAddress) public {
        if (!s_adminManagementContract__Base.checkIsAdmin(msg.sender)) {
            revert OperatorCore__AccessDenied_AdminOnly();
        }

        if (_newAddress == address(0)) {
            revert OperatorCore__ZeroAddressError();
        }

        IAdminManagement__Core s_adminManagementContractToVerify = IAdminManagement__Core(_newAddress);
        ( , address contractAddress, ) = s_adminManagementContractToVerify.ping();

        if (contractAddress != _newAddress) {
            revert OperatorCore__NonMatchingAdminAddress();
        }

        if (!s_adminManagementContractToVerify.checkIsAdmin(msg.sender)) {
            revert OperatorCore__AccessDenied_AdminOnly();
        }

        s_adminManagementCoreContractAddress = _newAddress;
        s_adminManagementContract__Base = IAdminManagement__Base(s_adminManagementCoreContractAddress);
    }

    function updateERC20TokenData(address _tokenAddress, uint256 _tokenDecimals) public {
        if (
            !s_adminManagementContract__Base.checkIsAdmin(msg.sender)
        ) {
            revert OperatorCore__AccessDenied_AdminOnly();
        }

        if (_tokenAddress == address(0)) {
            revert OperatorCore__ZeroAddressError();
        }

        if (_tokenDecimals < 1) {
            revert OperatorCore__ZeroTokenDecimalsError();
        }

        s_ERC20TokenAddress  = _tokenAddress;
        s_tokenDecimals = _tokenDecimals;
        s_ERC20Contract = IERC20(s_ERC20TokenAddress);
    }

    function getERC20TokenAddress() public view returns (address) {
        return s_ERC20TokenAddress;
    }

    function getERC20TokenDecimals() public view returns (uint256) {
        return s_tokenDecimals;
    }

    function getAdminManagementCoreContractAddress() public view returns (address) {
        return s_adminManagementCoreContractAddress;
    }

    function ping() external view returns (string memory, address, uint256) {
        return (CONTRACT_NAME, address(this), block.timestamp);
    }
}
