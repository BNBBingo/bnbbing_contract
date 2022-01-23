const { expect } = require("chai");
const { ethers } = require("hardhat");

describe('BNBbingo configuration', function () {
  beforeEach(async function() {
    const [owner, addr1, addr2] = await ethers.getSigners();

    const RandomGenerator = await ethers.getContractFactory("RandomGenerator");
    this.randomGenerator = await RandomGenerator.deploy();
    await this.randomGenerator.deployed();

    const BNBbingo = await ethers.getContractFactory("BNBbingo");
    this.bnbBingo = await BNBbingo.deploy(
      addr1.address,
      addr2.address,
      '1000000000000000000',
      this.randomGenerator.address
    );
    await this.bnbBingo.deployed();
  });

  describe('1. Initial Configuration', function () {
    it('1.1. Checking ticket price', async function () {
      expect(await this.bnbBingo.ticketPrice()).to.equal('1000000000000000000');
    });

    it('1.2. Checking Prize division price', async function () {
      expect(
        await this.bnbBingo.systemDivision()
      ).to.equal(5);
      
      expect(
        await this.bnbBingo.prizeDivision(0)
      ).to.equal(1);

      expect(
        await this.bnbBingo.prizeDivision(1)
      ).to.equal(2);

      expect(
        await this.bnbBingo.prizeDivision(2)
      ).to.equal(10);

      expect(
        await this.bnbBingo.prizeDivision(3)
      ).to.equal(17);

      expect(
        await this.bnbBingo.prizeDivision(4)
      ).to.equal(25);

      expect(
        await this.bnbBingo.prizeDivision(5)
      ).to.equal(40);
    });
  });

  describe('2. Ticket Price', function () {  
    it(
      '2.1. Setting ticket price by general user should be failed',
      async function() {
        const [owner, addr1, addr2] = await ethers.getSigners();
    
        await expect(
          this.bnbBingo.connect(addr1).setTicketPrice('100000000000000000')
        ).to.be.revertedWith('Ownable: caller is not the owner');
      }
    );
  
    it('2.2. Setting ticket price as zero should be failed', async function() {
      await expect(
        this.bnbBingo.setTicketPrice(0)
      ).to.be.revertedWith("Ticket price can't be zero");
    });

    it('2.3. Setting ticket price should be successed', async function() {
      await this.bnbBingo.setTicketPrice('10000000000000000');

      expect(
        await this.bnbBingo.ticketPrice()
      ).to.equal('10000000000000000');
    });
  });

  describe('3. Operator Setting', async function () {
    it(
      '3.1. Setting operator(A) by none operator(A) should be failed.',
      async function() {
        const [owner, addr1, addr2, addr3] = await ethers.getSigners();
    
        await expect(
          this.bnbBingo.connect(addr3).setAOperatorAddress(addr3.address)
        ).to.be.revertedWith('Incorrect operator');
      }
    );

    it(
      '3.2. Setting operator(B) by none operator(B) should be failed.',
      async function() {
        const [owner, addr1, addr2, addr3] = await ethers.getSigners();
    
        await expect(
          this.bnbBingo.connect(addr3).setBOperatorAddress(addr3.address)
        ).to.be.revertedWith('Incorrect operator');
      }
    );

    it(
      '3.3. Setting operator(A) by none operator(A) should be successed.',
      async function() {
        const [owner, addr1, addr2, addr3] = await ethers.getSigners();
    
        await this.bnbBingo.connect(addr1).setAOperatorAddress(addr3.address);

        expect(true);
      }
    );

    it(
      '3.4. Setting operator(B) by none operator(B) should be successed.',
      async function() {
        const [owner, addr1, addr2, addr3] = await ethers.getSigners();
    
        await this.bnbBingo.connect(addr2).setBOperatorAddress(addr3.address);

        expect(true);
      }
    );
  });

  describe('4. Prize division', async function () {
    it(
      '4.1. Setting prize division by none owner should be failed.',
      async function() {
        const [owner, addr1] = await ethers.getSigners();
    
        await expect(
          this.bnbBingo.connect(addr1).setPrizeDivision([1, 1, 1, 1, 1, 1])
        ).to.be.revertedWith('Ownable: caller is not the owner');
      }
    );

    it(
      '4.2. Setting prize division with overflow rates should be failed.',
      async function() {
        await expect(
          this.bnbBingo.setPrizeDivision([20, 20, 20, 20, 10, 10])
        ).to.be.revertedWith('Percentage overflow');
      }
    );

    it(
      '4.3. Setting prize division should be failed.',
      async function() {
        await this.bnbBingo.setPrizeDivision([10, 10, 10, 10, 20, 30]);

        expect(
          await this.bnbBingo.systemDivision()
        ).to.equal(10);
        
        expect(
          await this.bnbBingo.prizeDivision(0)
        ).to.equal(10);
  
        expect(
          await this.bnbBingo.prizeDivision(1)
        ).to.equal(10);
  
        expect(
          await this.bnbBingo.prizeDivision(2)
        ).to.equal(10);
  
        expect(
          await this.bnbBingo.prizeDivision(3)
        ).to.equal(10);
  
        expect(
          await this.bnbBingo.prizeDivision(4)
        ).to.equal(20);
  
        expect(
          await this.bnbBingo.prizeDivision(5)
        ).to.equal(30);
      }
    );
  });
});
