# Online play: one-time setup (owner steps)

These steps create the free accounts the online features need. Claude does all
the coding and deploying; only the account owner can create accounts.

**Never paste passwords, private keys or the Firebase service-account file into
chat or into the code.** They go only into GitHub's encrypted secrets (step 5).

Total cost: **US$0** (Oracle Cloud Always Free + Firebase free "Spark" plan + free DuckDNS name).

---

## 1. An SSH key for the server (on your computer, 1 minute)

GitHub uses this key to install updates on the server.

```sh
ssh-keygen -t ed25519 -f rsludo_server -C "rs-ludo deploy" -N ""
```

This makes two files: `rsludo_server.pub` (public, goes to Oracle) and
`rsludo_server` (private, goes only into GitHub secrets in step 5).

## 2. Oracle Cloud free server (about 20 minutes)

1. Sign up at https://www.oracle.com/cloud/free/ . A card is asked for **identity
   verification only**; Always Free resources are not charged. Choose a home
   region near your players (for Malaysia: **Singapore**). The home region cannot be changed later.
2. Menu > **Compute > Instances > Create instance**:
   - Name: `rs-ludo`
   - Image: **Canonical Ubuntu 22.04**
   - Shape: **Ampere VM.Standard.A1.Flex**, 1 OCPU, 6 GB memory (shows "Always Free-eligible")
   - Add SSH keys: **Paste public key** and paste the contents of `rsludo_server.pub`
   - Create. Write down the **Public IP address**.
   - If Oracle says "out of capacity", try again later or pick another availability domain.
3. Open the web ports: on the instance page click the **Subnet** > **Default Security List** >
   **Add Ingress Rules**: Source CIDR `0.0.0.0/0`, TCP, destination ports **80** and **443**.

## 3. A free web address for the server (5 minutes)

Phones and the iPad web version need a secure (`wss://`) address with a name.

1. Go to https://www.duckdns.org , sign in, and create a sub-domain, e.g. `rsludo`
   (giving `rsludo.duckdns.org`).
2. Put the Oracle **Public IP** in its "current ip" box and click **update ip**.

(If you own a domain, an A record pointing to the IP works too.)

## 4. Firebase project for accounts and saved data (10 minutes)

1. https://console.firebase.google.com > **Add project** > name `rs-ludo`. Google Analytics: optional.
   Stay on the free **Spark** plan; no Cloud Functions are needed.
2. **Build > Authentication > Get started > Sign-in method**: enable **Anonymous**
   (guest accounts). Google and Facebook are added later.
3. **Build > Firestore Database > Create database**: production mode, location
   **asia-southeast1 (Singapore)**.
4. **Project settings** (gear icon) > General: note the **Project ID** and the **Web API key**.
5. **Project settings > Service accounts > Generate new private key**. A `.json` file downloads.
   It goes only into GitHub secrets (next step); delete it from your computer afterwards.

## 5. Put everything into GitHub (5 minutes)

GitHub > **RsLUDO > Settings > Secrets and variables > Actions**.

**Secrets** (encrypted, never shown again):

| Name | Value |
| --- | --- |
| `SERVER_SSH_KEY` | contents of the private key file `rsludo_server` |
| `FIREBASE_SERVICE_ACCOUNT` | the whole contents of the downloaded `.json` file |

**Variables** (not secret):

| Name | Value |
| --- | --- |
| `SERVER_HOST` | the Oracle public IP |
| `SERVER_DOMAIN` | e.g. `rsludo.duckdns.org` |
| `FIREBASE_PROJECT_ID` | the Project ID |
| `FIREBASE_API_KEY` | the Web API key (it identifies the project; it is not a password) |

## 6. Tell Claude "online setup done"

Claude then builds the game server, a GitHub workflow that installs and updates
it on the Oracle server automatically, and the online screens, starting with
**Create Room / Join Room with a code**, then **Quick Match**, then **Friends**.
