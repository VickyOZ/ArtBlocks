;; Enhanced Voting Contract with Additional Robustness Features and Input Validation

;; Define constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_ALREADY_VOTED (err u101))
(define-constant ERR_INVALID_PROPOSAL (err u102))
(define-constant ERR_VOTING_CLOSED (err u103))
(define-constant ERR_INVALID_INPUT (err u104))
(define-constant ERR_PROPOSAL_NOT_FOUND (err u105))
(define-constant ERR_VOTING_PERIOD_EXCEEDED (err u106))
(define-constant MAX_VOTING_DURATION u2592000) ;; 30 days in seconds
(define-constant MIN_VOTING_DURATION u86400) ;; 1 day in seconds

;; Define data maps
(define-map proposals
  { proposal-id: uint }
  { 
    title: (string-ascii 50), 
    description: (string-ascii 500), 
    vote-count: uint, 
    is-active: bool,
    creator: principal,
    created-at: uint,
    voting-duration: uint
  }
)

(define-map votes
  { voter: principal, proposal-id: uint }
  { 
    voted: bool,
    vote-timestamp: uint
  }
)

;; Define data variables
(define-data-var proposal-count uint u0)
(define-data-var default-voting-duration uint u604800) ;; 7 days in seconds

;; Private functions
;; Validate proposal input
(define-private (validate-proposal-input (title (string-ascii 50)) (description (string-ascii 500)))
  (and 
    (> (len title) u0) 
    (<= (len title) u50)
    (> (len description) u0)
    (<= (len description) u500)
  )
)

;; Validate proposal ID
(define-private (validate-proposal-id (proposal-id uint))
  (and 
    (> proposal-id u0)
    (<= proposal-id (var-get proposal-count))
  )
)

;; Check if a proposal exists and is still active
(define-private (is-proposal-active (proposal-id uint))
  (match (map-get? proposals { proposal-id: proposal-id })
    proposal 
      (and 
        (get is-active proposal)
        (< block-height (+ (get created-at proposal) (get voting-duration proposal)))
      )
    false
  )
)

;; Validate voting duration
(define-private (validate-voting-duration (duration uint))
  (and (>= duration MIN_VOTING_DURATION) (<= duration MAX_VOTING_DURATION))
)

;; Public functions
;; Create a new proposal with optional custom voting duration
(define-public (create-proposal 
  (title (string-ascii 50)) 
  (description (string-ascii 500))
  (custom-duration (optional uint))
)
  (let (
    (new-proposal-id (+ (var-get proposal-count) u1))
    (voting-duration (default-to (var-get default-voting-duration) custom-duration))
  )
    ;; Validate sender is contract owner
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    
    ;; Validate proposal input
    (asserts! (validate-proposal-input title description) ERR_INVALID_INPUT)
    
    ;; Validate voting duration
    (asserts! (validate-voting-duration voting-duration) ERR_INVALID_INPUT)
    
    ;; Create proposal with extended metadata
    (map-set proposals
      { proposal-id: new-proposal-id }
      { 
        title: title, 
        description: description, 
        vote-count: u0, 
        is-active: true,
        creator: tx-sender,
        created-at: block-height,
        voting-duration: voting-duration
      }
    )
    
    ;; Update proposal count
    (var-set proposal-count new-proposal-id)
    
    (ok new-proposal-id)
  )
)

;; Vote on a proposal
(define-public (vote (proposal-id uint))
  (let (
    (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) ERR_INVALID_PROPOSAL))
    (has-voted (default-to false (get voted (map-get? votes { voter: tx-sender, proposal-id: proposal-id }))))
  )
    ;; Validate proposal ID
    (asserts! (validate-proposal-id proposal-id) ERR_INVALID_PROPOSAL)
    
    ;; Validate proposal is active and within voting period
    (asserts! (is-proposal-active proposal-id) ERR_VOTING_CLOSED)
    
    ;; Prevent multiple votes
    (asserts! (not has-voted) ERR_ALREADY_VOTED)
    
    ;; Record vote
    (map-set votes 
      { voter: tx-sender, proposal-id: proposal-id } 
      { 
        voted: true,
        vote-timestamp: block-height 
      }
    )
    
    ;; Update proposal vote count
    (map-set proposals
      { proposal-id: proposal-id }
      (merge proposal { vote-count: (+ (get vote-count proposal) u1) })
    )
    
    (ok true)
  )
)

;; Close a proposal manually (can only be done by contract owner)
(define-public (close-proposal (proposal-id uint))
  (let (
    (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) ERR_PROPOSAL_NOT_FOUND))
  )
    ;; Validate proposal ID
    (asserts! (validate-proposal-id proposal-id) ERR_INVALID_PROPOSAL)
    
    ;; Validate sender is contract owner
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    
    ;; Close the proposal
    (ok (map-set proposals
      { proposal-id: proposal-id }
      (merge proposal { is-active: false })
    ))
  )
)

;; Update default voting duration (only by contract owner)
(define-public (set-default-voting-duration (duration uint))
  (begin
    ;; Validate sender is contract owner
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    
    ;; Validate duration is reasonable (between MIN_VOTING_DURATION and MAX_VOTING_DURATION)
    (asserts! (validate-voting-duration duration) ERR_INVALID_INPUT)
    
    ;; Set new default duration
    (var-set default-voting-duration duration)
    (ok true)
  )
)

;; Read-only functions
;; Get proposal details with additional context
(define-read-only (get-proposal-details (proposal-id uint))
  (let ((proposal (map-get? proposals { proposal-id: proposal-id })))
    ;; Validate proposal ID before processing
    (if (validate-proposal-id proposal-id)
        (if (is-some proposal)
            (some {
              proposal: proposal,
              is-active: (is-proposal-active proposal-id),
              remaining-blocks: (match proposal
                p (- (+ (get created-at p) (get voting-duration p)) block-height)
                u0)
            })
            none
        )
        none
    )
  )
)

;; Get the total number of proposals
(define-read-only (get-proposal-count)
  (var-get proposal-count)
)

;; Check if a user has voted on a specific proposal
(define-read-only (has-voted (voter principal) (proposal-id uint))
  ;; Validate proposal ID before checking votes
  (if (validate-proposal-id proposal-id)
      (default-to false (get voted (map-get? votes { voter: voter, proposal-id: proposal-id })))
      false
  )
)