# Diode VPN Client Protocol Specification

This document specifies everything a third-party client (macOS, Windows, iOS, Linux, etc.) needs to implement a Diode VPN application that connects to Diode exit nodes over WireGuard. It is derived from the reference Android client in this repository and from the Diode node WireGuard exit-node specification (v0.1.4+).

**Scope:** network discovery, authentication (TicketV2), WebSocket JSON-RPC session management, WireGuard tunnel bring-up, mid-session billing refresh, disconnect, and error handling.

**Out of scope:** platform-specific VPN APIs (TUN, `VpnService`, Network Extension, Wintun), app-store subscription UX, and server-side node deployment.

---

## 1. Overview

A Diode VPN client:

1. Fetches the list of VPN-capable exit nodes (`dio_network`).
2. Optionally enriches nodes with geolocation for UI grouping.
3. Lets the user pick an exit node (by country or directly).
4. Verifies the user is entitled to connect (product/billing policy — see §12).
5. Opens a **WebSocket JSON-RPC** session to the **selected node's** RPC endpoint.
6. Authenticates with a signed **TicketV2** (`dio_ticket`).
7. Registers a WireGuard peer (`dio_wireguard_open`).
8. Brings up a **WireGuard UDP tunnel** to the returned endpoint.
9. Keeps the WebSocket open for the session lifetime; responds to server-pushed billing refresh (`dio_ticket_request`).
10. On disconnect, calls `dio_wireguard_close` and tears down the tunnel.

```mermaid
sequenceDiagram
  participant Client
  participant Prenet as Prenet HTTPS
  participant Node as Exit Node WSS
  participant WG as Exit Node WireGuard UDP
  participant Geo as Geo API

  Client->>Prenet: POST dio_network
  Prenet-->>Client: node list
  Client->>Geo: GET /ip/{host} (optional)
  Geo-->>Client: lat, lon, city
  Note over Client: User selects node; entitlement check
  Client->>Node: WSS connect
  Client->>Node: dio_ticket(ticketHex)
  Node-->>Client: result null
  Client->>Node: dio_wireguard_open(pubKeyHex)
  Node-->>Client: WireGuardSessionInfo
  Client->>WG: WireGuard handshake + traffic
  Note over Node,Client: Mid-session: dio_ticket_request notification
  Client->>Node: dio_ticket(refreshedTicketHex)
  Client->>Node: dio_wireguard_close (on disconnect)
```

---

## 2. Production endpoints and constants

| Constant | Value | Notes |
|----------|-------|-------|
| Prenet HTTPS RPC | `https://prenet.diode.io:8443/` | `dio_network`, one-shot JSON-RPC |
| Prenet WebSocket | `wss://prenet.diode.io:8443/ws` | Fallback only; prefer per-node WS (§4) |
| Per-node HTTPS | `https://{node_host}:8443/` | Same JSON-RPC as WS |
| Per-node WebSocket | `wss://{node_host}:8443/ws` | **Required** for production connect |
| Geo API | `https://monitor.testnet.diode.io` | `GET /ip/{ip}` |
| Moonbeam RPC | `https://rpc.api.moonbeam.network` | Epoch lookup for TicketV2 |
| Moonbeam chain ID | `1284` | TicketV2 `chain_id` |
| Epoch duration | `2_592_000` seconds (30 days) | `epoch = block.timestamp / 2_592_000` |
| VPN fleet contract | `0xd5b1221fce90049fbfc917f28b8996a07fdfdea7` | 20-byte Ethereum address |
| Developer fleet (dev/test) | `0x6000000000000000000000000000000000000000` | Legacy / Anvil |
| Default WireGuard port | `51820` | Used when not returned by RPC |
| Initial ticket `total_bytes` | `4096` | First `dio_ticket` allowance |
| Ticket refresh headroom | `65536` bytes | Added on top of server `usage` |
| Max ticket byte step | `50_000_000` | Per refresh hop (node `too_big_jump` limit) |
| `too_low` retry limit | `3` attempts | Per ticket submission burst |
| `dio_ticket_request` deadline | **20 seconds** | Server closes session if missed |

---

