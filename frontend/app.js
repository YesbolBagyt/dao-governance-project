const connectBtn = document.getElementById("connectBtn");
const accountSpan = document.getElementById("account");

let provider;
let signer;

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
    console.log("Connected:", address);
  } catch (error) {
    console.error(error);
    alert("Ошибка подключения MetaMask");
  }
};