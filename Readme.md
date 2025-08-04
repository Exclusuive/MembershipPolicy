# 🧱 Exclusuive Move Contracts

This repository contains the core smart contracts for the **Exclusuive** platform, built using the [Sui Move language](https://docs.sui.io/learn/move).

The contracts manage community-based membership systems, items, attributes, and ticketing — all fully on-chain and modularly structured.

---

## 📦 Modules Overview

### `community.move`

- Handles:
  - `Community` object creation
  - Registration of types (`MembershipType`, `ItemType`, `PartType`, `AttributeType`, `TicketType`)
  - Dynamic field mapping between types

### `membership.move`

- Handles:
  - Minting `Membership` objects
  - Attaching/removing `Item` and `Attribute` objects to `Membership`s
  - Replacement logic with ownership transfer

---

## 🚀 How to Use

### 🛠 Deploy

```bash
sui client publish --gas-budget 100000000
```

### 🧪 Testing

All test cases are written as Shell Scripts and located in the test/ folder. These scripts simulate full workflows such as creating a community, registering types, minting memberships, and attaching items or attributes.

📁 Folder Structure
test/
├── 0_community_setup.sh
├── 1_equip_items.sh

Make sure the sui CLI is installed and you are connected to a localnet or testnet environment with enough gas.

```bash
cd test
bash 0_community_setup.sh
bash 1_equip_items.sh
bash 2_attribute_attach.sh
bash 3_ticket_reward.sh
```