## 3. JSON-RPC transport

All Diode RPC uses **JSON-RPC 2.0** over HTTPS POST or WebSocket text frames.

### 3.1 Request shape

```json
{"jsonrpc":"2.0","id":1,"method":"<method>","params":[...]}
```

- `id` must be unique per in-flight request on a WebSocket connection.
- Methods used by VPN clients: `dio_network` (HTTPS only), `dio_ticket`, `dio_wireguard_open`, `dio_wireguard_close`.

### 3.2 Success response

```json
{"jsonrpc":"2.0","id":1,"result":<value>}
```

`dio_ticket` and legacy `dio_wireguard_open` return `result: null`. Spec-compliant servers return a **session object** from `dio_wireguard_open` (§8).

### 3.3 Error response (nested)

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "error": {
    "code": -32001,
    "message": "too_low",
    "data": { ... }
  }
}
```

### 3.4 Error response (flat — some node versions)

Some Diode nodes merge errors at the top level (no `error` object):

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "code": -32001,
  "message": "too_low",
  "data": { ... }
}
```

Clients **must** handle both shapes.

### 3.5 Server notifications (no `id`)

Mid-session billing uses a JSON-RPC **notification**:

```json
{
  "jsonrpc": "2.0",
  "method": "dio_ticket_request",
  "params": {
    "usage": 420000,
    "fleet": "0xd5b1221fce90049fbfc917f28b8996a07fdfdea7"
  }
}
```

- `usage`: decimal integer — minimum `total_bytes` baseline the server expects.
- `fleet`: optional `0x`-prefixed fleet contract; client should use it in the next ticket if present.
- Client must submit a new `dio_ticket` within **20 seconds** or the server closes the session.

---

## 4. Server discovery (`dio_network`)

### 4.1 Request

```
POST https://prenet.diode.io:8443/
Content-Type: application/json

{"jsonrpc":"2.0","id":1,"method":"dio_network","params":[]}
```

### 4.2 Response

`result` is a JSON **array** of node entries. Each entry:

| Field | Type | Description |
|-------|------|-------------|
| `node_id` | string | Node wallet address (`0x` + 40 hex or 40 hex). **This is TicketV2 `server_id`.** |
| `node` | array | Server object (see §4.3) |

### 4.3 Server object array layout

The `node` field is a JSON array with positional fields:

| Index | Content |
|-------|---------|
| `1` | **Host** — public IP or hostname used for RPC and WireGuard |
| `5` | **Extra** — array of `[key, value]` pairs |

From index `5`, parse:

| Key | Use |
|-----|-----|
| `name` | Display name (e.g. `user@diode-us1`) |
| `features` | Feature flags string |

### 4.4 VPN-capable node filter

Include a node in the VPN server list only if **either**:

- `name` contains (case-insensitive) one of: `diode-eu1`, `diode-eu2`, `diode-us1`, `diode-us2`, `diode-as1`, `diode-as2`, **or**
- `features` contains `wg_exit`.

### 4.5 Caching

- Persist the full `dio_network` result locally.
- Refresh on app start and at most every **1 hour**.
- Render cached data immediately on cold start; refresh in background.

### 4.6 WebSocket routing rule (critical)

The WebSocket for `dio_ticket` / `dio_wireguard_*` **must** terminate on the **same exit node** whose wallet address equals `node_id` / TicketV2 `server_id`.

```
WebSocket URL = wss://{node.host}:8443/ws
```

The prenet gateway (`wss://prenet.diode.io:8443/ws`) is a fallback only when routing guarantees the same node handles both WebSocket RPC and WireGuard for that ticket.

---

## 5. Geolocation (optional UI)

For map / country grouping:

```
GET https://monitor.testnet.diode.io/ip/{node_host}
```

Example response:

```json
{
  "city": "Mountain View",
  "ip": "8.8.8.8",
  "latitude": 37.38,
  "longitude": -122.07
}
```

Cache geo results per `node_id` to avoid repeat lookups on refresh.

---

## 6. Device identity and persistent state

Each client installation maintains:

### 6.1 Ticket signing key (secp256k1)

