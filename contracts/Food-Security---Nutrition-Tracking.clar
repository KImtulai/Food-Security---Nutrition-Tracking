(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-insufficient-balance (err u104))
(define-constant err-unauthorized (err u105))

(define-fungible-token nutrition-token)

(define-data-var next-food-id uint u1)
(define-data-var total-donations uint u0)
(define-data-var token-reward-per-donation uint u100)

(define-map food-items
  uint
  {
    qr-code: (string-ascii 64),
    name: (string-ascii 50),
    producer: principal,
    production-date: uint,
    expiry-date: uint,
    calories: uint,
    protein: uint,
    carbs: uint,
    fat: uint,
    fiber: uint,
    sodium: uint,
    is-organic: bool,
    is-donated: bool,
    recipient: (optional principal)
  })

(define-map supply-chain-events
  {food-id: uint, event-id: uint}
  {
    event-type: (string-ascii 20),
    location: (string-ascii 100),
    timestamp: uint,
    handler: principal,
    temperature: (optional int),
    notes: (string-ascii 200)
  })

(define-map food-event-count uint uint)

(define-map producer-stats
  principal
  {
    total-registered: uint,
    total-donated: uint,
    reputation-score: uint,
    total-feedback: uint
  })

(define-map donation-recipients
  principal
  {
    total-received: uint,
    last-donation-date: uint,
    verification-status: bool
  })

(define-map food-feedback {food-id: uint, rater: principal} uint)

(define-read-only (get-food-item (food-id uint))
  (map-get? food-items food-id))

(define-read-only (get-supply-chain-event (food-id uint) (event-id uint))
  (map-get? supply-chain-events {food-id: food-id, event-id: event-id}))

(define-read-only (get-food-event-count (food-id uint))
  (default-to u0 (map-get? food-event-count food-id)))

(define-read-only (get-producer-stats (producer principal))
  (default-to
    {total-registered: u0, total-donated: u0, reputation-score: u0, total-feedback: u0}
    (map-get? producer-stats producer)))

(define-read-only (get-donation-recipient (recipient principal))
  (map-get? donation-recipients recipient))

(define-read-only (get-total-donations)
  (var-get total-donations))

(define-read-only (get-token-balance (account principal))
  (ft-get-balance nutrition-token account))

(define-read-only (get-token-supply)
  (ft-get-supply nutrition-token))

(define-public (register-food-item 
  (qr-code (string-ascii 64))
  (name (string-ascii 50))
  (production-date uint)
  (expiry-date uint)
  (calories uint)
  (protein uint)
  (carbs uint)
  (fat uint)
  (fiber uint)
  (sodium uint)
  (is-organic bool))
  (let ((food-id (var-get next-food-id)))
    (map-set food-items food-id {
      qr-code: qr-code,
      name: name,
      producer: tx-sender,
      production-date: production-date,
      expiry-date: expiry-date,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      sodium: sodium,
      is-organic: is-organic,
      is-donated: false,
      recipient: none
    })
    (map-set food-event-count food-id u0)
    (var-set next-food-id (+ food-id u1))
    (update-producer-stats tx-sender u1 u0 u0)
    (ok food-id)))

(define-public (add-supply-chain-event
  (food-id uint)
  (event-type (string-ascii 20))
  (location (string-ascii 100))
  (temperature (optional int))
  (notes (string-ascii 200)))
  (let ((event-count (get-food-event-count food-id))
        (food-item (unwrap! (get-food-item food-id) err-not-found)))
    (map-set supply-chain-events 
      {food-id: food-id, event-id: event-count}
      {
        event-type: event-type,
        location: location,
        timestamp: stacks-block-height,
        handler: tx-sender,
        temperature: temperature,
        notes: notes
      })
    (map-set food-event-count food-id (+ event-count u1))
    (ok event-count)))

(define-public (donate-food-item (food-id uint) (recipient principal))
  (let ((food-item (unwrap! (get-food-item food-id) err-not-found)))
    (asserts! (is-eq (get producer food-item) tx-sender) err-unauthorized)
    (asserts! (not (get is-donated food-item)) err-already-exists)
    (map-set food-items food-id (merge food-item {is-donated: true, recipient: (some recipient)}))
    (try! (ft-mint? nutrition-token (var-get token-reward-per-donation) tx-sender))
    (var-set total-donations (+ (var-get total-donations) u1))
    (update-producer-stats tx-sender u0 u1 u0)
    (update-donation-recipient recipient)
    (ok true)))

