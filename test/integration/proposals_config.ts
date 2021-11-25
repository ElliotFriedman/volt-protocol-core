import { ProposalsConfigMap } from '@custom-types/types';

// import fip_xx_proposal from '@proposals/description/fip_xx';

import ido_liquidity_removal_proposal from '@proposals/description/ido_liquidity_removal';

const proposals: ProposalsConfigMap = {
  /*
    fip_xx : {
        deploy: true, // deploy flag for whether to run deploy action during e2e tests or use mainnet state
        skipDAO: false, // whether or not to simulate proposal in DAO
        totalValue: 0, // amount of ETH to send to DAO execution
        proposal: fip_xx_proposal // full proposal file, imported from '@proposals/description/fip_xx.ts'
    }
    */

  fip_liquidity_removal: {
    deploy: true,
    skipDAO: false,
    totalValue: 0,
    proposal: ido_liquidity_removal_proposal
  }
};

export default proposals;
