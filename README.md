# Xento Contracts.

Solidity Smart contracts for the Xento Dapp project.

## Important commands.

1. `npx hardhat node`

Creates a new hardhat node(local blockchain environment).

2. `npx hardhat compile`

Compiles all the smart contracts in the contracts directory.

3. `npx hardhat ignition deploy ./ignition/modules/<contract-ignition-module>.ts --network <network-name> --deployment-id <desired-deployment-id>`

Deploys your smart contract to the specified network(the network must have been configured in your hardhat config file).

E.g: `npx hardhat ignition deploy ./ignition/modules/Lock.ts --network localhost --deployment-id localhost-deployment`

4. `npx hardhat ignition verify <deployment-id>`

Verifies smart contracts deployed on testnets/mainnets.

E.g: `npx hardhat ignition verify sepolia-deployment`

5. `npx hardhat test`

Runs all tests. It also triggers the gas report output, hence you should be cautious about how much you run tests(with your API key on), to avoid excess cost and/or rate limiting due to too many API requests(see the gas reporter setup inside hardhat config file for more insight).

6. `npx hardhat coverage`

Checks for test coverage. Ensure to add the "solidity coverage import to your hardhat config file(`import solidity-coverage`) - already added on this template.

7. `npm run lint`

For linting Solidity(smart contract) code with solhint(see the `lint` script inside `package.json`).

8. `npx hardhat docgen`

Generates markdown documentations(using Natspec comments that has been added to the contracts) - thanks to OpenZepellin's `solidity-docgen` utility/library

> **The generated docs can be found inside the `docs` folder.**
