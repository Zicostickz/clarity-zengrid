;; ZenGrid - Mental Health Tracking Contract

;; Constants 
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-INVALID-SCORE (err u102))
(define-constant ERR-ALREADY-RECORDED-TODAY (err u103))
(define-constant ERR-NO-ENTRIES (err u104))
(define-constant ERR-INVALID-TIMEFRAME (err u105))
(define-constant ERR-FUTURE-DATE (err u106))

;; Data Variables
(define-map daily-entries
    { user: principal, date: uint }
    { score: uint, note: (optional (string-utf8 280)) }
)

;; Data Variables for Weekly Insights
(define-map weekly-insights
    { user: principal, week: uint }
    { 
      avg-score: uint,
      trend: (string-utf8 20),
      entry-count: uint,
      streak: uint
    }
)

;; Private Functions
(define-private (is-valid-score (score uint))
    (and (>= score u1) (<= score u5))
)

(define-private (get-today)
    (/ block-height u144)  ;; Approximate days since genesis
)

(define-private (get-week)
    (/ (get-today) u7)
)

(define-private (is-valid-date (date uint))
    (<= date (get-today))
)

(define-private (get-week-entries (day-offset uint) (acc { count: uint, total: uint }))
    (let (
        (current-week (get-week))
        (target-day (+ (* current-week u7) day-offset))
        (entry (get-entry tx-sender target-day))
    )
    (if (is-some entry)
        {
            count: (+ (get count acc) u1),
            total: (+ (get total acc) (get score (unwrap-panic entry)))
        }
        acc
    ))
)

(define-private (calculate-trend (current-avg uint) (prev-avg uint))
    (if (> current-avg prev-avg)
        "improving"
        (if (< current-avg prev-avg)
            "declining"
            "stable"
        )
    )
)

(define-private (calculate-streak (user principal) (current-week uint))
    (let (
        (prev-insight (map-get? weekly-insights { user: user, week: (- current-week u1) }))
        (current-entries (get-week-entries u6 { count: u0, total: u0 }))
    )
    (if (and (is-some prev-insight) (> (get count current-entries) u0))
        (+ (get streak (unwrap-panic prev-insight)) u1)
        u1)
    )
)

;; [Rest of the contract remains unchanged...]
