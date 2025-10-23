// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title XNT
 * @dev A standard ERC20 token with mint and burn capability, 
 * fully compliant with the ERC20 standard.
 */
contract XNT is ERC20, Ownable {
    uint8 private _customDecimals;

    /**
     * @dev Sets the token name, symbol, and decimals during deployment.
     * @param name_ The name of the token (e.g., "Lola USD").
     * @param symbol_ The symbol of the token (e.g., "LUSD").
     * @param decimals_ Number of decimal places (e.g., 18 for most ERC-20 tokens).
     * @param initialSupply_ The initial supply (in whole tokens, before applying decimals).
     * @param owner_ Address that will receive the initial supply and be set as the owner.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialSupply_,
        address owner_
    ) ERC20(name_, symbol_) Ownable(owner_) {
        _customDecimals = decimals_;
        _mint(owner_, initialSupply_ * (10 ** decimals_));
    }

    /**
     * @dev Returns the number of decimals used by the token.
     */
    function decimals() public view virtual override returns (uint8) {
        return _customDecimals;
    }

    /**
     * @dev Mint new tokens to a given address.
     * Can only be called by the owner (e.g., admin or treasury contract).
     * @param to Recipient address.
     * @param amount Number of tokens to mint (raw units, not adjusted for decimals).
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev Burn tokens from a given address.
     * Can only be called by the owner (admin burn).
     * @param from Address from which tokens will be burned.
     * @param amount Number of tokens to burn (raw units, not adjusted for decimals).
     */
    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}
