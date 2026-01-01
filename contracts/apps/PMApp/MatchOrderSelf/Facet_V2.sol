// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Facet} from "../../../Facet.sol";
import {MatchOrderSelfBase} from "./Base.sol";
import {IMatchOrderSelfFacet} from "./IFacet.sol";
import "../../../utils/IERC20.sol";
import {AccessControlBase} from "../../../facets/AccessControl/Base.sol";

contract MatchOrderSelfFacet_V2 is IMatchOrderSelfFacet, MatchOrderSelfBase, AccessControlBase, Facet {
    function MatchOrderSelfFacet_V2_init(uint8 roleB) external onlyInitializing {
        _setFunctionAccess(this.matchOrderSelf.selector, roleB, true);
        _addInterface(type(IMatchOrderSelfFacet).interfaceId);
    }

    function MatchOrderSelf_version() external pure returns (string memory) {
        return "V2";
    }

    function matchOrderSelf(OrderSelf memory order) external whenNotPaused protected nonReentrant {
        // Make sure the market has not closed or been delisted
        if (s.marketIsEndedMap[order.marketId] || s.marketIsBlockedMap[order.marketId]) revert MarketIsEndedOrBlocked(order.marketId, order.salt);
        if (s.marketIdMap[order.marketId].length == 0) revert MarketIdNotExist(order.marketId, order.salt);
        uint256 nftId1 = s.marketIdMap[order.marketId][0];
        uint256 nftId2 = s.marketIdMap[order.marketId][1];

        bytes32 digest = _getDigest(
            keccak256(
                abi.encode(
                    TYPEHASH_ORDER_SELF,
                    order.salt,
                    order.maker,
                    order.marketId,
                    order.tradeType,
                    order.paymentTokenAmount,
                    order.paymentTokenAddress,
                    order.deadline,
                    order.feeTokenAddress
                )
            )
        );
        // The order has been completed or cancelled
        if (s.orderIsFilledOrCancelledMap[digest]) revert OrderFilledOrCancelled(order.salt);
        s.orderIsFilledOrCancelledMap[digest] = true;

        // Verify the signature
        address signer = _recoverSigner(digest, order.sig);
        if (order.maker != signer) revert InvalidSignature(order.salt, order.sig, order.maker, signer);

        // Is it an allowed payment token address?
        if (s.paymentAddressMap[order.paymentTokenAddress] == false) {
            revert InvalidPaymentToken(order.salt, order.paymentTokenAddress);
        }
        uint256 paymentTokenDecimals = 10 ** IERC20(order.paymentTokenAddress).decimals();
        uint256 nftTokenAmount = (order.paymentTokenAmount * 10 ** TOKEN_DECIMALS) / paymentTokenDecimals;
        if (order.tradeType == 0) {
            // Split order, maker pays StableCoin
            bool paymentResult = IERC20(order.paymentTokenAddress).transferFrom(order.maker, address(this), order.paymentTokenAmount);
            if (!paymentResult)
                revert PaymentTransferFailed(order.salt, order.maker, address(this), order.paymentTokenAddress, order.paymentTokenAmount);

            _chargeAllFee(order);
            // Split the order and mint 2 types of NFT for the maker
            _mint(order.maker, nftId1, nftTokenAmount, "");
            _mint(order.maker, nftId2, nftTokenAmount, "");
            s.marketVaultMap[order.marketId][order.paymentTokenAddress] += order.paymentTokenAmount;
        } else if (order.tradeType == 1) {
            // Combine orders and destroy maker’s 2 types of NFTs
            _burn(order.maker, nftId1, nftTokenAmount); 
            _burn(order.maker, nftId2, nftTokenAmount);

            // Combine orders, transfer StableCoin from market vault to maker
            bool paymentResult = IERC20(order.paymentTokenAddress).transfer(order.maker, order.paymentTokenAmount);
            if (!paymentResult)
                revert PaymentTransferFailed(order.salt, order.maker, address(this), order.paymentTokenAddress, order.paymentTokenAmount);

            uint256 currentBalance = s.marketVaultMap[order.marketId][order.paymentTokenAddress];
            if (currentBalance < order.paymentTokenAmount) {
                revert MarketVaultBalanceInsufficient(currentBalance, order.paymentTokenAmount);
            }
            s.marketVaultMap[order.marketId][order.paymentTokenAddress] -= order.paymentTokenAmount;
        }
    }
}