(define-public (verify-donation-recipient (recipient principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (let ((current-data (default-to 
                          {total-received: u0, last-donation-date: u0, verification-status: false}
                          (get-donation-recipient recipient))))
      (map-set donation-recipients recipient 
        (merge current-data {verification-status: true}))
      (ok true))))

(define-public (set-token-reward (new-reward uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set token-reward-per-donation new-reward)
    (ok true)))

(define-public (transfer-tokens (amount uint) (recipient principal))
  (ft-transfer? nutrition-token amount tx-sender recipient))

(define-private (update-producer-stats (producer principal) (registered-increment uint) (donated-increment uint) (feedback-increment uint))
  (let ((current-stats (get-producer-stats producer)))
    (map-set producer-stats producer {
      total-registered: (+ (get total-registered current-stats) registered-increment),
      total-donated: (+ (get total-donated current-stats) donated-increment),
      reputation-score: (+ (get reputation-score current-stats)
                          (+ registered-increment (+ (* donated-increment u5) (* feedback-increment u2)))),
      total-feedback: (+ (get total-feedback current-stats) feedback-increment)
    })
    true))

(define-private (update-donation-recipient (recipient principal))
  (let ((current-data (default-to 
                        {total-received: u0, last-donation-date: u0, verification-status: false}
                        (get-donation-recipient recipient))))
    (map-set donation-recipients recipient {
      total-received: (+ (get total-received current-data) u1),
      last-donation-date: stacks-block-height,
      verification-status: (get verification-status current-data)
    })
    true))

(define-public (get-nutrition-score (food-id uint))
  (let ((food-item (unwrap! (get-food-item food-id) err-not-found)))
    (ok (+ 
      (if (get is-organic food-item) u20 u0)
      (if (> (get fiber food-item) u5) u15 u0)
      (if (< (get sodium food-item) u1000) u10 u0)
      (if (> (get protein food-item) u10) u10 u0)
      u10))))

(define-public (batch-verify-supply-chain (food-ids (list 10 uint)))
  (ok (map get-food-item food-ids)))

(define-public (emergency-recall (food-id uint) (reason (string-ascii 200)))
  (let ((food-item (unwrap! (get-food-item food-id) err-not-found)))
    (asserts! (or (is-eq tx-sender contract-owner) 
                  (is-eq tx-sender (get producer food-item))) err-unauthorized)
    (try! (add-supply-chain-event food-id "RECALL" "EMERGENCY" none reason))
    (ok true)))

(define-public (submit-feedback (food-id uint) (rating uint))
  (let ((food-item (unwrap! (get-food-item food-id) err-not-found)))
    (asserts! (and (>= rating u1) (<= rating u5)) err-invalid-amount)
    (asserts! (is-some (get recipient food-item)) err-unauthorized)
    (asserts! (is-eq tx-sender (unwrap-panic (get recipient food-item))) err-unauthorized)
    (map-set food-feedback {food-id: food-id, rater: tx-sender} rating)
    (update-producer-stats (get producer food-item) u0 u0 rating)
    (ok true)))

(define-public (batch-register-food-items (items (list 10 {qr-code: (string-ascii 64), name: (string-ascii 50), production-date: uint, expiry-date: uint, calories: uint, protein: uint, carbs: uint, fat: uint, fiber: uint, sodium: uint, is-organic: bool})))
  (ok (map register-single-item items)))

(define-private (register-single-item (item {qr-code: (string-ascii 64), name: (string-ascii 50), production-date: uint, expiry-date: uint, calories: uint, protein: uint, carbs: uint, fat: uint, fiber: uint, sodium: uint, is-organic: bool}))
  (let ((food-id (var-get next-food-id)))
    (map-set food-items food-id {
      qr-code: (get qr-code item),
      name: (get name item),
      producer: tx-sender,
      production-date: (get production-date item),
      expiry-date: (get expiry-date item),
      calories: (get calories item),
      protein: (get protein item),
      carbs: (get carbs item),
      fat: (get fat item),
      fiber: (get fiber item),
      sodium: (get sodium item),
      is-organic: (get is-organic item),
      is-donated: false,
      recipient: none
    })
    (map-set food-event-count food-id u0)
    (var-set next-food-id (+ food-id u1))
    (update-producer-stats tx-sender u1 u0 u0)
    food-id))

(define-public (calculate-meal-nutrition (food-ids (list 10 uint)))
  (let ((total-calories u0)
        (total-protein u0)
        (total-carbs u0)
        (total-fat u0)
        (total-fiber u0)
        (total-sodium u0))
    (ok (fold accumulate-nutrition food-ids {calories: total-calories, protein: total-protein, carbs: total-carbs, fat: total-fat, fiber: total-fiber, sodium: total-sodium}))))

(define-private (accumulate-nutrition (food-id uint) (acc {calories: uint, protein: uint, carbs: uint, fat: uint, fiber: uint, sodium: uint}))
  (let ((food-item (unwrap! (get-food-item food-id) acc)))
    {
      calories: (+ (get calories acc) (get calories food-item)),
      protein: (+ (get protein acc) (get protein food-item)),
      carbs: (+ (get carbs acc) (get carbs food-item)),
      fat: (+ (get fat acc) (get fat food-item)),
      fiber: (+ (get fiber acc) (get fiber food-item)),
      sodium: (+ (get sodium acc) (get sodium food-item))
    }))

(define-read-only (is-food-expiring-soon (food-id uint))
  (let ((food-item (unwrap! (get-food-item food-id) false)))
    (if (> (get expiry-date food-item) stacks-block-height)
      (< (- (get expiry-date food-item) stacks-block-height) u7)
      false)))

