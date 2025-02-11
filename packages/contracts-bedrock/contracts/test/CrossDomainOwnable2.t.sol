// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Bytes32AddressLib } from "@rari-capital/solmate/src/utils/Bytes32AddressLib.sol";
import { CommonTest, Messenger_Initializer } from "./CommonTest.t.sol";
import { CrossDomainOwnable2 } from "../L2/CrossDomainOwnable2.sol";
import { AddressAliasHelper } from "../vendor/AddressAliasHelper.sol";
import { Hashing } from "../libraries/Hashing.sol";
import { Encoding } from "../libraries/Encoding.sol";

contract XDomainSetter2 is CrossDomainOwnable2 {
    uint256 public value;

    function set(uint256 _value) external onlyOwner {
        value = _value;
    }
}

contract CrossDomainOwnable2_Test is Messenger_Initializer {
    XDomainSetter2 setter;

    function setUp() public override {
        super.setUp();
        vm.prank(alice);
        setter = new XDomainSetter2();
    }

    function test_onlyOwner_notMessenger_reverts() external {
        vm.expectRevert("CrossDomainOwnable2: caller is not the messenger");
        setter.set(1);
    }

    function test_onlyOwner_notOwner_reverts() external {
        // set the xDomainMsgSender storage slot
        bytes32 key = bytes32(uint256(204));
        bytes32 value = Bytes32AddressLib.fillLast12Bytes(address(alice));
        vm.store(address(L2Messenger), key, value);

        vm.prank(address(L2Messenger));
        vm.expectRevert("CrossDomainOwnable2: caller is not the owner");
        setter.set(1);
    }

    function test_onlyOwner_notOwner2_reverts() external {
        uint240 nonce = 0;
        address sender = bob;
        address target = address(setter);
        uint256 mntValue = 0;
        uint256 ethValue = 0;
        uint256 minGasLimit = 0;
        bytes memory message = abi.encodeWithSelector(XDomainSetter2.set.selector, 1);

        bytes32 hash = Hashing.hashCrossDomainMessage(
            Encoding.encodeVersionedNonce(nonce, 1),
            sender,
            target,
            mntValue,
            ethValue,
            minGasLimit,
            message
        );

        // It should be a failed message. The revert is caught,
        // so we cannot expectRevert here.
        vm.expectEmit(true, true, true, true);
        emit FailedRelayedMessage(hash);

        vm.prank(AddressAliasHelper.applyL1ToL2Alias(address(L1Messenger)));
        L2Messenger.relayMessage(
            Encoding.encodeVersionedNonce(nonce, 1),
            sender,
            target,
            mntValue,
            ethValue,
            minGasLimit,
            message
        );

        assertEq(setter.value(), 0);
    }

    function test_onlyOwner_succeeds() external {
        address owner = setter.owner();

        // Simulate the L2 execution where the call is coming from
        // the L1CrossDomainMessenger
        vm.prank(AddressAliasHelper.applyL1ToL2Alias(address(L1Messenger)));
        L2Messenger.relayMessage(
            Encoding.encodeVersionedNonce(1, 1),
            owner,
            address(setter),
            0,
            0,
            0,
            abi.encodeWithSelector(XDomainSetter2.set.selector, 2)
        );

        assertEq(setter.value(), 2);
    }
}
