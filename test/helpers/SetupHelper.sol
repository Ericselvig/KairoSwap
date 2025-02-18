// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {JITHook} from "../../src/JITHook.sol";
import {StrategiesController} from "../../src/StrategiesController.sol";
import {PositionManager} from "v4-periphery/src/PositionManager.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {IAllowanceTransfer} from "permit2/src/interfaces/IAllowanceTransfer.sol";
import {PositionDescriptor} from "v4-periphery/src/PositionDescriptor.sol";
import {IWETH9} from "v4-periphery/src/interfaces/external/IWETH9.sol";

contract SetupHelper is Test {
    function deployHook(
        IPoolManager manager,
        StrategiesController controller,
        uint256 threshold,
        PositionManager posm
    ) public returns (JITHook) {
        uint160 flags = uint160(Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG);
        address hookAddress = address(flags);
        deployCodeTo(
            "JITHook.sol", abi.encode(address(manager), address(controller), threshold, address(posm)), hookAddress
        );
        return JITHook(hookAddress);
    }

    function approveTokens(JITHook hook, Currency token0, Currency token1) public {
        MockERC20(Currency.unwrap(token0)).approve(address(hook), type(uint256).max);
        MockERC20(Currency.unwrap(token1)).approve(address(hook), type(uint256).max);
    }

    function deployCodeTo(string memory fileName, bytes memory constructorArgs, address target) internal override {
        bytes memory bytecode = abi.encodePacked(vm.getCode(fileName), constructorArgs);
        vm.etch(target, bytecode);
    }

    function deployPosm(
        IPoolManager manager,
        IWETH9 _WETH9
    ) public returns (PositionManager) {
        IAllowanceTransfer permit2 = IAllowanceTransfer(deployPermit2());
        PositionDescriptor positionDescriptor =
            new PositionDescriptor(manager, 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, "ETH");
        return new PositionManager(manager, permit2, 100_000, positionDescriptor, _WETH9);
    }

    function deployPermit2() public returns (address) {
        // Implement the logic to deploy Permit2 contract
        // This is a placeholder implementation
        return address(new MockERC20("Permit2", "P2", 18));
    }
}