- Generate a random 32-byte secp256k1 private key on first use.
- Store securely (Keychain, Credential Manager, encrypted prefs, etc.).
- Used only to sign TicketV2 device blobs.
- Derive Ethereum address: standard `ecrecover` address from the public key (same as web3j `Keys.getAddress`).

### 6.2 `local_address` (opaque client ID)

- Stable random string per install, e.g. `macos:{uuid}` or `windows:{uuid}`.
- Embedded in the ticket RLP and hashed in the device blob (§7.2).
- Not required to be an Ethereum address.

### 6.3 WireGuard keypair (per connection)

- Generate a fresh **X25519** keypair for each connect (or per session).
- **Private key:** base64 (32 bytes) — WireGuard `[Interface] PrivateKey`.
- **Public key:** 32-byte raw, **hex-encoded** (64 hex chars) — sent to `dio_wireguard_open`.
- Do not reuse the TicketV2 secp256k1 key for WireGuard.

---

## 7. TicketV2 authentication

TicketV2 is the sole authentication mechanism for VPN sessions. The client builds and signs it on-device; no server-issued JWT is required for the reference flow.

### 7.1 High-level fields

| Field | Source |
|-------|--------|
| `chain_id` | `1284` (Moonbeam) for production |
| `epoch` | Current chain epoch (§7.6) |
| `fleet_contract` | VPN fleet `0xd5b1221fce90049fbfc917f28b8996a07fdfdea7` |
| `server_id` | Selected node's `node_id` (20 bytes) |
| `total_connections` | `0` for VPN clients (reference app) |
| `total_bytes` | Byte allowance commitment (§10) |
| `local_address` | Install-stable string (§6.2) |
| `device_signature` | 65-byte ECDSA signature (§7.4) |

**Epoch validity on node:** `RemoteChain.epoch - 1 ≤ ticket.epoch ≤ RemoteChain.epoch`.

### 7.2 Device blob (what gets signed)

Concatenate **7 × 32-byte words** (ABI `bytes32` style, big-endian uint256 for integers):

| # | Field | Encoding |
|---|-------|----------|
| 1 | `chain_id` | `uint256` big-endian, 32 bytes |
| 2 | `epoch` | `uint256` big-endian, 32 bytes |
| 3 | `fleet_contract` | 20-byte address **left-padded** to 32 bytes (12 zero bytes + 20 address bytes) |
| 4 | `server_id` | 20-byte node wallet, left-padded to 32 bytes |
| 5 | `total_connections` | `uint256` BE, 32 bytes |
| 6 | `total_bytes` | `uint256` BE, 32 bytes |
| 7 | `local_address` | `SHA-256(UTF-8(local_address))` as 32 bytes |

**Important:** Diode uses **SHA-256** for the local-address hash in the device blob, not Keccak.

The node overwrites `server_id` in its parsed ticket struct with its own wallet, but **signature verification uses the blob you signed**, so `server_id` in the blob must match the node handling the WebSocket.

### 7.3 Signing algorithm

1. `digest = Keccak-256(device_blob)` (Ethereum SHA3 / `web3j Hash.sha3`).
2. ECDSA sign `digest` with secp256k1 private key.
3. **No EIP-191 prefix** — sign the raw 32-byte digest.
4. Wire format: **65 bytes** = `recovery_id` (0 or 1) ‖ `r` (32) ‖ `s` (32).
   - Map Ethereum `v` (27/28) to recovery id: `recId = v - 27`.

Reference: Elixir `Secp256k1.sign(priv, device_blob, :kec)`.

### 7.4 RLP encoding (wire format for `dio_ticket`)

RLP-encode a list of 8 items **in order**:

| Index | Content | RLP encoding |
|-------|---------|--------------|
| 0 | `"ticketv2"` | UTF-8 string |
| 1 | `chain_id` | unsigned integer, minimal big-endian (`0` → empty byte array) |
| 2 | `epoch` | unsigned integer |
| 3 | `fleet_contract` | 20 raw bytes |
| 4 | `total_connections` | unsigned integer |
| 5 | `total_bytes` | unsigned integer |
| 6 | `local_address` | UTF-8 bytes of the string |
| 7 | `device_signature` | 65 raw bytes |

