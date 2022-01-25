const { expect } = require("chai");
const { ethers } = require("hardhat");

describe('BNBbingo Lottery', function () {
  beforeEach(async function() {
    const [owner, addr1, addr2] = await ethers.getSigners();

    const RandomGenerator = await ethers.getContractFactory("RandomGenerator");
    this.randomGenerator = await RandomGenerator.deploy();
    await this.randomGenerator.deployed();

    const BNBbingo = await ethers.getContractFactory("BNBbingo");
    this.bnbBingo = await BNBbingo.deploy(
      addr1.address,
      addr2.address,
      '50000000000000000',
      this.randomGenerator.address
    );
    await this.bnbBingo.deployed();
  });

  describe('1. Ticket Buy(Fail Case)', function () {
    it('1.1. Buying ticket before the round is started should be failed', async function () {
      await expect(this.bnbBingo.buyTicket([1, 2, 3, 4, 5, 6], {value: '1000000000000000000'}))
      .to.be.revertedWith('Round is not started');
    });
    it('1.2. Buying ticket with incorrect price should be failed', async function () {
      await this.bnbBingo.startRound();

      await expect(this.bnbBingo.buyTicket([1, 2, 3, 4, 5, 6], {value: '100000000000000000'}))
      .to.be.revertedWith('Incorrect ticket price');
    });
  });

  describe('2. Ticket Buy(Success Case)', function () {
    beforeEach(async function () {
      await this.bnbBingo.startRound();
    });

    describe('2.1. Buying 1st rank ticket', async function () {
      beforeEach(async function () {
        const [owner, addr1, addr2, addr3] = await ethers.getSigners();

        await this.bnbBingo.connect(addr3).buyTicket([1, 2, 3, 4, 5, 6], {value: '1000000000000000000'});
  
        await this.bnbBingo.stopRound();
        await this.bnbBingo.drawClaimableRound();
      });

      it('2.1.1. Claim token by not buyer should be failed', async function () {
        await expect(this.bnbBingo.claimTicket(1))
        .to.be.revertedWith('Not ticket owner');
      });

      it('2.1.2. Claim token by buyer should be success', async function () {
        const [owner, addr1, addr2, addr3] = await ethers.getSigners();
        expect(await this.bnbBingo.getPrize(1)).to.equal('400000000000000000');

        await this.bnbBingo.connect(addr3).claimTicket(1);
      });

      it('2.1.3. Claim ticket again should be failed', async function () {
        const [owner, addr1, addr2, addr3] = await ethers.getSigners();
        expect(await this.bnbBingo.getPrize(1)).to.equal('400000000000000000');

        await this.bnbBingo.connect(addr3).claimTicket(1);

        await expect(this.bnbBingo.connect(addr3).claimTicket(1))
      .to.be.revertedWith('The ticket was already claimed');
      });
    });
  });
});
