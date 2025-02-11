// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { CommonTest } from "./CommonTest.t.sol";
import { Types } from "../libraries/Types.sol";
import { Hashing } from "../libraries/Hashing.sol";
import { Encoding } from "../libraries/Encoding.sol";
import { LegacyCrossDomainUtils } from "../libraries/LegacyCrossDomainUtils.sol";
import { console } from "forge-std/console.sol";

contract Hashing_hashDepositSource_Test is CommonTest {
    /**
     * @notice Tests that hashDepositSource returns the correct hash in a simple case.
     */
    function test_hashDepositSource_succeeds() external {
        assertEq(
            Hashing.hashDepositSource(
                0xd25df7858efc1778118fb133ac561b138845361626dfb976699c5287ed0f4959,
                0x1
            ),
            0xf923fb07134d7d287cb52c770cc619e17e82606c21a875c92f4c63b65280a5cc
        );
    }
}

contract Hashing_hashCrossDomainMessage_Test is CommonTest {
    /**
     * @notice Tests that hashCrossDomainMessage returns the correct hash in a simple case.
     */
    function testDiff_hashCrossDomainMessage_succeeds(
        uint240 _nonce,
        uint16 _version,
        address _sender,
        address _target,
        uint256 _mntValue,
        uint256 _ethValue,
        uint256 _gasLimit,
        bytes memory _data
    ) external {
        // Ensure the version is valid.
        uint16 version = uint16(bound(uint256(_version), 0, 1));
        uint256 nonce = Encoding.encodeVersionedNonce(_nonce, version);
        assertEq(
            Hashing.hashCrossDomainMessage(nonce, _sender, _target, _mntValue, _ethValue, _gasLimit, _data),
            ffi.hashCrossDomainMessage(nonce, _sender, _target, _mntValue, _ethValue, _gasLimit, _data)
        );
    }

    /**
     * @notice Tests that hashCrossDomainMessageV0 matches the hash of the legacy encoding.
     */
    function testFuzz_hashCrossDomainMessageV0_matchesLegacy_succeeds(
        address _target,
        address _sender,
        bytes memory _message,
        uint256 _messageNonce
    ) external {
        assertEq(
            keccak256(
                LegacyCrossDomainUtils.encodeXDomainCalldata(
                    _target,
                    _sender,
                    _message,
                    _messageNonce
                )
            ),
            Hashing.hashCrossDomainMessageV0(_target, _sender, _message, _messageNonce)
        );
    }
}

contract Hashing_hashWithdrawal_Test is CommonTest {
    /**
     * @notice Tests that hashWithdrawal returns the correct hash in a simple case.
     */
    function testDiff_hashWithdrawal_succeeds(
        uint256 _nonce,
        address _sender,
        address _target,
        uint256 _mntValue,
        uint256 _ethValue,
        uint256 _gasLimit,
        bytes memory _data
    ) external {
        assertEq(
            Hashing.hashWithdrawal(
                Types.WithdrawalTransaction(_nonce, _sender, _target, _mntValue, _ethValue, _gasLimit, _data)
            ),
            ffi.hashWithdrawal(_nonce, _sender, _target, _mntValue, _ethValue, _gasLimit, _data)
        );
    }
}

contract Hashing_hashOutputRootProof_Test is CommonTest {
    /**
     * @notice Tests that hashOutputRootProof returns the correct hash in a simple case.
     */
    function testDiff_hashOutputRootProof_succeeds(
        bytes32 _version,
        bytes32 _stateRoot,
        bytes32 _messagePasserStorageRoot,
        bytes32 _latestBlockhash
    ) external {
        assertEq(
            Hashing.hashOutputRootProof(
                Types.OutputRootProof({
                    version: _version,
                    stateRoot: _stateRoot,
                    messagePasserStorageRoot: _messagePasserStorageRoot,
                    latestBlockhash: _latestBlockhash
                })
            ),
            ffi.hashOutputRootProof(
                _version,
                _stateRoot,
                _messagePasserStorageRoot,
                _latestBlockhash
            )
        );
    }
}

contract Hashing_hashDepositTransaction_Test is CommonTest {
    /**
     * @notice Tests that hashDepositTransaction returns the correct hash in a simple case.
     */
    function testDiff_hashDepositTransaction_succeeds(
        address _from,
        address _to,
        uint256 _mint,
        uint256 _mntValue,
        uint256 _ethValue,
        uint64 _gas,
        bytes memory _data,
        uint64 _logIndex
    ) external {
        assertEq(
            Hashing.hashDepositTransaction(
                Types.UserDepositTransaction(
                    _from,
                    _to,
                    false, // isCreate
                    _mntValue,
                    _mint,
                    _ethValue,
                    _gas,
                    _data,
                    bytes32(uint256(0)),
                    _logIndex
                )
            ),
            ffi.hashDepositTransaction(_from, _to, _mint, _mntValue, _ethValue, _gas, _data, _logIndex)
        );
    }
}
