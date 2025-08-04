# ExperHive Smart Contract

ExperHive is a decentralized skills, reputation, and achievement platform built on Clarity. It enables users to build verifiable skill profiles, earn endorsements, participate in challenges, and receive NFT certificates for achievements.

---

## What's New in v2.2

**Security Framework Added!**

- **Role-Based Access Control:**  
  Fine-grained roles (`Admin`, `Verifier`, `Moderator`, `User`) restrict sensitive actions.
- **Rate Limiting:**  
  Prevents abuse by limiting user and principal actions per time window.
- **Reentrancy Protection:**  
  Guards all state-changing functions against reentrancy attacks.
- **Pause & Emergency Mode:**  
  Admins can pause/unpause the contract and activate emergency mode for critical incidents.
- **Multi-Signature Operations:**  
  Critical actions require multi-signature approval from multiple admins.
- **Security Audit Trail:**  
  All sensitive actions are logged for auditability.
- **Comprehensive Input Validation:**  
  All inputs are strictly validated and sanitized.
- **Expanded Error Handling:**  
  New error codes for security and validation failures.
- **Security Wrappers:**  
  All public functions are protected by security checks.

---

## Features

- **Skills & Endorsements**
  - Add skills to your profile
  - Endorse other users' skills (with expiry)
  - Rate skills (1-5)
  - Revoke endorsements

- **Skill-Based Challenges**
  - Create skill challenges with STX rewards
  - Participate and submit challenge entries
  - Review submissions and award scores
  - Complete challenges and mint NFTs for winners

- **Reputation System**
  - Dynamic reputation scoring based on endorsements, ratings, challenge participation, and accuracy
  - Reputation decays over time if inactive
  - Fraud flags penalize scores

- **Skill NFTs & Achievements**
  - Mint NFTs for skill mastery, challenge wins, and top endorsers
  - Transfer NFTs between users

- **Verification & Experience**
  - Authorized verifiers can verify skills and experience
  - Add verified skills and experience levels

- **Security & Admin Controls**
  - Grant/revoke roles
  - Pause/unpause contract and activate/deactivate emergency mode
  - Multi-signature approval for critical operations
  - Security event logging and audit trail

---

## Data Structures

- **Maps**
  - `skills`: User skills
  - `endorsements`: Skill endorsements
  - `skill-challenges`: Challenge details
  - `challenge-participants`: Challenge submissions
  - `user-reputation`: Reputation scores
  - `skill-nfts`: NFT certificates
  - `user-roles`, `pending-operations`, `security-events`: Security and admin controls
  - ...and more

- **Constants**
  - Error codes, contract owner, limits, expiry blocks, security parameters

---

## Key Functions

### Skill Management

```clarity
(contract-call? .experhive add-skill "JavaScript")
(contract-call? .experhive endorse 'SP1ABC...DEF "JavaScript")
(contract-call? .experhive rate-skill 'SP1ABC...DEF "JavaScript" u5)
(contract-call? .experhive revoke-endorsement 'SP1ABC...DEF "JavaScript")
```

### Challenge System

```clarity
(contract-call? .experhive create-challenge "JavaScript" "Build a DeFi App" "Create a decentralized exchange" u3 u1000000 u1440 u10)
(contract-call? .experhive participate-in-challenge u1 "ipfs://QmABC123...")
(contract-call? .experhive review-challenge-submission u1 'SP1ABC...DEF u95 "Great work!")
(contract-call? .experhive complete-challenge u1)
```

### Reputation & Verification

```clarity
(contract-call? .experhive get-user-reputation-score 'SP1ABC...DEF)
(contract-call? .experhive add-verified-skill 'SP1ABC...DEF "JavaScript" "Web Development")
(contract-call? .experhive verify-experience 'SP1ABC...DEF "JavaScript" true)
```

### NFTs & Achievements

```clarity
(contract-call? .experhive mint-skill-nft 'SP1ABC...DEF "JavaScript" "Expert" "skill-mastery" "ipfs://metadata-uri")
(contract-call? .experhive transfer-nft u1 'SP2XYZ...ABC)
```

### Security & Admin

```clarity
(contract-call? .experhive emergency-pause)
(contract-call? .experhive emergency-unpause)
(contract-call? .experhive activate-emergency-mode)
(contract-call? .experhive deactivate-emergency-mode)
(contract-call? .experhive grant-role 'SP1ADMIN... "u1")
(contract-call? .experhive create-multisig-operation "update-contract" 'SP1ADMIN... u1000000 u3)
(contract-call? .experhive approve-multisig-operation u1)
```

---

## Read-Only Queries

- `get-challenge-details`
- `get-challenge-participation`
- `get-nft-details`
- `get-user-nfts`
- `get-skill-details`
- `get-skill-category`
- `get-verified-experience`
- `get-user-role`
- `is-contract-paused`
- `is-emergency-mode-active`
- `get-security-event`

---

## Security & Validation

- Input validation for strings, numbers, principals
- Only contract owner or authorized verifiers can perform sensitive actions
- Reputation and NFT logic includes fraud and decay handling
- All state-changing functions protected by security checks and audit logging

---

## Example Usage

```clarity
;; Add a skill
(contract-call? .experhive add-skill "JavaScript")

;; Endorse a skill
(contract-call? .experhive endorse 'SP1ABC...DEF "JavaScript")

;; Create a challenge
(contract-call? .experhive create-challenge "JavaScript" "Build a DeFi App" "Create a decentralized exchange" u3 u1000000 u1440 u10)

;; Mint an NFT
(contract-call? .experhive mint-skill-nft 'SP1ABC...DEF "JavaScript" "Expert" "skill-mastery" "ipfs://metadata-uri")

;; Pause contract (admin only)
(contract-call? .experhive emergency-pause)
```

---

## License

MIT License

---

**ExperHive** empowers users to build trusted, verifiable skill profiles and achievements on-chain, now with enhanced security and control features.
