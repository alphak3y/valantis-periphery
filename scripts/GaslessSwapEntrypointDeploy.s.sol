// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import 'forge-std/Script.sol';
import { GaslessSwapEntrypoint } from '../src/swap-router/GaslessSwapEntrypoint.sol';

contract GaslessSwapEntrypointDeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint('DEPLOYER_PRIVATE_KEY');
        address owner = vm.envAddress('GASLESSSWAP_ENTRYPOINT_OWNER');
        // solhint-disable-next-line var-name-mixedcase
        address DAI = vm.envAddress('DAI');
        address swapRouter = vm.envAddress('SWAP_ROUTER');

        vm.startBroadcast(deployerPrivateKey);

        new GaslessSwapEntrypoint(owner, swapRouter, DAI);

        vm.stopBroadcast();
    }
}
