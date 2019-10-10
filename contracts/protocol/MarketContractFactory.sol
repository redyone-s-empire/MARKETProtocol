/*
    Copyright 2017-2019 MARKET Protocol

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.11;

import "./MarketContract.sol";
import "./MarketContractRegistryInterface.sol";

import "github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.3.0/contracts/ownership/Ownable.sol";

/// @title MarketContractFactoryMPX
/// @author MARKET Protocol <support@marketprotocol.io>
contract MarketContractFactory is Ownable {

    address public marketContractRegistry;
    address public marketCollateralPool;

    event MarketContractCreated(address indexed creator, address indexed contractAddress);

    /// @dev deploys our factory and ties it to the supplied registry address
    /// @param registryAddress - address of our MARKET registry
    /// @param collateralPoolAddress - address of our MARKET Collateral pool
    constructor(
        address registryAddress,
        address collateralPoolAddress
    ) public {
        require(registryAddress != address(0), "registryAddress can not be null");
        require(collateralPoolAddress != address(0), "collateralPoolAddress can not be null");

        marketContractRegistry = registryAddress;
        marketCollateralPool = collateralPoolAddress;
    }

    /// @dev Deploys a new instance of a market contract and adds it to the whitelist.
    /// @param contractNames bytes32 array of names
    ///     contractName            name of the market contract
    ///     longTokenSymbol         symbol for the long token
    ///     shortTokenSymbol        symbol for the short token
    /// @param collateralTokenAddress address of the ERC20 token that will be used for collateral and pricing
    /// @param contractSpecs array of unsigned integers including:
    ///     floorPrice              minimum tradeable price of this contract, contract enters settlement if breached
    ///     capPrice                maximum tradeable price of this contract, contract enters settlement if breached
    ///     priceDecimalPlaces      number of decimal places to convert our queried price from a floating point to
    ///                             an integer
    ///     qtyMultiplier           multiply traded qty by this value from base units of collateral token.
    ///     feeInBasisPoints    fee amount in basis points (Collateral token denominated) for minting.
    ///     mktFeeInBasisPoints fee amount in basis points (MKT denominated) for minting.
    ///     expirationTimeStamp     seconds from epoch that this contract expires and enters settlement
    /// @param oracleURL url of data
    /// @param oracleStatistic statistic type (lastPrice, vwap, etc)
    /// @param oracleHubAddress address of the wallet which can trigger settlement
    function deployMarketContract(
        bytes32[3] calldata contractNames,
        address collateralTokenAddress,
        uint[7] calldata contractSpecs,
        string calldata oracleURL,
        string calldata oracleStatistic,
        address oracleHubAddress
    ) external
    {
        MarketContract mktContract = new MarketContract(
            contractNames,
            [
            owner(),
            collateralTokenAddress,
            marketCollateralPool
            ],
            oracleHubAddress,
            contractSpecs,
            oracleURL,
            oracleStatistic
        );

        MarketContractRegistryInterface(marketContractRegistry).addOwnerContract(msg.sender, address(mktContract));
        emit MarketContractCreated(msg.sender, address(mktContract));
    }

    /// @dev allows for the owner to set the desired registry for contract creation.
    /// @param registryAddress desired registry address.
    function setRegistryAddress(address registryAddress) external onlyOwner {
        require(registryAddress != address(0), "registryAddress can not be null");
        marketContractRegistry = registryAddress;
    }
}