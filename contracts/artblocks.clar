;; Define constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_ALREADY_VOTED (err u101))
(define-constant ERR_INVALID_PROPOSAL (err u102))
(define-constant ERR_VOTING_CLOSED (err u103))

;; Define data maps
(define-map proposals
  { proposal-id: uint }
  { title: (string-ascii 50), description: (string-ascii 500), vote-count: uint, is-active: bool }
)

(define-map votes
  { voter: principal, proposal-id: uint }
  { voted: bool }
)

;; Define data variables
(define-data-var proposal-count uint u0)

;; Public functions

;; Create a new proposal
(define-public (create-proposal (title (string-ascii 50)) (description (string-ascii 500)))
  (let ((new-proposal-id (+ (var-get proposal-count) u1)))
    (if (is-eq tx-sender CONTRACT_OWNER)
      (begin
        (map-set proposals
          { proposal-id: new-proposal-id }
          { title: title, description: description, vote-count: u0, is-active: true }
        )
        (var-set proposal-count new-proposal-id)
        (ok new-proposal-id)
      )
      ERR_NOT_AUTHORIZED
    )
  )
)

;; Vote on a proposal
(define-public (vote (proposal-id uint))
  (let (
    (proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) ERR_INVALID_PROPOSAL))
    (has-voted (default-to false (get voted (map-get? votes { voter: tx-sender, proposal-id: proposal-id }))))
  )
    (asserts! (get is-active proposal) ERR_VOTING_CLOSED)
    (asserts! (not has-voted) ERR_ALREADY_VOTED)
    (map-set votes { voter: tx-sender, proposal-id: proposal-id } { voted: true })
    (map-set proposals
      { proposal-id: proposal-id }
      (merge proposal { vote-count: (+ (get vote-count proposal) u1) })
    )
    (ok true)
  )
)

;; Close a proposal
(define-public (close-proposal (proposal-id uint))
  (let ((proposal (unwrap! (map-get? proposals { proposal-id: proposal-id }) ERR_INVALID_PROPOSAL)))
    (if (is-eq tx-sender CONTRACT_OWNER)
      (begin
        (map-set proposals
          { proposal-id: proposal-id }
          (merge proposal { is-active: false })
        )
        (ok true)
      )
      ERR_NOT_AUTHORIZED
    )
  )
)

;; Read-only functions

;; Get proposal details
(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals { proposal-id: proposal-id })
)

;; Get the total number of proposals
(define-read-only (get-proposal-count)
  (var-get proposal-count)
)

;; Check if a user has voted on a specific proposal
(define-read-only (has-voted (voter principal) (proposal-id uint))
  (default-to false (get voted (map-get? votes { voter: voter, proposal-id: proposal-id })))
)