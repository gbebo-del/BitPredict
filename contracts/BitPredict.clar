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