RLP rules match Ethereum RLP (see reference `DiodeRlp.kt` in this repo).

### 7.5 JSON-RPC parameter

Hex-encode the RLP bytes with a mandatory **`0x` prefix**:

```
ticketHex = "0x" + hex(RLP_bytes)
```

Send:

```json
{"jsonrpc":"2.0","id":1,"method":"dio_ticket","params":["0x..."]}
```

The node decodes via `Base16.decode/1` — **without `0x` prefix will fail**.

### 7.6 Epoch calculation

**Production (Moonbeam):**

1. `POST https://rpc.api.moonbeam.network` with `eth_getBlockByNumber` for `"latest"` (or `eth_blockNumber` then fetch that block).
2. `epoch = block.timestamp / 2_592_000` (integer division).

`dio_network` stays on prenet; epoch comes from Moonbeam RPC, not from the exit node (unless you connect to a dev node on another chain).

**Per-node chain detection (dev / local):**

| Chain ID | Epoch rule |
|----------|------------|
| `1284` (Moonbeam) | `block.timestamp / 2_592_000` |
| `31337` (Anvil) | `block.timestamp / 2_592_000`; `server_id` from `eth_coinbase`; fleet `0x000…000` |
| `15` (legacy Diode L1) | `blockNumber / 40_320` |

Detect via `eth_chainId` on the node's HTTP RPC (`https://{host}:8443/`).

---

## 8. WebSocket session methods

Connect first, then call methods in order.

### 8.1 `dio_ticket`

**Params:** `[ticketHex]` — one element, `0x`-prefixed hex RLP.

**Success:**

```json
{"jsonrpc":"2.0","id":1,"result":null}
```

**Errors:** see §11.

Must succeed before `dio_wireguard_open`.

### 8.2 `dio_wireguard_open`

**Params:** `[publicKeyHex]` — client's WireGuard public key as **`0x` + 64 hex chars** (32 bytes).

**Success (spec v0.1.4+):**

```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "result": {
    "server_public_key": "<base64, 32-byte WG public key>",
    "endpoint_host": "203.0.113.10",
    "listen_port": 51820,
    "client_address": "10.77.0.3/32"
  }
}
```

| Field | Use |
|-------|-----|
| `server_public_key` | WireGuard `[Peer] PublicKey` (base64) |
| `endpoint_host` | UDP endpoint host for WireGuard |
| `listen_port` | UDP port (typically 51820) |
| `client_address` | Client tunnel IP CIDR (`[Interface] Address`) |

`result` may also be returned as a JSON string containing the object; parse both forms.

**Legacy servers** return `result: null` — clients should treat this as unsupported and surface a clear error.

### 8.3 `dio_wireguard_close`

**Params:** `[]` (empty array).

**Success:** `result: null`.

Call on user disconnect **before** closing the WebSocket. Also tear down the local WireGuard interface.

### 8.4 Keep WebSocket open

The reference client keeps the WebSocket connected for the entire VPN session to receive `dio_ticket_request` notifications and to call `dio_wireguard_close` on teardown.

---

## 9. WireGuard tunnel configuration

After successful `dio_wireguard_open`, configure WireGuard:

```ini
[Interface]
PrivateKey = <client private key, base64>
Address = <client_address from RPC>
DNS = 1.1.1.1
MTU = 1280

[Peer]
PublicKey = <server_public_key from RPC, base64>
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = <endpoint_host>:<listen_port>
```

### 9.1 Bring-up sequence

1. `dio_ticket` → OK
2. Generate X25519 keypair
3. `dio_wireguard_open(clientPublicKeyHex)` → `WireGuardSessionInfo`
4. **(Recommended)** Run a WireGuard Noise IKpsk2 handshake probe to `endpoint_host:listen_port` before binding the OS tunnel — fails fast if the node is misconfigured.
5. Apply config and route all traffic through the tunnel (platform VPN API).

### 9.2 WireGuard public key encoding

