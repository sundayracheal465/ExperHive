# ExperHive Smart Contract

ExperHive is a decentralized skills, reputation, and achievement platform built on Clarity. It enables users to build verifiable skill profiles, earn endorsements, participate in challenges, and receive NFT certificates for achievements.

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

---

## Data Structures

- **Maps**
  - `skills`: User skills
  - `endorsements`: Skill endorsements
  - `skill-challenges`: Challenge details
  - `challenge-participants`: Challenge submissions
  - `user-reputation`: Reputation scores
  - `skill-nfts`: NFT certificates
  - ...and more

- **Constants**
  - Error codes, contract owner, limits, expiry blocks

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

---

## Read-Only Queries

- `get-challenge-details`
- `get-challenge-participation`
- `get-nft-details`
- `get-user-nfts`
- `get-skill-details`
- `get-skill-category`
- `get-verified-experience`

---

## Security & Validation

- Input validation for strings, numbers, principals
- Only contract owner or authorized verifiers can perform sensitive actions
- Reputation and NFT logic includes fraud and decay handling

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
```

---

## License

MIT License

---

**ExperHive** empowers users to build trusted, verifiable skill profiles and achievements on-chain.
