const UniswapPCVDeposit = artifacts.require('UniswapPCVDeposit');
const UniswapPCVController = artifacts.require('UniswapPCVController');
const BondingCurve = artifacts.require('BondingCurve');
const TribeReserveStabilizer = artifacts.require('TribeReserveStabilizer');
const EthReserveStabilizer = artifacts.require('EthReserveStabilizer');
const PCVDripController = artifacts.require('PCVDripController');
const RatioPCVController = artifacts.require('RatioPCVController');
const Core = artifacts.require('Core');
const Tribe = artifacts.require('Tribe');

async function upgrade(addresses, logging = false) {
  const {
    coreAddress,
    oldUniswapPCVDepositAddress,
    ethUniswapPCVDepositAddress,
    ethUniswapPCVControllerAddress,
    ethBondingCurveAddress,
    ethReserveStabilizerAddress,
    tribeReserveStabilizerAddress,
    ratioPCVControllerAddress,
    pcvDripControllerAddress,
    timelockAddress
  } = addresses;

  const deposit = await UniswapPCVDeposit.at(ethUniswapPCVDepositAddress);
  const controller = await UniswapPCVController.at(ethUniswapPCVControllerAddress);
  const bondingCurve = await BondingCurve.at(ethBondingCurveAddress);
  const tribeReserveStabilizer = await TribeReserveStabilizer.at(tribeReserveStabilizerAddress);
  
  const ratioPCVController = await RatioPCVController.at(ratioPCVControllerAddress);
  const pcvDripController = await PCVDripController.at(pcvDripControllerAddress);
  const ethReserveStabilizer = await EthReserveStabilizer.at(ethReserveStabilizerAddress);

  const core = await Core.at(coreAddress);
  const tribe = await Tribe.at(await core.tribe());

  logging ? console.log('Granting Burner to new UniswapPCVController') : undefined;
  await core.grantBurner(controller.address);

  logging ? console.log('Granting Minter to new UniswapPCVController') : undefined;
  await core.grantMinter(controller.address);

  logging ? console.log('Granting Minter to new BondingCurve') : undefined;
  await core.grantMinter(bondingCurve.address);

  logging ? console.log('Granting Minter to new UniswapPCVDeposit') : undefined;
  await core.grantMinter(deposit.address);

  logging ? console.log('Granting Burner to new TribeReserveStabilizer') : undefined;
  await core.grantBurner(tribeReserveStabilizer.address);

  // special role
  // check via tribe contract
  logging ? console.log('Transferring TRIBE Minter role to TribeReserveStabilizer') : undefined;
  await tribe.setMinter(tribeReserveStabilizer.address, {from: timelockAddress});

  logging ? console.log('Granting Burner to new EthReserveStabilizer') : undefined;
  await core.grantBurner(ethReserveStabilizer.address);

  logging ? console.log('Granting PCVController to new RatioPCVController') : undefined;
  await core.grantPCVController(ratioPCVController.address);

  logging ? console.log('Granting PCVController to new PCVDripController') : undefined;
  await core.grantPCVController(pcvDripController.address);

  logging ? console.log('Granting Minter to new PCVDripController') : undefined;
  await core.grantMinter(pcvDripController.address);

  await ratioPCVController.withdrawRatio(oldUniswapPCVDepositAddress, ethUniswapPCVDepositAddress, '10000'); // move 100% of PCV from old -> new
}

/// /  --------------------- NOT RUN ON CHAIN ----------------------
async function revokeOldContractPerms(core, oldContractAddresses) {
  const {
    oldUniswapPCVDepositAddress,
    oldUniswapPCVControllerAddress,
    oldEthReserveStabilizerAddress,
    oldRatioControllerAddress,
    oldBondingCurveAddress,
  } = oldContractAddresses;

  // Revoke controller permissions
  await core.revokeMinter(oldUniswapPCVControllerAddress);
  await core.revokeMinter(oldUniswapPCVDepositAddress);
  await core.revokeMinter(oldBondingCurveAddress);

  await core.revokeBurner(oldUniswapPCVControllerAddress);
  await core.revokeBurner(oldEthReserveStabilizerAddress);  

  await core.revokePCVController(oldRatioControllerAddress);
  await core.revokePCVController(oldUniswapPCVControllerAddress);
}

module.exports = { upgrade, revokeOldContractPerms };