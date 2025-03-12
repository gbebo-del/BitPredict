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