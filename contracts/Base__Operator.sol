// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IAdminManagement__Base.sol";
import "./interfaces/IERC20.sol";
import "./auth/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./lib/ETHUSDConverter.sol";
import "./lib/XNTUSDConverter.sol";

using Strings for address;
// using UniEthConverter for uint256;
using XNTUSDConverter for uint256;

contract Base__Operator is ReentrancyGuard {
    // -----------------
    // Custom Errors
    // -----------------
    error Operator__ZeroAddressError();
    error Operator__AccessDenied_AdminOnly();
    error Operator__ZeroAmountError();
    error Operator__InsufficientBalance();

    event TransferProcessed(
        address indexed sender,
        address indexed receiver,
        string indexed tokenType,
        uint256 totalAmount,
        uint256 commision,
        uint256 reward,
        uint256 amountSent,
        uint256 sendTime
    );

    // -----------------
    // State variables
    // -----------------
    address internal s_adminManagementCoreContractAddress;
    address internal s_ERC20TokenAddress;
    address internal s_XNTTokenAddress;
    uint256 internal s_tokenDecimals;
    address internal s_treasuryWalletAddress;

    struct Transaction {
        address sender;
        address receiver;
        string tokenType;
        uint256 totalAmount;
        uint256 commission;
        uint256 reward;
        uint256 amountSent;
        uint256 sendTime;
    }

    Transaction[] internal s_transactions;
    mapping(address => Transaction[]) internal s_userTransactions;

    IAdminManagement__Base internal s_adminManagementContract__Base;

    // BPS => Basis Points
    uint256 constant COMMISSION_BPS = 30; // 0.3%
    uint256 constant YIELD_BPS = 10; // 0.1%
    uint256 constant BPS_DENOMINATOR = 10000; // 100%

    IERC20 internal s_ERC20Contract;

    IERC20 internal s_XNTContract;

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

    function calculateRewards(uint256 _rewardBase) internal view returns (uint256 rewardInXNT__raw, uint256 rewardInXNT__pretty) {
        // _rewardBase is in USD, and should be scaled to 1e18
        (uint256 XNTAmount__raw, uint256 XNTAmount__pretty) = XNTUSDConverter.USDToXNT(_rewardBase);

        // XNTAmount__raw is already in 1e18 units
        return (XNTAmount__raw, XNTAmount__pretty);
    }

    function transfer__ERC20(
        address _createdBy,
        uint256 _totalAmount,
        address _receiverAddress
    ) public noReentrant() returns(Transaction memory completedTransaction) {
        // scale total amount first
        uint256 totalAmount = _totalAmount * 10 ** s_tokenDecimals;

        // Calculate platform commission (2%) and merchant payout (98%)
        uint256 platformCommission = (totalAmount * COMMISSION_BPS) / BPS_DENOMINATOR;
        uint256 rewardBase = (totalAmount * YIELD_BPS) / BPS_DENOMINATOR;
        uint256 amountToSend = totalAmount - platformCommission;

        string memory stringifiedTokenAddress = s_ERC20TokenAddress.toHexString(); 

        (uint256 r, ) = calculateRewards(rewardBase);

        Transaction memory newTransaction = Transaction ({
            sender: _createdBy,
            receiver: _receiverAddress,
            tokenType: string.concat("ERC20: ", stringifiedTokenAddress),
            totalAmount: totalAmount, 
            commission: platformCommission, 
            reward: r,  
            amountSent: amountToSend, 
            sendTime: block.timestamp
        });

        s_transactions.push(newTransaction);
        s_userTransactions[_createdBy].push(newTransaction);

        // todos: scale ERC20 transfers - reward is already scaled

        // Transfer everything(totalAmount) to contract
        require(
            s_ERC20Contract.transferFrom(
                _createdBy,
                address(this),
                totalAmount
            ),
            "Operator funding failed"
        );

        // Transfer 2% to treasury address
        require(
            s_ERC20Contract.transfer(
                s_treasuryWalletAddress,
                platformCommission
            ),
            "Transfer to user failed"
        );
 
        // Transfer 98% to receiver address, so that contract(contract reserves the rest - 2%)
        require(
            s_ERC20Contract.transfer(
                _receiverAddress,
                amountToSend
            ),
            "Transfer to user failed"
        );

        // Transfer reward to sender address
        require(
            s_XNTContract.transfer(
                _createdBy,
                r // XNT in raw form is already scaled
            ),
            "Transfer to user failed"
        );

        emit TransferProcessed(
            _createdBy,
            _receiverAddress,
            string.concat("ERC20: ", stringifiedTokenAddress),
            totalAmount, 
            platformCommission, 
            r,
            amountToSend, 
            block.timestamp
        );

        return newTransaction;
    }

    function transfer__Eth(address _createdBy, address payable _receiverAddress) public payable noReentrant() returns(Transaction memory completedTransaction) { 
        // Calculate platform commission (2%) and merchant payout (98%)
        uint256 platformCommission = (msg.value * COMMISSION_BPS) / BPS_DENOMINATOR;
        uint256 amountToSend = msg.value - platformCommission;
        uint256 rewardBase = (msg.value * YIELD_BPS) / BPS_DENOMINATOR; // already scaled in this case

        (uint256 ETHAmountInUSD /* already scaled */, ) = ETHUSDConverter.ETHToUSD(rewardBase);
        (uint256 r, ) = calculateRewards(ETHAmountInUSD);

         Transaction memory newTransaction = Transaction ({
            sender: _createdBy,
            receiver: _receiverAddress,
            tokenType: "Eth",
            totalAmount: msg.value, 
            commission: platformCommission, 
            reward: r,
            amountSent: amountToSend, 
            sendTime: block.timestamp
        });

        s_transactions.push(newTransaction);
        s_userTransactions[_createdBy].push(newTransaction);

        (bool transferToUserIsSuccessful, ) = _receiverAddress.call{value: amountToSend}("");
        require(transferToUserIsSuccessful, "transfer to user was unsuccessful");

        (bool commitionTransferIsSuccessful, ) = s_treasuryWalletAddress.call{value: platformCommission}("");
        require(commitionTransferIsSuccessful, "commision transfer was unsuccessful");

        // Transfer reward to sender address
        require(
            s_XNTContract.transfer(
                _createdBy,
                r // XNT in raw form is already scaled
            ),
            "Transfer to user failed"
        );

        emit TransferProcessed(
            msg.sender, 
            _receiverAddress,
            "Eth",
            msg.value, 
            platformCommission, 
            r,
            amountToSend, 
            block.timestamp
        );

        return newTransaction;
    }

    function withdrawXNTTokens(uint256 _amountToWithdraw, address _receiverAddress) public noReentrant() returns(Transaction memory completedTransaction){ 
        _verifyIsAdmin(msg.sender);  

        _verifyIsAddress(_receiverAddress);

        if(_amountToWithdraw == 0) {
            revert Operator__ZeroAmountError();
        }

        uint256 scaledAmountToWithdraw = _amountToWithdraw * 10 ** 18;

        uint256 contractBalance = s_XNTContract.balanceOf(address(this));

        if (contractBalance < scaledAmountToWithdraw) {
            revert Operator__InsufficientBalance();
        }

        string memory tokenType = string.concat("ERC20: ", s_XNTTokenAddress.toHexString());

        Transaction memory newTransaction = Transaction ({
            sender: address(this),
            receiver: _receiverAddress,
            tokenType: tokenType,
            totalAmount: scaledAmountToWithdraw, 
            commission: 0, 
            reward: 0,
            amountSent: scaledAmountToWithdraw, 
            sendTime: block.timestamp
        });

        require(
            s_XNTContract.transfer(
                _receiverAddress,
                scaledAmountToWithdraw // XNT in raw form is already scaled
            ),
            "Transfer to user failed"
        );

        s_transactions.push(newTransaction);
        s_userTransactions[address(this)].push(newTransaction);

        emit TransferProcessed(
            address(this), 
            _receiverAddress,
            tokenType,
            scaledAmountToWithdraw, 
            0, 
            0,
            scaledAmountToWithdraw, 
            block.timestamp
        );

        return newTransaction;
    }

    // ====================== VIEW FUNCTIONS ======================
    function getXNTPrice() public view returns (uint256 XNTPrice) {
        return XNTUSDConverter.getXNTPrice();
    }

    function getETHPrice() public view returns (uint256 ETHPrice) {
        return ETHUSDConverter.getETHPrice();
    }

    function getAllTransactions() external view returns (Transaction[] memory allTransactions) {
        return s_transactions;
    }

    function getUserTransactions(address user) external view returns (Transaction[] memory userTxs) {
        return s_userTransactions[user];
    }

    function getTotalTransactionCount() external view returns (uint256) {
        return s_transactions.length;
    }

    function getUserTransactionCount(address user) external view returns (uint256) {
        return s_userTransactions[user].length;
    }
}
