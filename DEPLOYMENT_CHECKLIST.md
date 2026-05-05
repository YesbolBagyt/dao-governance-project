# DAO Deployment Checklist

## Pre-deployment

- [ ] Run forge build
- [ ] Run forge test
- [ ] Run Slither
- [ ] Check token supply
- [ ] Check Governor parameters
- [ ] Check Timelock delay

## Deployment Order

1. Deploy TimelockController
2. Deploy GovernanceToken
3. Deploy MyGovernor
4. Grant PROPOSER_ROLE to Governor
5. Grant EXECUTOR_ROLE
6. Revoke admin role from deployer
7. Deploy Treasury
8. Deploy Box owned by Timelock

## Post-deployment Verification

- [ ] Timelock delay is 2 days
- [ ] Governor has proposer role
- [ ] Timelock controls treasury
- [ ] Timelock owns Box
- [ ] Delegation works
- [ ] Proposal lifecycle works

## Monitoring Plan

Events to monitor:
- ProposalCreated
- VoteCast
- ProposalQueued
- ProposalExecuted
- RoleGranted
- RoleRevoked
- Transfer

Metrics to track:
- Active proposals
- Voter turnout
- Quorum participation
- Treasury balance
- Large token holders