// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import 'forge-std/Script.sol';
import { ValantisSwapRouter } from '../src/swap-router/ValantisSwapRouter.sol';

contract ValantisRouterDeploy is Script {

    function run() external {
        
        uint256 deployerPrivateKey = vm.envUint('DEPLOYER_PRIVATE_KEY');
        address WETH = vm.envAddress('WETH');
        address protocolFactory = vm.envAddress('PROTOCOL_FACTORY');
        address permit2 = vm.envAddress('PERMIT2');

        vm.startBroadcast(deployerPrivateKey);

        ValantisSwapRouter swapRouter = new ValantisSwapRouter(protocolFactory, WETH, permit2);

        vm.stopBroadcast();
    }

}