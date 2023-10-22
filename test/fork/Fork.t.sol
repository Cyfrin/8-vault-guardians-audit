// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {Base_Test} from "../Base.t.sol";

abstract contract Fork_Test is Base_Test {
    address constant AAVE_POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        // Fork Ethereum Mainnet at a specific block number.
        vm.createSelectFork({blockNumber: 18_377_723, urlOrAlias: "mainnet"});

        // The base is set up after the fork is selected so that the base test contracts are deployed on the fork.
        Base_Test.setUp();

        // labelContracts();
    }

    function testForkWorks() public {
        assertEq(block.chainid, 1);
    }

    function testForkGetsCorrectAddresses() public {
        assertEq(AAVE_POOL, vaultGuardians.getAavePool());
    }

    // // add this to be excluded from coverage report
    // function testA() public {}
}
