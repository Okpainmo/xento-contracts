// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IAdminManagement__Base.sol";
import "./interfaces/IERC20.sol";

contract Base__Operator {
    // -----------------
    // Custom Errors
    // -----------------
    error Operator__ZeroAddressError();
    error Operator__AccessDenied_AdminOnly();
    
    event TransferProcessed(
        address indexed sender,
        address indexed receiver,
        string indexed tokenType,
        uint256 totalAmount,
        uint256 commision,
        uint256 amountSent,
        uint256 sendTime
    );

    // -----------------
    // State variables
    // -----------------
    address internal s_adminManagementCoreContractAddress;
    address internal s_ERC20TokenAddress;
    uint256 internal s_tokenDecimals;

    IAdminManagement__Base internal s_adminManagementContract__Base =
        IAdminManagement__Base(s_adminManagementCoreContractAddress);

    IERC20 internal s_ERC20Contract =
        IERC20(s_ERC20TokenAddress);

    // -----------------
    // Internal helpers
    // -----------------
    function _verifyIsAddress(address _address) internal pure virtual {
        if (_address == address(0)) {
            revert Operator__ZeroAddressError();
        }
    }

    function _verifyIsAdmin(
        address _address
    ) internal view virtual {
        if (
            !s_adminManagementContract__Base.checkIsAdmin(_address)
        ) {
            revert Operator__AccessDenied_AdminOnly();
        }
    }

    // call directly on UI - via user wallet to get user approval
    function handleApproveERC20Transfer(
        uint256 _amount
        // address _orchestratorContractAddress
    ) public {
        require(
            IERC20(s_ERC20TokenAddress).approve(
                address(this),
                _amount
            ),
            "ERC20 approve failed"
        );
    }

    function handleTransfer__ERC20(
        address _createdBy,
        uint256 _totalAmount,
        address _receiverAddress
    ) public {
        _verifyIsAdmin(address(this));

        // Calculate platform commission (2%) and merchant payout (98%)
        uint256 platformCommission = (_totalAmount * 2) / 100;
        uint256 amountToSend = _totalAmount - platformCommission;

        // Transfer 2% to platform commission wallet
        require(
            s_ERC20Contract.transferFrom(
                _createdBy,
                address(this),
                platformCommission * 10 ** s_tokenDecimals // process WEI value
            ),
            "Commission transfer failed"
        );

        // Transfer 98% to receiver address
        require(
            s_ERC20Contract.transferFrom(
                _createdBy,
                _receiverAddress,
                amountToSend * 10 ** s_tokenDecimals // process WEI value
            ),
            "Transfer to user failed"
        );

        emit TransferProcessed(
            _createdBy,
            _receiverAddress,
            "ERC20",
            _totalAmount, // return prettified value
            platformCommission, // return prettified value
            amountToSend, // return prettified value
            block.timestamp
        );
    }

    function sendEther__PassThrough(address payable _receiverAddress) public payable {
        require(msg.value > 0, "Transfer amount must be greater than zero");

        (bool transferIsSuccessful, ) = _receiverAddress.call{value: msg.value}("");
        require(transferIsSuccessful, "The transaction was unsuccessful");


        emit TransferProcessed(
            msg.sender,
            _receiverAddress,
            "ERC20",
            msg.value,
            0,
            msg.value,
            block.timestamp
        );

    }
}
