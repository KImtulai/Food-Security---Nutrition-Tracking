# 🍎 Food Security & Nutrition Tracking Smart Contract

> 🌍 **Fighting malnutrition globally through blockchain transparency**

A comprehensive Clarity smart contract that creates an immutable ledger for food production, distribution, and nutrition verification. This MVP enables food traceability through QR codes, stores nutritional data on-chain, and incentivizes food donation programs with token rewards.

## 🚀 Key Features

### 📱 QR Code Food Tracking
- Unique QR codes for every food item
- Immutable food registration with comprehensive nutritional data
- Complete supply chain event logging

### 🥗 Nutritional Data Storage
- Calories, protein, carbs, fat, fiber, and sodium tracking
- Organic certification status
- Automated nutrition scoring system
- Tamper-proof nutritional information

### 🎁 Token Incentive Program
- Earn **Nutrition Tokens** for food donations
- Reputation scoring for producers
- Verified recipient system
- Emergency recall capabilities

### 📦 Batch Food Registration
```clarity
(batch-register-food-items items)
```
Register multiple food items in a single transaction for improved efficiency and reduced gas costs.

## 📋 Smart Contract Functions

### 🍯 Food Item Management
```clarity
(register-food-item qr-code name production-date expiry-date calories protein carbs fat fiber sodium is-organic)
```
Register a new food item with complete nutritional information.

### 🚚 Supply Chain Tracking
```clarity
(add-supply-chain-event food-id event-type location temperature notes)
```
Add supply chain events (production, transport, storage, retail).

### 💝 Donation System
```clarity
(donate-food-item food-id recipient)
```
Donate food items and earn nutrition tokens as rewards.

### 🔍 Verification & Queries
```clarity
(get-food-item food-id)
(get-nutrition-score food-id)
(get-producer-stats producer)
```

## 🛠️ Usage Instructions

### 1️⃣ Setup Clarinet Project
```bash
clarinet new food-security-tracking
cd food-security-tracking
```

### 2️⃣ Deploy Contract
```bash
clarinet deploy
```

### 3️⃣ Register Food Items
```bash
clarinet console
(contract-call? .Food-Security---Nutrition-Tracking register-food-item 
  "QR123456789" 
  "Organic Apples" 
  u1640000000 
  u1650000000 
  u80 u0 u21 u0 u4 u2 true)
```

### 4️⃣ Track Supply Chain
```bash
(contract-call? .Food-Security---Nutrition-Tracking add-supply-chain-event 
  u1 
  "HARVEST" 
  "Farm Location XYZ" 
  (some 4) 
  "Fresh harvest from organic farm")
```

### 5️⃣ Donate Food & Earn Tokens
```bash
(contract-call? .Food-Security---Nutrition-Tracking donate-food-item 
  u1 
  'ST1DONATION_RECIPIENT_ADDRESS)
```

## 🎯 Core Data Structures

### 🍊 Food Items
- **QR Code**: Unique identifier (64 characters)
- **Nutritional Info**: Calories, macronutrients, micronutrients
- **Dates**: Production and expiry timestamps
- **Status**: Organic certification, donation status

### 📦 Supply Chain Events
- **Event Types**: HARVEST, TRANSPORT, STORAGE, RETAIL, RECALL
- **Location**: GPS coordinates or address
- **Temperature**: Cold chain monitoring
- **Handler**: Responsible party at each step

### 🏆 Producer Stats
- **Total Registered**: Number of items registered
- **Total Donated**: Donation count
- **Reputation Score**: Weighted scoring system

## 🏅 Token Economics

- **Base Reward**: 100 tokens per donation
- **Reputation Bonus**: +5 tokens per donation to reputation score
- **Token Transfer**: P2P token transfers enabled
- **Supply Tracking**: Total token supply monitoring

## 🔒 Security Features

- **Owner Controls**: Contract owner emergency functions
- **Authorization**: Producer-only food item management
- **Verification**: Recipient verification system
- **Emergency Recall**: Immediate product recall capabilities

## 🧪 Testing

```bash
### 🏭 Bulk Operations
- Streamlined batch food item registration
- Reduced transaction costs for large-scale producers
- Enhanced scalability for food supply chains

npm install
npm test
```

Run comprehensive TypeScript tests for all contract functions.

## 🌟 Use Cases

### 🏪 Retail & Distribution
- Track food from farm to shelf
- Verify nutritional claims
- Monitor cold chain compliance
- Enable consumer transparency

### 🤝 Food Donation Programs
- Incentivize food donations with tokens
- Track donated food distribution
- 📦 Batch registration efficiency gains
- Verify recipient organizations
- Prevent food waste

### 🏥 Public Health
- Monitor nutrition in communities
- Track foodborne illness sources
- Verify organic certifications
- Support dietary recommendations

## 📊 Data Analytics

Track key metrics:
- 📈 Total food items registered
- 🎁 Total donations completed
- 🪙 Token distribution
- ⭐ Producer reputation scores
- 🌡️ Cold chain compliance rates

---

**Built with ❤️ on Stacks blockchain using Clarity smart contracts**

🔗 **Contract Address**: [Deploy to get address]  
📚 **Documentation**: [Stacks Documentation](https://docs.stacks.co)  
🛠️ **Built With**: [Clarinet](https://github.com/hirosystems/clarinet)
