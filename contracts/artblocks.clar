;; ArtBlocks Collaborative NFT Platform
;; Implement a collaborative NFT platform using Stacks blockchain and Clarity

(define-non-fungible-token art-blocks-collaborative (buff 32))

;; Storage for tracking artist contributions
(define-map artist-contributions 
  {token-id: (buff 32)}
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
(define-constant err-not-owner (err u100))
(define-constant err-invalid-royalties (err u101))
(define-constant err-token-exists (err u102))
(define-constant err-invalid-contribution (err u103))

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
      (total-royalty (fold + royalty-percentages u0))
    )
    ;; Validate total royalty is 100%
    (asserts! (is-eq total-royalty u100) err-invalid-royalties)
    
    ;; Ensure no duplicate token
    (asserts! 
      (not (is-some (nft-get-owner? art-blocks-collaborative token-id))) 
      err-token-exists
    )
    
    ;; Mint NFT to transaction sender
    (try! (nft-mint? art-blocks-collaborative token-id tx-sender))
    
    ;; Store artist contributions
    (map-set artist-contributions 
      {token-id: token-id}
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
          (map-get? artist-contributions {token-id: token-id}) 
          (err u404)
        )
      )
    )
    ;; Ensure only token owner can distribute royalties
    (asserts! 
      (is-eq tx-sender (unwrap! (nft-get-owner? art-blocks-collaborative token-id) (err u404))) 
      err-not-owner
    )
    
    ;; Distribute royalties to each artist
    (try! 
      (fold distribute-artist-royalty 
        (zip contributions.artists contributions.royalty-percentages)
        (ok u0)
      )
    )
    
    (ok true)
  )
)

;; Helper function to distribute royalties to individual artists
(define-private (distribute-artist-royalty 
  (artist-data {artist: principal, royalty: uint})
  (prev-result (response uint uint))
)
  (match prev-result
    prev-value
    (let 
      (
        ;; Calculate artist's share
        (artist-royalty (/ (* sale-price artist-data.royalty) u100))
      )
      ;; Transfer royalty
      (try! (stx-transfer? artist-royalty tx-sender artist-data.artist))
      
      ;; Update artist royalties
      (map-set artist-royalties 
        artist-data.artist 
        (+ 
          (default-to u0 (map-get? artist-royalties artist-data.artist)) 
          artist-royalty
        )
      )
      
      ;; Emit royalty distribution event
      (print (royalty-distributed artist-data.artist artist-royalty))
      
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
  (map-get? artist-contributions {token-id: token-id})
)

;; View function to get artist's total royalties
(define-read-only (get-artist-royalties (artist principal))
  (map-get? artist-royalties artist)
)