| Context | Format |
|---------|--------|
| `dio_wireguard_open` RPC | Hex, 32 bytes → 64 hex digits, **`0x` prefix required** |
| WireGuard config file | Base64 (standard WireGuard encoding) |

### 9.3 Server prerequisites

Exit nodes require `WIREGUARD_ENABLED=1`, a non-zero listen port, and kernel WireGuard interface up. If not ready, clients see `wireguard not enabled` or `wireguard error` (§11).

---

## 10. Ticket commitment, scoring, and refresh

The server tracks per-device usage and rejects tickets whose commitment is too low.

### 10.1 Ticket score

```
score = total_connections * 1024 + total_bytes
```

A new ticket must have **strictly higher** score than the server's stored summary when refreshing.

### 10.2 Initial connect

Submit `total_bytes = 4096` (reference default), `total_connections = 0`.

### 10.3 `too_low` synchronous rejection

When `dio_ticket` fails with `message: "too_low"`:

```json
{
  "code": -32001,
  "message": "too_low",
  "data": {
    "usage": "f4240",
    "summary": {
      "chain_id": "...",
      "epoch": "...",
      "total_connections": "...",
      "total_bytes": "...",
      "local_address": "...",
      "device_signature": "..."
    }
  }
}
```

- `usage`: hex integer (optional `0x`) — minimum `total_bytes` = `max(stored_ticket.total_bytes, device_usage)`.
- `summary`: server's reference ticket fields (hex-encoded integers in `total_connections` / `total_bytes`).

**Client algorithm** (`minimumTotalBytesForRetry`):

```
headroom = 65536
maxStep = 50_000_000
summaryScore = summary.total_connections * 1024 + summary.total_bytes
minFromUsage = usage + headroom
minFromScore = summaryScore + 1
minCover = max(minFromUsage, minFromScore)
target = max(minCover, lastSignedBytes + headroom)
if (target - lastSignedBytes > maxStep):
    target = lastSignedBytes + maxStep
    if (target < minCover): target = minCover
```

Rebuild ticket with new `total_bytes = target`, re-sign, retry `dio_ticket`. Repeat up to **3** attempts per burst.

### 10.4 `dio_ticket_request` (async)

Same semantics as `too_low`: raise `total_bytes` and call `dio_ticket` again within **20 seconds**.

When both a notification and a prior `too_low` are present, use the **higher** of notification `usage` and `data.usage`.

If `params.fleet` is set, update `fleet_contract` in the next ticket.

### 10.5 Mid-session state to retain

While connected, keep:

- WebSocket connection
- Ticket signing parameters (`chain_id`, `epoch`, `server_id`, `fleet`, `local_address`)
- Last successfully submitted `total_bytes`
- Active WireGuard session (until reconnect)

On refresh success, update `lastSignedTotalBytes`. On refresh failure, reconnect (§12.4).

---

## 11. Error codes and client mapping

| Condition | Code / signal | Client action |
|-----------|---------------|---------------|
| No ticket / not authenticated | `-32000`, `"not authenticated"` | Connect + `dio_ticket` first |
| Invalid / expired ticket | `-32001` / `-32002` (not `too_low`) | Rebuild ticket (check epoch, signature, `server_id`) |
| Commitment too low | `-32001`, `"too_low"` + `data` | Retry with higher `total_bytes` (§10) |
| Invalid WireGuard public key | RPC error / `-32602` | Regenerate X25519 keypair |
| WireGuard disabled on node | message contains `"not enabled"`, often HTTP 503 | Pick another node; surface error |
| WireGuard kernel error | message contains `"wireguard error"`, often HTTP 500 | Retry or reconnect |
| WebSocket closed mid-session | transport error | Auto-reconnect (§12.4) |
| Missed `dio_ticket_request` deadline | server closes WS (~20s) | Reconnect with fresh ticket |

Show clear, user-facing messages for all failure modes.

---

## 12. Connection lifecycle (reference behavior)

### 12.1 Connect

