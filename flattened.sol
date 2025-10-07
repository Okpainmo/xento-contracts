// Sources flattened with hardhat v2.26.1 https://hardhat.org

// SPDX-License-Identifier: MIT

// File contracts/interfaces/IAdminManagement__Base.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.20;

interface IAdminManagement__Base {
    // ------------------------
    // Errors
    // ------------------------
    error AdminManagement__ZeroAddressError();
    error AdminManagement__AlreadyAddedAsAdmin(Admin admin);
    error AdminManagement__AddressIsNotAnAdmin();

    // ------------------------
    // Structs
    // ------------------------
    struct Admin {
        address adminAddress;
        address addedBy;
        uint256 addedAt;
    }

    // ------------------------
    // Events
    // ------------------------
    event AddedNewAdmin(
        string message,
        uint256 timestamp,
        string indexed contractName,
        address indexed addedAdminAddress,
        address indexed addedBy
    );

    event RemovedAdmin(
        string message,
        uint256 timestamp,
        string indexed contractName,
        address indexed removedAdminAddress,
        address indexed removedBy
    );

    // ------------------------
    // Functions
    // ------------------------
    function addAdmin(address _address) external;

    function removeAdmin(address _address) external;

    function getPlatformAdmins() external view returns (Admin[] memory);

    function getAdminAdminRegistrations(
        address _adminAddress
    ) external view returns (Admin[] memory);

    function checkIsAdmin(address _adminAddress) external view returns (bool);

    function getAdminProfile(
        address _adminAddress
    ) external view returns (Admin memory);
}

// File contracts/interfaces/IERC20.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    // =========================
    //          Errors
    // =========================
    error LolaUSD__InsufficientBalance();
    error LolaUSD__OperatorAddressIsZeroAddress();
    error LolaUSD__OwnerAddressIsZeroAddress();
    error LolaUSD__ReceiverAddressIsZeroAddress();
    error LolaUSD__TransferOperationWasUnsuccessful();
    error LolaUSD__ExcessSpendRequestOrUnauthorized();
    error LolaUSD__ExcessAllowanceDecrement();
    error LolaUSD__UnsuccessfulTransferFromOperation();
    error LolaUSD__ZeroAddressError();
    error LolaUSD__AccessDenied_AdminOnly();
    error LolaUSD__ProposalAlreadyExecuted();
    error LolaUSD__InvalidProposalCodeName();

    // =========================
    //          Events
    // =========================
    event Transfer(
        address indexed _owner,
        address indexed _receiver,
        uint256 _value
    );
    event Approval(
        address indexed _owner,
        address indexed _operator,
        uint256 _value
    );

    // =========================
    //      View Functions
    // =========================
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);

    function allowance(
        address _owner,
        address _operator
    ) external view returns (uint256);

    // =========================
    //   ERC20-like Functions
    // =========================
    function approve(address _operator, uint256 _value) external returns (bool);

    function increaseAllowance(
        address _operator,
        uint256 _amountToAdd
    ) external returns (bool);

    function decreaseAllowance(
        address _operator,
        uint256 _amountToDeduct
    ) external returns (bool);

    function transfer(
        address _receiver,
        uint256 _value
    ) external returns (bool);

    function transferFrom(
        address _owner,
        address _receiver,
        uint256 _value
    ) external returns (bool);

    // =========================
    //   Admin (Mint/Burn)
    // =========================
    function mint(
        address _to,
        uint256 _amount,
        uint256 _proposalId,
        string memory _proposalCodeName
    ) external;

    function burn(
        address _from,
        uint256 _amount,
        uint256 _proposalId,
        string memory _proposalCodeName
    ) external;
}

