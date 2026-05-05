const TOKEN_ADDRESS = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";
const GOVERNOR_ADDRESS = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0";
const BOX_ADDRESS = "0x0165878A594ca255338adfa4d48449f69242Eb8F";

const tokenAbi = [
  "function balanceOf(address) view returns (uint256)",
  "function getVotes(address) view returns (uint256)",
  "function delegates(address) view returns (address)",
  "function delegate(address)",
  "function decimals() view returns (uint8)"
];

const governorAbi = [
  "function propose(address[] targets,uint256[] values,bytes[] calldatas,string description) returns (uint256)",
  "function castVote(uint256 proposalId,uint8 support) returns (uint256)",
  "function queue(address[] targets,uint256[] values,bytes[] calldatas,bytes32 descriptionHash) returns (uint256)",
  "function execute(address[] targets,uint256[] values,bytes[] calldatas,bytes32 descriptionHash) payable returns (uint256)",
  "function hashProposal(address[] targets,uint256[] values,bytes[] calldatas,bytes32 descriptionHash) pure returns (uint256)",
  "function state(uint256 proposalId) view returns (uint8)",
  "function votingDelay() view returns (uint256)",
  "function votingPeriod() view returns (uint256)"
];

const boxAbi = [
  "function store(uint256 newValue)",
  "function retrieve() view returns (uint256)"
];

const connectBtn = document.getElementById("connectBtn");
const accountSpan = document.getElementById("account");
const balanceSpan = document.getElementById("balance");
const votingPowerSpan = document.getElementById("votingPower");
const delegateSpan = document.getElementById("delegate");

let provider;
let signer;
let token;
let governor;
let box;
let currentProposalId;
let proposalTargets;
let proposalValues;
let proposalCalldatas;
let proposalDescription;
let proposalDescriptionHash;

connectBtn.onclick = async () => {
  try {
    if (!window.ethereum) {
      alert("MetaMask не найден");
      return;
    }

    provider = new ethers.providers.Web3Provider(window.ethereum);
    await provider.send("eth_requestAccounts", []);

    signer = provider.getSigner();
    const address = await signer.getAddress();

    accountSpan.innerText = address;

    token = new ethers.Contract(TOKEN_ADDRESS, tokenAbi, signer);
    governor = new ethers.Contract(GOVERNOR_ADDRESS, governorAbi, signer);
    box = new ethers.Contract(BOX_ADDRESS, boxAbi, signer);

    await loadUserData(address);

  } catch (error) {
    console.error(error);
    alert("Ошибка подключения MetaMask");
  }
};

async function loadUserData(address) {
  const balance = await token.balanceOf(address);
  const decimals = await token.decimals();

  balanceSpan.innerText =
    ethers.utils.formatUnits(balance, decimals);

  const votingPower = await token.getVotes(address);
  votingPowerSpan.innerText =
    ethers.utils.formatUnits(votingPower, decimals);

  const delegate = await token.delegates(address);
  delegateSpan.innerText = delegate;
}

document.getElementById("delegateBtn").onclick = async () => {
  try {
    const addr = document.getElementById("delegateAddress").value;

    const tx = await token.delegate(addr);
    await tx.wait();

    alert("Delegated!");

    const address = await signer.getAddress();
    await loadUserData(address);

  } catch (err) {
    console.error(err);
    alert("Delegate error");
  }
};

document.getElementById("voteForBtn").onclick = async () => {
  vote(1);
};

document.getElementById("voteAgainstBtn").onclick = async () => {
  vote(0);
};

document.getElementById("voteAbstainBtn").onclick = async () => {
  vote(2);
};

async function vote(type) {
  try {
    const id = document.getElementById("proposalId").value;

    const tx = await governor.castVote(id, type);
    await tx.wait();

    alert("Vote submitted!");

  } catch (err) {
    console.error(err);
    alert("Vote error");
  }
}
async function updateProposalInfo() {
  if (!box) return;

  const value = await box.retrieve();
  document.getElementById("boxValue").innerText = value.toString();

  if (currentProposalId) {
    const state = await governor.state(currentProposalId);
    document.getElementById("proposalState").innerText = getStateName(state);
  }
}

function getStateName(state) {
  const states = [
    "Pending",
    "Active",
    "Canceled",
    "Defeated",
    "Succeeded",
    "Queued",
    "Expired",
    "Executed"
  ];

  return states[state] || "Unknown";
}

document.getElementById("createBoxProposalBtn").onclick =
async () => {
  try {

    const address = await signer.getAddress();

    const votes = await token.getVotes(address);

    console.log("Votes:", votes.toString());

    const boxInterface =
      new ethers.utils.Interface(boxAbi);

    proposalTargets = [BOX_ADDRESS];

    proposalValues = [0];

    proposalCalldatas = [
      boxInterface.encodeFunctionData(
        "store",
        [42]
      )
    ];

    proposalDescription =
      "Proposal: Store 42 in Box " + Date.now();

    proposalDescriptionHash =
      ethers.utils.id(proposalDescription);

    const tx = await governor.propose(
      proposalTargets,
      proposalValues,
      proposalCalldatas,
      proposalDescription,
      {
        gasLimit: 8000000
      }
    );

    const receipt = await tx.wait();

    console.log(receipt);

    currentProposalId =
      await governor.hashProposal(
        proposalTargets,
        proposalValues,
        proposalCalldatas,
        proposalDescriptionHash
      );

    document.getElementById(
      "currentProposalId"
    ).innerText =
      currentProposalId.toString();

    document.getElementById(
      "proposalId"
    ).value =
      currentProposalId.toString();

    await updateProposalInfo();

    alert("Proposal created!");

  } catch (err) {
    console.error(err);
    alert(err.reason || err.message);
  }
};

document.getElementById("moveToVotingBtn").onclick = async () => {
  try {
    const delay = await governor.votingDelay();

    await rpc("anvil_mine", [
      ethers.utils.hexValue(delay.toNumber() + 1)
    ]);

    await updateProposalInfo();

    alert("Proposal is now active!");
  } catch (err) {
    console.error(err);
    alert("Move to voting error");
  }
};

document.getElementById("endVotingBtn").onclick = async () => {
  try {
    const period = await governor.votingPeriod();

    await rpc("anvil_mine", [
      ethers.utils.hexValue(period.toNumber() + 1)
    ]);

    await updateProposalInfo();

    alert("Voting period ended!");
  } catch (err) {
    console.error(err);
    alert("End voting error");
  }
};

document.getElementById("queueBtn").onclick = async () => {
  try {
    const tx = await governor.queue(
      proposalTargets,
      proposalValues,
      proposalCalldatas,
      proposalDescriptionHash
    );

    await tx.wait();

    await updateProposalInfo();

    alert("Proposal queued!");
  } catch (err) {
    console.error(err);
    alert("Queue error");
  }
};

document.getElementById("executeBtn").onclick = async () => {
  try {

    await rpc("evm_increaseTime", [
      2 * 24 * 60 * 60 + 1
    ]);

    await rpc("evm_mine", []);

    const tx = await governor.execute(
      proposalTargets,
      proposalValues,
      proposalCalldatas,
      proposalDescriptionHash
    );

    await tx.wait();

    await updateProposalInfo();

    alert("Proposal executed!");

  } catch (err) {
    console.error(err);
    alert("Execute error");
  }
};

async function rpc(method, params = []) {
  await fetch("http://127.0.0.1:8545", {
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      jsonrpc: "2.0",
      id: 1,
      method,
      params
    })
  });
}