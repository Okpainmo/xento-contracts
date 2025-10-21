// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

contract ReentrancyGuard {

    error ReentrancyGuard__NoEntrance();
    bool internal locked;

    modifier noReentrant() {
        if (locked) {
            revert ReentrancyGuard__NoEntrance();
        }

        locked = true;

        _;

        locked= false;
    }
}
