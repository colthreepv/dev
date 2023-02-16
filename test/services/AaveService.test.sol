// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20PresetMinterPauser } from "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import { IVault } from "../../src/interfaces/IVault.sol";
import { IService } from "../../src/interfaces/IService.sol";
import { IManager, Manager } from "../../src/Manager.sol";
import { IAToken } from "../../src/interfaces/external/aave/IAToken.sol";
import { AaveService } from "../../src/services/debit/AaveService.sol";
import { GeneralMath } from "../../src/libraries/GeneralMath.sol";
import { BaseIntegrationServiceTest } from "./BaseIntegrationServiceTest.sol";
import { Helper } from "./Helper.sol";

contract AaveServiceTest is BaseIntegrationServiceTest {
    using GeneralMath for uint256;

    AaveService internal immutable service;
    address internal constant aavePool = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;

    string internal constant rpcUrl = "ARBITRUM_RPC_URL";
    uint256 internal constant blockNumber = 55895589;

    constructor() BaseIntegrationServiceTest(rpcUrl, blockNumber) {
        vm.startPrank(admin);
        service = new AaveService(address(manager), aavePool);
        vm.stopPrank();
        loanLength = 1;
        loanTokens = new address[](loanLength);
        collateralTokens = new address[](1);
        loanTokens[0] = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1; // DAI
        whales[loanTokens[0]] = 0x252cd7185dB7C3689a571096D5B57D45681aA080;
        collateralTokens[0] = 0x82E64f49Ed5EC1bC6e43DAD4FC8Af9bb3A2312EE;
        serviceAddress = address(service);
    }

    function testOpen(uint256 daiAmount, uint256 daiLoan, uint256 daiMargin) public {
        uint256 whaleBalance = IERC20(loanTokens[0]).balanceOf(whales[loanTokens[0]]);
        uint256 transformedAmount = daiAmount % whaleBalance;
        if (transformedAmount == 0) transformedAmount++;
        uint256 transformedMargin = (daiMargin % (whaleBalance - transformedAmount));
        if (transformedMargin == 0) transformedMargin++;
        IService.Order memory order = _openOrder1(
            daiAmount,
            daiLoan,
            daiMargin,
            (daiLoan % transformedAmount) + transformedMargin,
            block.timestamp,
            ""
        );
        service.open(order);
    }

    function testClose(uint256 daiAmount, uint256 daiLoan, uint256 daiMargin, uint256 minAmountsOutDai) public {
        testOpen(daiAmount, daiLoan, daiMargin);

        bytes memory data = abi.encode(minAmountsOutDai);

        (, IService.Collateral[] memory collaterals, , ) = service.getAgreement(1);
        if (collaterals[0].amount < minAmountsOutDai) {
            // Slippage check
            vm.expectRevert(bytes4(keccak256(abi.encodePacked("InsufficientAmountOut()"))));
            service.close(0, data);
        } else {
            service.close(0, data);
        }
    }

    function testQuote(uint256 daiAmount, uint256 daiLoan, uint256 daiMargin) public {
        testOpen(daiAmount, daiLoan, daiMargin);

        (
            IService.Loan[] memory loan,
            IService.Collateral[] memory collaterals,
            uint256 createdAt,
            IService.Status status
        ) = service.getAgreement(1);

        IService.Agreement memory agreement = IService.Agreement(loan, collaterals, createdAt, status);
        (uint256[] memory profits, ) = service.quote(agreement);
    }
}
