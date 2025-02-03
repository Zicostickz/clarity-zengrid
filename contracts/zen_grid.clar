;; ZenGrid - Mental Health Tracking Contract

;; Constants 
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-INVALID-SCORE (err u102))
(define-constant ERR-ALREADY-RECORDED-TODAY (err u103))
(define-constant ERR-NO-ENTRIES (err u104))
(define-constant ERR-INVALID-TIMEFRAME (err u105))

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
    (let ((prev-insight (map-get? weekly-insights { user: user, week: (- current-week u1) })))
        (if (is-some prev-insight)
            (+ (get streak (unwrap-panic prev-insight)) u1)
            u1)
    )
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

(define-public (generate-weekly-insight)
    (let
        (
            (current-week (get-week))
            (start-day (* current-week u7))
            (entries (fold get-week-entries (list u0 u1 u2 u3 u4 u5 u6) { count: u0, total: u0 }))
            (avg-score (if (> (get count entries) u0)
                        (/ (get total entries) (get count entries))
                        u0))
            (prev-insight (map-get? weekly-insights { user: tx-sender, week: (- current-week u1) }))
            (prev-avg (default-to u0 (get avg-score prev-insight)))
            (streak (calculate-streak tx-sender current-week))
        )
        (if (> (get count entries) u0)
            (ok (map-set weekly-insights
                { user: tx-sender, week: current-week }
                {
                    avg-score: avg-score,
                    trend: (calculate-trend avg-score prev-avg),
                    entry-count: (get count entries),
                    streak: streak
                }))
            ERR-NO-ENTRIES)
    )
)

;; Read Only Functions
(define-read-only (get-entry (user principal) (date uint))
    (map-get? daily-entries { user: user, date: date })
)

(define-read-only (get-today-entry (user principal))
    (get-entry user (get-today))
)

(define-read-only (get-weekly-insight (user principal) (week uint))
    (map-get? weekly-insights { user: user, week: week })
)

(define-read-only (get-current-week-insight (user principal))
    (get-weekly-insight user (get-week))
)
