;; ArtBlocks Collaborative NFT Platform
;; Implement a collaborative NFT platform using Stacks blockchain and Clarity

(define-non-fungible-token art-blocks-collaborative (buff 32))

;; Storage for tracking artist contributions
(define-map artist-contributions 
  { token-id: (buff 32) }
  { 
    artists: (list 5 principal),
    royalty-percentages: (list 5 uint),
    contribution-descriptions: (list 5 (string-utf8 100))
  }
)

;; Storage for tracking artist royalties
(define-map artist-royalties 
  principal 
  uint
)

;; Contract owner
(define-constant contract-owner tx-sender)

;; Error constants
(define-constant ERR-NOT-OWNER (err u100))
(define-constant ERR-INVALID-ROYALTIES (err u101))
(define-constant ERR-TOKEN-EXISTS (err u102))
(define-constant ERR-INVALID-CONTRIBUTION (err u103))

;; Events
(define-event create-collaborative-artwork 
  (token-id (buff 32))
  (artists (list 5 principal))
  (royalty-percentages (list 5 uint))
)

(define-event royalty-distributed
  (artist principal)
  (amount uint)
)

;; Utility function to sum a list of uints
(define-private (sum-list (lst (list 5 uint)))
  (fold + lst u0)
)

;; Create a new collaborative artwork
(define-public (create-collaborative-artwork 
  (artists (list 5 principal))
  (royalty-percentages (list 5 uint))
  (contribution-descriptions (list 5 (string-utf8 100)))
)
  (let 
    (
      (token-id (sha256 (to-consensus-buff? {
        artists: artists, 
        royalty-percentages: royalty-percentages, 
        block-height: block-height
      })))
      (total-royalty (sum-list royalty-percentages))
    )
    ;; Validate total royalty is 100%
    (asserts! (is-eq total-royalty u100) ERR-INVALID-ROYALTIES)
    
    ;; Ensure no duplicate token
    (asserts! 
      (is-none (nft-get-owner? art-blocks-collaborative token-id)) 
      ERR-TOKEN-EXISTS
    )
    
    ;; Mint NFT to transaction sender
    (try! (nft-mint? art-blocks-collaborative token-id tx-sender))
    
    ;; Store artist contributions
    (map-set artist-contributions 
      { token-id: token-id }
      {
        artists: artists,
        royalty-percentages: royalty-percentages,
        contribution-descriptions: contribution-descriptions
      }
    )
    
    ;; Emit event
    (print (create-collaborative-artwork token-id artists royalty-percentages))
    
    ;; Return token ID
    (ok token-id)
  )
)

;; Distribute royalties for a sold artwork
(define-public (distribute-royalties 
  (token-id (buff 32))
  (sale-price uint)
)
  (let 
    (
      ;; Retrieve artist contributions
      (contributions 
        (unwrap! 
          (map-get? artist-contributions { token-id: token-id }) 
          (err u404)
        )
      )
    )
    ;; Ensure only token owner can distribute royalties
    (asserts! 
      (is-eq tx-sender (unwrap! (nft-get-owner? art-blocks-collaborative token-id) (err u404))) 
      ERR-NOT-OWNER
    )
    
    ;; Distribute royalties to each artist
    (try! 
      (distribute-royalties-internal 
        (get artists contributions) 
        (get royalty-percentages contributions)
        sale-price
      )
    )
    
    (ok true)
  )
)

;; Internal function to distribute royalties
(define-private (distribute-royalties-internal 
  (artists (list 5 principal))
  (royalty-percentages (list 5 uint))
  (sale-price uint)
)
  (match (fold distribute-single-artist-royalty 
          (list 
            { artist: (element-at artists u0), royalty: (element-at royalty-percentages u0) }
            { artist: (element-at artists u1), royalty: (element-at royalty-percentages u1) }
            { artist: (element-at artists u2), royalty: (element-at royalty-percentages u2) }
            { artist: (element-at artists u3), royalty: (element-at royalty-percentages u3) }
            { artist: (element-at artists u4), royalty: (element-at royalty-percentages u4) }
          )
          (ok u0)
        )
    result result
    error-value (err error-value)
  )
)

;; Distribute royalty to a single artist
(define-private (distribute-single-artist-royalty 
  (artist-data { artist: principal, royalty: uint })
  (prev-result (response uint uint))
)
  (match prev-result
    prev-value
    (let 
      (
        ;; Calculate artist's share
        (artist-royalty (/ (* sale-price (get royalty artist-data)) u100))
      )
      ;; Transfer royalty
      (try! (stx-transfer? artist-royalty tx-sender (get artist artist-data)))
      
      ;; Update artist royalties
      (map-set artist-royalties 
        (get artist artist-data)
        (+ 
          (default-to u0 (map-get? artist-royalties (get artist artist-data))) 
          artist-royalty
        )
      )
      
      ;; Emit royalty distribution event
      (print (royalty-distributed (get artist artist-data) artist-royalty))
      
      (ok (+ prev-value artist-royalty))
    )
    error-value 
    (err error-value)
  )
)

;; Allow artists to withdraw accumulated royalties
(define-public (withdraw-royalties)
  (let 
    (
      (royalty-amount 
        (unwrap! 
          (map-get? artist-royalties tx-sender) 
          (err u404)
        )
      )
    )
    ;; Ensure royalties exist
    (asserts! (> royalty-amount u0) (err u404))
    
    ;; Reset royalties before transfer
    (map-set artist-royalties tx-sender u0)
    
    ;; Transfer royalties
    (try! (stx-transfer? royalty-amount tx-sender tx-sender))
    
    (ok royalty-amount)
  )
)

;; View function to get artist contributions
(define-read-only (get-artist-contributions (token-id (buff 32)))
  (map-get? artist-contributions { token-id: token-id })
)

;; View function to get artist's total royalties
(define-read-only (get-artist-royalties (artist principal))
  (map-get? artist-royalties artist)
)