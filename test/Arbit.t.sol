// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "forge-std/Test.sol";

import {Arbit} from "src/Arbit.sol";

contract ArbitTest is Test {
    using stdStorage for StdStorage;

    Arbit arbit;

    // event CaseOpened(uint256 caseId);

    // event GMEverybodyGM();

    function setUp() external {
        arbit = new Arbit();
        uint256 a = arbit.openCase(address(0x0), address(0x1));
        // vm.expectEmit("0", address(0x0), address(0x0), address(0x0));
        // emit CaseOpened();
    }

    // VM Cheatcodes can be found in ./lib/forge-std/src/Vm.sol
    // Or at https://github.com/foundry-rs/forge-std
    // function testSetGm() external {
    //     // slither-disable-next-line reentrancy-events,reentrancy-benign
    //     greeter.setGreeting("gm gm");

    //     // Expect the GMEverybodyGM event to be fired
    //     vm.expectEmit(true, true, true, true);
    //     emit GMEverybodyGM();
    //     // slither-disable-next-line unused-return
    //     greeter.gm("gm gm");

    //     // Expect the gm() call to revert
    //     vm.expectRevert(abi.encodeWithSignature("BadGm()"));
    //     // slither-disable-next-line unused-return
    //     greeter.gm("gm");

    //     // We can read slots directly
    //     uint256 slot = stdstore
    //         .target(address(greeter))
    //         .sig(greeter.owner.selector)
    //         .find();
    //     assertEq(slot, 1);
    //     bytes32 owner = vm.load(address(greeter), bytes32(slot));
    //     assertEq(address(this), address(uint160(uint256(owner))));
    // }
}
