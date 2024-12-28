;; ZenGrid - Mental Health Tracking Contract

;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-INVALID-SCORE (err u102))
(define-constant ERR-ALREADY-RECORDED-TODAY (err u103))

;; Data Variables
(define-map daily-entries
    { user: principal, date: uint }
    { score: uint, note: (optional (string-utf8 280)) }
)

;; Private Functions
(define-private (is-valid-score (score uint))
    (and (>= score u1) (<= score u5))
)

(define-private (get-today)
    (/ block-height u144)  ;; Approximate days since genesis
)

;; Public Functions
(define-public (record-entry (score uint) (note (optional (string-utf8 280))))
    (let
        (
            (today (get-today))
            (existing-entry (map-get? daily-entries { user: tx-sender, date: today }))
        )
        (if (not (is-valid-score score))
            ERR-INVALID-SCORE
            (if (is-some existing-entry)
                ERR-ALREADY-RECORDED-TODAY
                (ok (map-set daily-entries
                    { user: tx-sender, date: today }
                    { score: score, note: note }
                ))
            )
        )
    )
)

(define-public (update-today-entry (score uint) (note (optional (string-utf8 280))))
    (let
        (
            (today (get-today))
            (existing-entry (map-get? daily-entries { user: tx-sender, date: today }))
        )
        (if (not (is-valid-score score))
            ERR-INVALID-SCORE
            (if (is-none existing-entry)
                (err u104)
                (ok (map-set daily-entries
                    { user: tx-sender, date: today }
                    { score: score, note: note }
                ))
            )
        )
    )
)

;; Read Only Functions
(define-read-only (get-entry (user principal) (date uint))
    (map-get? daily-entries { user: user, date: date })
)

(define-read-only (get-today-entry (user principal))
    (get-entry user (get-today))
)