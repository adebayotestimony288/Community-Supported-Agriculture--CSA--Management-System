;; CSA Members Contract
;; Manages member registration, subscriptions, and payments

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-MEMBER-EXISTS (err u101))
(define-constant ERR-MEMBER-NOT-FOUND (err u102))
(define-constant ERR-INVALID-TIER (err u103))
(define-constant ERR-INSUFFICIENT-PAYMENT (err u104))
(define-constant ERR-INVALID-STATUS (err u105))

;; Data Variables
(define-data-var next-member-id uint u1)
(define-data-var total-members uint u0)

;; Data Maps
(define-map members
  { member-id: uint }
  {
    wallet-address: principal,
    subscription-tier: (string-ascii 20),
    status: (string-ascii 20),
    join-date: uint,
    payment-due: uint,
    total-paid: uint,
    pickup-location: (string-ascii 100)
  }
)

(define-map member-by-address
  { wallet-address: principal }
  { member-id: uint }
)

(define-map subscription-prices
  { tier: (string-ascii 20) }
  { price: uint }
)

;; Initialize subscription tiers and prices
(map-set subscription-prices { tier: "basic" } { price: u500000 })
(map-set subscription-prices { tier: "premium" } { price: u800000 })
(map-set subscription-prices { tier: "family" } { price: u1200000 })

;; Public Functions

;; Register a new member
(define-public (register-member (tier (string-ascii 20)) (pickup-location (string-ascii 100)))
  (let
    (
      (member-id (var-get next-member-id))
      (current-block block-height)
    )
    (asserts! (is-valid-tier tier) ERR-INVALID-TIER)
    (asserts! (is-none (map-get? member-by-address { wallet-address: tx-sender })) ERR-MEMBER-EXISTS)

    (map-set members
      { member-id: member-id }
      {
        wallet-address: tx-sender,
        subscription-tier: tier,
        status: "pending",
        join-date: current-block,
        payment-due: current-block,
        total-paid: u0,
        pickup-location: pickup-location
      }
    )

    (map-set member-by-address
      { wallet-address: tx-sender }
      { member-id: member-id }
    )

    (var-set next-member-id (+ member-id u1))
    (var-set total-members (+ (var-get total-members) u1))

    (print { event: "member-registered", member-id: member-id, tier: tier })
    (ok member-id)
  )
)

;; Process subscription payment
(define-public (pay-subscription (member-id uint))
  (let
    (
      (member-data (unwrap! (map-get? members { member-id: member-id }) ERR-MEMBER-NOT-FOUND))
      (tier (get subscription-tier member-data))
      (price (unwrap! (get price (map-get? subscription-prices { tier: tier })) ERR-INVALID-TIER))
    )
    (asserts! (is-eq tx-sender (get wallet-address member-data)) ERR-NOT-AUTHORIZED)

    ;; In a real implementation, this would handle STX transfer
    ;; For now, we'll just update the payment records

    (map-set members
      { member-id: member-id }
      (merge member-data {
        status: "active",
        payment-due: (+ block-height u4320), ;; ~30 days
        total-paid: (+ (get total-paid member-data) price)
      })
    )

    (print { event: "payment-processed", member-id: member-id, amount: price })
    (ok true)
  )
)

;; Update member subscription tier
(define-public (update-subscription-tier (member-id uint) (new-tier (string-ascii 20)))
  (let
    (
      (member-data (unwrap! (map-get? members { member-id: member-id }) ERR-MEMBER-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (get wallet-address member-data)) ERR-NOT-AUTHORIZED)
    (asserts! (is-valid-tier new-tier) ERR-INVALID-TIER)

    (map-set members
      { member-id: member-id }
      (merge member-data { subscription-tier: new-tier })
    )

    (print { event: "tier-updated", member-id: member-id, new-tier: new-tier })
    (ok true)
  )
)

;; Update pickup location
(define-public (update-pickup-location (member-id uint) (new-location (string-ascii 100)))
  (let
    (
      (member-data (unwrap! (map-get? members { member-id: member-id }) ERR-MEMBER-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (get wallet-address member-data)) ERR-NOT-AUTHORIZED)

    (map-set members
      { member-id: member-id }
      (merge member-data { pickup-location: new-location })
    )

    (print { event: "pickup-location-updated", member-id: member-id })
    (ok true)
  )
)

;; Suspend member (admin only)
(define-public (suspend-member (member-id uint))
  (let
    (
      (member-data (unwrap! (map-get? members { member-id: member-id }) ERR-MEMBER-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    (map-set members
      { member-id: member-id }
      (merge member-data { status: "suspended" })
    )

    (print { event: "member-suspended", member-id: member-id })
    (ok true)
  )
)

;; Read-only Functions

;; Get member details
(define-read-only (get-member (member-id uint))
  (map-get? members { member-id: member-id })
)

;; Get member ID by wallet address
(define-read-only (get-member-id (wallet-address principal))
  (map-get? member-by-address { wallet-address: wallet-address })
)

;; Get subscription price for tier
(define-read-only (get-subscription-price (tier (string-ascii 20)))
  (map-get? subscription-prices { tier: tier })
)

;; Get total member count
(define-read-only (get-total-members)
  (var-get total-members)
)

;; Check if member is active
(define-read-only (is-member-active (member-id uint))
  (match (map-get? members { member-id: member-id })
    member-data (is-eq (get status member-data) "active")
    false
  )
)

;; Private Functions

;; Validate subscription tier
(define-private (is-valid-tier (tier (string-ascii 20)))
  (or
    (is-eq tier "basic")
    (or
      (is-eq tier "premium")
      (is-eq tier "family")
    )
  )
)