// File contracts/Base__Operator.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.20;

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

    IERC20 internal s_ERC20Contract = IERC20(s_ERC20TokenAddress);

    // -----------------
    // Internal helpers
    // -----------------
    function _verifyIsAddress(address _address) internal pure virtual {
        if (_address == address(0)) {
            revert Operator__ZeroAddressError();
        }
    }

    function _verifyIsAdmin(address _address) internal view virtual {
        if (!s_adminManagementContract__Base.checkIsAdmin(_address)) {
            revert Operator__AccessDenied_AdminOnly();
        }
    }

    // call directly on UI - via user wallet to get user approval
    function handleApproveERC20Transfer(
        uint256 _amount
    ) public // address _orchestratorContractAddress
    {
        require(
            IERC20(s_ERC20TokenAddress).approve(address(this), _amount),
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

    function sendEther__PassThrough(
        address payable _receiverAddress
    ) public payable {
        require(msg.value > 0, "Transfer amount must be greater than zero");

        (bool transferIsSuccessful, ) = _receiverAddress.call{value: msg.value}(
            ""
        );
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

// File contracts/interfaces/IAdminManagement__Core.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.20;

interface IAdminManagement__Core {
    // ---- Core Admin Checks ----
    function checkIsAdmin(address account) external view returns (bool);

    // ---- Metadata / Utilities ----
    function getContractName() external pure returns (string memory);

    function getContractOwner() external view returns (address);

    function ping() external view returns (string memory, address, uint256);
}

// File contracts/core/Core__Operator.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.20;

contract Core__Operator is Base__Operator {
    error OperatorCore__ZeroAddressError();
    error OperatorCore__AccessDenied_AdminOnly();
    error OperatorCore__NonMatchingAdminAddress();
    error OperatorCore__ZeroTokenDecimalsError();

    event Logs(string message, uint256 timestamp, string indexed contractName);

    string private constant CONTRACT_NAME = "Core__Operator";
    address private immutable i_owner;

    function _verifyIsAddress(address _address) internal pure override {
        if (_address == address(0)) {
            revert OperatorCore__ZeroAddressError();
        }
    }

    constructor(address _adminManagementCoreContractAddress) {
        _verifyIsAddress(_adminManagementCoreContractAddress);

        s_adminManagementCoreContractAddress = _adminManagementCoreContractAddress;
        s_adminManagementContract__Base = IAdminManagement__Base(
            s_adminManagementCoreContractAddress
        );

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

    function updateAdminManagementCoreContractAddress(
        address _newAddress
    ) public {
        if (!s_adminManagementContract__Base.checkIsAdmin(msg.sender)) {
            revert OperatorCore__AccessDenied_AdminOnly();
        }

        if (_newAddress == address(0)) {
            revert OperatorCore__ZeroAddressError();
        }

        IAdminManagement__Core s_adminManagementContractToVerify = IAdminManagement__Core(
                _newAddress
            );
        (, address contractAddress, ) = s_adminManagementContractToVerify
            .ping();

        if (contractAddress != _newAddress) {
            revert OperatorCore__NonMatchingAdminAddress();
        }

        if (!s_adminManagementContractToVerify.checkIsAdmin(msg.sender)) {
            revert OperatorCore__AccessDenied_AdminOnly();
        }

        s_adminManagementCoreContractAddress = _newAddress;
        s_adminManagementContract__Base = IAdminManagement__Base(
            s_adminManagementCoreContractAddress
        );
    }

    function updateERC20TokenData(
        address _tokenAddress,
        uint256 _tokenDecimals
    ) public {
        if (!s_adminManagementContract__Base.checkIsAdmin(msg.sender)) {
            revert OperatorCore__AccessDenied_AdminOnly();
        }

        if (_tokenAddress == address(0)) {
            revert OperatorCore__ZeroAddressError();
        }

        if (_tokenDecimals < 1) {
            revert OperatorCore__ZeroTokenDecimalsError();
        }

        s_ERC20TokenAddress = _tokenAddress;
        s_tokenDecimals = _tokenDecimals;
        s_ERC20Contract = IERC20(s_ERC20TokenAddress);
    }

    function getERC20TokenAddress() public view returns (address) {
        return s_ERC20TokenAddress;
    }

    function getERC20TokenDecimals() public view returns (uint256) {
        return s_tokenDecimals;
    }

    function getAdminManagementCoreContractAddress()
        public
        view
        returns (address)
    {
        return s_adminManagementCoreContractAddress;
    }

    function ping() external view returns (string memory, address, uint256) {
        return (CONTRACT_NAME, address(this), block.timestamp);
    }
}