```
1. If another session is active → disconnect first
2. Resolve chain context (Moonbeam epoch OR per-node eth_chainId)
3. Build ActiveSessionParams:
     - server_id = node.node_id (20 bytes)
     - fleet = VPN fleet contract
     - local_address, signing key from secure store
4. WebSocket connect to wss://{node.host}:8443/ws
5. dio_ticket (with too_low retries)
6. Generate WireGuard keypair
7. dio_wireguard_open(publicKeyHex)
8. WireGuard preflight handshake (optional but recommended)
9. Bring up OS tunnel with session-derived config
10. Keep WebSocket open; register notification handler
```

Single connect retry after **350 ms** on transient failure is used in the reference client.

### 12.2 Connected

- Monitor WireGuard handshake age; if **> 180 seconds**, trigger reconnect.
- On `Tunnel.State.DOWN` (platform-specific), trigger reconnect.
- Handle `dio_ticket_request` on the WebSocket thread / async dispatcher.

### 12.3 Disconnect (user-initiated)

```
1. Cancel reconnect / health watch jobs
2. Set UI state to idle
3. Tear down WireGuard tunnel
4. dio_wireguard_close() over open WebSocket
5. WebSocket close
6. Clear session state
```

Order: tunnel down may happen before or after `dio_wireguard_close`; reference client tears down tunnel then closes RPC.

### 12.4 Auto-reconnect

Triggered on:

- WebSocket drop while connected
- `dio_ticket` refresh failure
- WireGuard stale handshake (> 180s)
- Tunnel interface down

Sequence:

1. Tear down tunnel and RPC
2. Try same-country nodes (never-failed first, then oldest failure)
3. Full connect handshake per node until success or exhaustion

---

## 13. Entitlement and fleet membership (product layer)

The WireGuard protocol does not include app-store billing. Production Diode VPN apps typically:

1. **Gate connect** on an active subscription or license (platform-specific).
2. **Register the device signing key** with Diode Console so the fleet contract recognizes the device:

```
POST https://console.diode.io/api/v1/rpc
Authorization: Bearer <org_api_key>
Content-Type: application/json

{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "fleet.member.add",
  "params": {
    "fleet_id": "<console fleet UUID>",
    "address": "0x<ethereum address of ticket signing key>",
    "label": "My VPN Client 1.0.0"
  }
}
```

The ticket's `fleet_contract` (`0xd5b122…`) must match a fleet where the device address is an allowed member. A backend may alternatively issue tickets or override fleet policy.

Reference Android app: $29.99/year Google Play subscription + on-device TicketV2 signing after entitlement check.

---

## 14. TLS and certificate validation

Exit nodes are often reached by **numeric IP** from `dio_network`, while TLS certificates may be issued for DNS names. Clients connecting to `wss://203.0.113.10:8443/ws` can fail standard hostname verification.

The reference Android client disables certificate verification when the WebSocket host is a literal IP address. Production clients should either:

- Use certificate pinning with IP-specific trust stores, **or**
- Terminate TLS on a hostname that matches the certificate and document that routing, **or**
- Accept the MitM risk only for IP-literal endpoints (document clearly).

HTTPS calls to `prenet.diode.io` and Moonbeam RPC use normal PKI validation (with optional debug overrides).

---

## 15. Platform implementation checklist

| Component | Requirement |
|-----------|-------------|
| HTTP client | `dio_network`, Moonbeam `eth_getBlockByNumber`, geo API |
| WebSocket client | Persistent session, JSON-RPC request/response correlation, notification dispatch |
| Crypto | secp256k1 + Keccak-256 (tickets), SHA-256 (local_address hash), RLP encode |
| Crypto | X25519 keygen (WireGuard) |
| VPN | WireGuard userspace or kernel driver + full-tunnel routing |
| Storage | Secure persistence of ticket signing key + `local_address` |
| Threading | All network/crypto off UI thread; serialize ticket refresh on RPC connection |

---

## 16. Verification and test vectors

### 16.1 Ticket signature self-test

Given a fixed private key and `TicketV2.Params`, verify:

1. `device_blob` length = 224 bytes (7 × 32).
2. `Keccak256(device_blob)` signs to an address matching the private key (ECDSA recover).
3. RLP + `0x` hex round-trips.

See `TicketV2SignatureSelfTest` in this repository.

### 16.2 Local integration test

