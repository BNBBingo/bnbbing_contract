// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers, network, run, upgrades } = require("hardhat");
const { NomicLabsHardhatPluginError } = require("hardhat/plugins");

const params = {
  mainnet: {
    address1: "0xdC53a086feDe6e24a8C573039bCc6c93E7e58239",
    address2: "0x484df4A08C27f2F3268D6A7A1eF0baDCe1afC10F",
    price: "50000000000000000",
  },
  testnet: {
    address1: "0xdC53a086feDe6e24a8C573039bCc6c93E7e58239",
    address2: "0x484df4A08C27f2F3268D6A7A1eF0baDCe1afC10F",
    price: "50000000000000000",
  },
}

async function main() {
  const signers = await ethers.getSigners();
  // Find deployer signer in signers.
  let deployer;
  signers.forEach((a) => {
    if (a.address === process.env.ADDRESS) {
      deployer = a;
    }
  });
  if (!deployer) {
    throw new Error(`${process.env.ADDRESS} not found in signers!`);
  }

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Network:", network.name);

  if (network.name === "testnet" || network.name === "mainnet") {
    // const RandomGenerator = await ethers.getContractFactory("RandomGenerator");
    // const randomGenerator = await RandomGenerator.deploy();
    // await randomGenerator.deployed();

    // console.log("Deployed RandomGenerator Address: " + randomGenerator.address);

    // try {
    //   // verify
    //   await run("verify:verify", {
    //     address: randomGenerator.address
    //   });
    //   console.log("Deployed RandomGenerator Verified");
    // } catch (error) {
    //   if (error instanceof NomicLabsHardhatPluginError) {
    //     console.log("RandomGenerator: Contract source code already verified");
    //   } else {
    //     console.error(error);
    //   }
    // }

    const BNBBingo = await ethers.getContractFactory("BNBbingo");
    const bnbBingo = await BNBBingo.deploy(
      params[network.name].address1,
      params[network.name].address2,
      params[network.name].price,
      // randomGenerator.address
      '0xE3D5456Dd61D5B0255835cfe6Ee7350A9BB52C5d'
    );
    await bnbBingo.deployed();

    console.log("Deployed BNBBingo Address: " + bnbBingo.address);

    try {
      // verify
      await run("verify:verify", {
        address: bnbBingo.address,
        args: [
          params[network.name].address1,
          params[network.name].address2,
          params[network.name].price,
          // randomGenerator.address
          '0xE3D5456Dd61D5B0255835cfe6Ee7350A9BB52C5d'
        ]
      });
      console.log("Deployed BNBBingo Verified");
    } catch (error) {
      if (error instanceof NomicLabsHardhatPluginError) {
        console.log("BNBBingo: Contract source code already verified");
      } else {
        console.error(error);
      }
    }
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
