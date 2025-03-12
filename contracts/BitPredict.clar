;; Title: BitPredict - Decentralized Bitcoin Price Prediction Markets
;;
;; Summary: L2-optimized prediction protocol enabling secure BTC price speculation
;;
;; Description: 
;; BitPredict revolutionizes decentralized finance by creating a Bitcoin-native prediction market
;; protocol anchored on Stacks L2. Our platform combines blockchain's trustless nature with 
;; enterprise-grade scalability, offering:
;; - Real-time BTC price markets with minimized latency
;; - Anti-manipulation mechanisms through Stack's Bitcoin-finalized blocks
;; - Dynamic reward distribution with automated fee capture
;; Designed for both traders and developers, BitPredict creates a new paradigm for decentralized
;; price speculation while maintaining direct Bitcoin settlement security.


;; ADMINISTRATIVE CONFIGURATION

;; Contract owner (initial deployer)
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-parameter (err u101))
(define-constant err-not-found (err u102))
(define-constant err-market-closed (err u103))
(define-constant err-invalid-prediction (err u104))
(define-constant err-insufficient-balance (err u105))
(define-constant err-already-claimed (err u106))

;; Oracle configuration
(define-data-var oracle-address principal 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM) ;; Initial placeholder
(define-data-var minimum-stake uint u1000000)  ;; 1.0 STX base participation
(define-data-var protocol-fee uint u2)         ;; 2% platform fee on winnings
(define-data-var market-counter uint u0)       ;; Global market ID tracker

;; PREDICTION MARKET CORE STRUCTURES

;; Market lifecycle tracking
(define-map markets
    uint  ;; Market ID
    { 
        opening-price: uint,      ;; BTC/USD price at market start (sats)
        closing-price: uint,      ;; BTC/USD price at resolution (sats)
        bull-commitment: uint,    ;; Total "up" positions (STX)
        bear-commitment: uint,    ;; Total "down" positions (STX)
        activation-block: uint,   ;; Stacks block height for market start
        expiration-block: uint,   ;; Stacks block height for market end
        resolution-status: bool   ;; Market settlement flag
    }
)

;; User position management
(define-map positions
    {market: uint, participant: principal}  ;; Composite key
    {
        direction: (string-ascii 4),  ;; "bull" or "bear"
        amount: uint,                  ;; STX committed
        claimed: bool                  ;; Reward status
    }
)

;; MARKET LIFECYCLE MANAGEMENT

;; Creates new prediction market window
(define-public (create-market (opening-price uint) (activation-block uint) (expiration-block uint))
    (let (
        (new-market-id (var-get market-counter))
        )
        ;; Administrative controls
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (> expiration-block activation-block) err-invalid-parameter)
        (asserts! (> opening-price u0) err-invalid-parameter)
        
        ;; Market initialization
        (map-set markets new-market-id
            {
                opening-price: opening-price,
                closing-price: u0,
                bull-commitment: u0,
                bear-commitment: u0,
                activation-block: activation-block,
                expiration-block: expiration-block,
                resolution-status: false
            }
        )
        (var-set market-counter (+ new-market-id u1))
        (ok new-market-id)
    )
)

;; MARKET PARTICIPATION ENGINE

;; Processes user market participation
(define-public (take-position (market-id uint) (position (string-ascii 4)) (stake uint))
    (let (
        (market (unwrap! (map-get? markets market-id) err-not-found))
        (current-block stacks-block-height)
        )
        ;; Market validity checks
        (asserts! (and 
                (>= current-block (get activation-block market)) 
                (< current-block (get expiration-block market))) 
                err-market-closed)
        (asserts! (or (is-eq position "bull") (is-eq position "bear")) 
                err-invalid-prediction)
        (asserts! (>= stake (var-get minimum-stake)) 
                err-invalid-parameter)

        ;; Capital management
        (asserts! (<= stake (stx-get-balance tx-sender)) 
                err-insufficient-balance)
        (try! (stx-transfer? stake tx-sender (as-contract tx-sender)))

        ;; Position registration
        (map-set positions 
            {market: market-id, participant: tx-sender}
            {direction: position, amount: stake, claimed: false}
        )

        ;; Market state update
        (map-set markets market-id
            (merge market {
                bull-commitment: (if (is-eq position "bull")
                                (+ (get bull-commitment market) stake)
                                (get bull-commitment market)),
                bear-commitment: (if (is-eq position "bear")
                                (+ (get bear-commitment market) stake)
                                (get bear-commitment market))
            })
        )
        (ok true)
    )
)

;; MARKET RESOLUTION SYSTEM

;; Finalizes market with oracle-reported price
(define-public (settle-market (market-id uint) (closing-price uint))
    (let (
        (market (unwrap! (map-get? markets market-id) err-not-found))
        )
        ;; Authorization and timing checks
        (asserts! (is-eq tx-sender (var-get oracle-address)) err-owner-only)
        (asserts! (>= stacks-block-height (get expiration-block market)) err-market-closed)
        (asserts! (not (get resolution-status market)) err-market-closed)
        (asserts! (> closing-price u0) err-invalid-parameter)

        ;; Market finalization
        (map-set markets market-id
            (merge market {
                closing-price: closing-price,
                resolution-status: true
            })
        )
        (ok true)
    )
)

;; REWARD DISTRIBUTION MECHANISM

;; Processes reward claims for successful positions
(define-public (claim-rewards (market-id uint))
    (let (
        (market (unwrap! (map-get? markets market-id) err-not-found))
        (position (unwrap! (map-get? positions {market: market-id, participant: tx-sender}) err-not-found))
        )
        ;; Claim validity checks
        (asserts! (get resolution-status market) err-market-closed)
        (asserts! (not (get claimed position)) err-already-claimed)

        (let (
            (winning-side (if (> (get closing-price market) (get opening-price market)) "bull" "bear"))
            (total-commitment (+ (get bull-commitment market) (get bear-commitment market)))
            (winning-pool (if (is-eq winning-side "bull") 
                            (get bull-commitment market) 
                            (get bear-commitment market)))
            )
            ;; Position outcome verification
            (asserts! (is-eq (get direction position) winning-side) err-invalid-prediction)
            
            (let (
                (gross-reward (/ (* (get amount position) total-commitment) winning-pool))
                (local-protocol-fee (/ (* gross-reward (var-get protocol-fee)) u100))
                (net-payout (- gross-reward local-protocol-fee))
                )
                ;; Fund distribution
                (try! (as-contract (stx-transfer? net-payout (as-contract tx-sender) tx-sender)))
                (try! (as-contract (stx-transfer? local-protocol-fee (as-contract tx-sender) contract-owner)))
                
                ;; Position state update
                (map-set positions 
                    {market: market-id, participant: tx-sender}
                    (merge position {claimed: true})
                )
                (ok net-payout)
            )
        )
    )
)