Against a local node on `localhost:8545`:

1. `dio_ticket` succeeds
2. `dio_wireguard_open` returns session object with non-empty `server_public_key`, `endpoint_host`, `client_address`
3. WireGuard Noise handshake completes over UDP
4. `dio_wireguard_close` succeeds

See `DiodeRpcLocalIntegrationTest` and `WireGuardTunnelIntegrationTest`.

### 16.3 Example `dio_wireguard_open` result

```json
{
  "server_public_key": "YSBzZWN1cmUgd2lyZWd1YXJkIHB1YmxpYyBrZXkgYmFzZTY0IHBhZGRlZA==",
  "endpoint_host": "203.0.113.10",
  "listen_port": 51820,
  "client_address": "10.77.0.3/32"
}
```

---

## 17. Reference implementation map (this repository)

| Topic | File |
|-------|------|
| TicketV2 build/sign/RLP | `app/src/main/kotlin/io/diode/vpn/ticket/TicketV2.kt` |
| RLP | `app/src/main/kotlin/io/diode/vpn/crypto/DiodeRlp.kt` |
| Device key storage | `app/src/main/kotlin/io/diode/vpn/crypto/DeviceKeyStore.kt` |
| WebSocket RPC | `app/src/main/kotlin/io/diode/vpn/network/DiodeRpcClient.kt` |
| Node list parse | `app/src/main/kotlin/io/diode/vpn/network/VpnNode.kt` |
| Connect lifecycle | `app/src/main/kotlin/io/diode/vpn/ui/ServerListViewModel.kt` |
| Ticket refresh math | `app/src/main/kotlin/io/diode/vpn/ticket/TicketCommitment.kt` |
| WG config | `app/src/main/kotlin/io/diode/vpn/vpn/WireGuardConfigBuilder.kt` |
| Constants | `app/src/main/kotlin/io/diode/vpn/network/NetworkConfig.kt` |

---

## 18. Version history

| Version | Notes |
|---------|-------|
| 1.0 | Initial extract from DiodeVPN Android client (TicketV2, spec v0.1.4 `dio_wireguard_open` session object, mid-session `dio_ticket_request`, Moonbeam epoch) |

---

## Appendix A: Complete connect example (pseudocode)

```text
// --- Discovery (on app start) ---
nodes = POST prenet dio_network → parse & filter wg_exit nodes
cache(nodes)
for each new node: geo = GET monitor/ip/{host}

// --- Connect (user picks node) ---
assert userHasEntitlement()
epoch = moonbeam.latestBlock.timestamp / 2592000
priv = loadOrCreateSecp256k1Key()
localAddr = loadOrCreateLocalAddress()
serverId = hexDecode(node.node_id)  // 20 bytes

ticket = signTicketV2(
  chainId=1284, epoch=epoch,
  fleet=0xd5b122..., serverId=serverId,
  totalConnections=0, totalBytes=4096,
  localAddress=localAddr, key=priv)

ws = connect("wss://" + node.host + ":8443/ws")
rpc(ws, "dio_ticket", [ticket])  // retry on too_low up to 3×

wg = generateX25519()
session = rpc(ws, "dio_wireguard_open", ["0x" + hex(wg.publicKey)])

config = wireguardConfig(wg.privateKeyB64, session)
preflightHandshake(session.endpoint, wg, session.serverPublicKey)
bringUpTunnel(config)

onNotification("dio_ticket_request", (usage, fleet) => {
  newBytes = minimumTotalBytesForRetry(usage, lastSignedBytes, summary...)
  ticket2 = signTicketV2(..., totalBytes=newBytes)
  rpc(ws, "dio_ticket", [ticket2])
})

onDisconnect(() => {
  tearDownTunnel()
  rpc(ws, "dio_wireguard_close", [])
  ws.close()
})
```

---

## Appendix B: RLP unsigned integer examples

| Value | RLP bytes (hex) |
|-------|-----------------|
| `0` | *(empty)* |
| `1` | `01` |
| `1284` | `0504` |
| `4096` | `820010` |

Strings and byte arrays use standard RLP string encoding; single bytes `< 0x80` encode as themselves.
