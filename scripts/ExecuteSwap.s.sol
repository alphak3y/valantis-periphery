// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import "forge-std/console.sol";

import {GaslessSwapEntrypoint} from "src/swap-router/GaslessSwapEntrypoint.sol";
import {IAllowanceTransfer} from "src/swap-router/interfaces/IAllowanceTransfer.sol";
import {Permit2Info, TokenPermitInfo} from "src/swap-router/structs/GaslessSwapEntrypointStructs.sol";
import {GaslessSwapIntent, GaslessSwapParams} from "src/swap-router/structs/ValantisSwapRouterStructs.sol";

contract Default is Script {
    using stdJson for string;

    string instanceId;
    uint256 instanceIdBlock = 0;
    string rpcUrl;
    uint256 forkBlock;
    uint256 initialReserveCount;

    string config;
    string deployedContracts;

    function run() external {

        // vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        // First, declare the arrays for GaslessSwapParams
        bool[] memory isUniversalPool = new bool[](1);
        isUniversalPool[0] = false;

        address[] memory pools = new address[](1);
        pools[0] = 0x5365b6EF09253C7aBc0A9286eC578A9f4B413B7D;

        uint256[] memory amountInSpecified = new uint256[](1);
        amountInSpecified[0] = 100000000000000000;

        bytes[] memory payloads = new bytes[](1);
        payloads[0] = hex"000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000005abe35ddb420703ba6dd7226acdcb24be71192e50000000000000000000000005555555555555555555555555555555555555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";

        // Create the GaslessSwapIntent struct
        GaslessSwapIntent memory intent = GaslessSwapIntent({
            isTokenOutEth: true,
            tokenIn: 0xfFaa4a3D97fE9107Cef8a3F48c069F577Ff76cC1,
            tokenOut: 0x5555555555555555555555555555555555555555,
            owner: 0x2fCf555c4C508c2e358F373A4B6E25F8491928b0,
            recipient: 0x2fCf555c4C508c2e358F373A4B6E25F8491928b0,
            authorizedSender: 0x38252268C18339f996F1fE903b2970891185Ecd0,
            feeToken: address(0),
            amountIn: 100000000000000000,
            amountOutMin: 0,
            maxFee: 10000000000000000,
            nonce: 2059,
            deadline: 1743681497
        });

        // Create the GaslessSwapParams struct
        GaslessSwapParams memory params = GaslessSwapParams({
            isUniversalPool: isUniversalPool,
            pools: pools,
            amountInSpecified: amountInSpecified,
            payloads: payloads,
            intent: intent
        });

        // Create the TokenPermitInfo struct
        TokenPermitInfo memory tokenPermitInfo = TokenPermitInfo({
            isEnabled: false,
            data: ""
        });

        // Create the Permit2Info struct
        IAllowanceTransfer.PermitDetails[] memory permitDetails = new IAllowanceTransfer.PermitDetails[](1);
        permitDetails[0] = IAllowanceTransfer.PermitDetails({
            token: 0xfFaa4a3D97fE9107Cef8a3F48c069F577Ff76cC1,
            amount: 100000000000000000,
            expiration: 1743681497,
            nonce: 2
        });

        Permit2Info memory permit2Info = Permit2Info({
            isEnabled: true,
            permitBatch: IAllowanceTransfer.PermitBatch({
                details: permitDetails,
                spender: 0x5Abe35DDb420703bA6Dd7226ACDCb24be71192e5,
                sigDeadline: 1743681497
            }),
            signature: hex"29b05ee1ea01fffc5456e5d8ff87b1e68ca371a735344f31916526b294390c15658bca65cab762ea02cc4865848891b659aed9337cad73eaf4f2eacb86ecfee31c"
        });

        vm.prank(0x2fCf555c4C508c2e358F373A4B6E25F8491928b0);

        // Make the swapOwnerExecute call
        GaslessSwapEntrypoint(0x38252268C18339f996F1fE903b2970891185Ecd0).swapOwnerExecute(
            params,
            hex"e41c2184d35cefee4021a5643b4c373f166e27d7ccb5cdb0e1451f02909a0cc545d36afeade33499e8abd23b09a8c487f267d9ba3def2e574bd81d21d84a767c1b",
            0,
            tokenPermitInfo,
            permit2Info
        );
    }
}
