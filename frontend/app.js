const connectBtn = document.getElementById("connectBtn");
const accountSpan = document.getElementById("account");

let provider;
let signer;

connectBtn.onclick = async () => {
  if (window.ethereum) {
    provider = new ethers.providers.Web3Provider(window.ethereum);
    await provider.send("eth_requestAccounts", []);
    signer = provider.getSigner();

    const address = await signer.getAddress();
    accountSpan.innerText = address;
  } else {
    alert("Install MetaMask");
  }
};