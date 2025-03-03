;; ZenGrid - Mental Health Tracking Contract

;; Constants 
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-INVALID-SCORE (err u102))
(define-constant ERR-ALREADY-RECORDED-TODAY (err u103))
(define-constant ERR-NO-ENTRIES (err u104))
(define-constant ERR-INVALID-TIMEFRAME (err u105))
(define-constant ERR-FUTURE-DATE (err u106))
(define-constant ERR-NOTE-TOO-LONG (err u107))
(define-constant MAX-NOTE-LENGTH u280)

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

(define-private (is-valid-note (note (optional (string-utf8 280))))
    (match note
        some-note (< (len some-note) MAX-NOTE-LENGTH)
        true
    )
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

(define-private (iterate-week-days (current-day uint) (acc { count: uint, total: uint }))
    (let (
        (entry (get-entry tx-sender current-day))
    )
    (if (>= current-day (+ current-day u7))
        acc
        (if (is-some entry)
            (iterate-week-days 
                (+ current-day u1)
                {
                    count: (+ (get count acc) u1),
                    total: (+ (get total acc) (get score (unwrap-panic entry)))
                }
            )
            (iterate-week-days (+ current-day u1) acc)
        )
    ))
)

(define-private (calculate-streak (user principal) (current-week uint))
    (let (
        (prev-insight (map-get? weekly-insights { user: user, week: (- current-week u1) }))
        (week-start (* current-week u7))
        (continuous-entries (verify-continuous-entries user week-start))
    )
    (if (and (is-some prev-insight) continuous-entries)
        (+ (get streak (unwrap-panic prev-insight)) u1)
        u1)
    )
)

(define-private (verify-continuous-entries (user principal) (start-day uint))
    (let (
        (entries (fold iterate-week-days 
            (list u0 u1 u2 u3 u4 u5 u6)
            { count: u0, total: u0 }
        ))
    )
    (= (get count entries) u7))
)

;; Public Functions remain unchanged...
