;; Title: Simplified Treatment Protocol Management
;; Description: Simplified smart contract for managing personalized treatment protocols

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_INVALID_SCORE (err u102))
(define-constant ERR_INVALID_INPUT (err u103))
(define-constant MAX_SCORE u100)

;; Data Variables
(define-data-var protocol-counter uint u0)
(define-data-var admin principal CONTRACT_OWNER)

;; Data Maps
(define-map medical-professionals 
    principal 
    {
        is-active: bool,
        specialty: (string-utf8 64)
    })

(define-map treatment-protocols
    { protocol-id: uint }
    {
        genetic-marker: (string-utf8 32),
        treatment-details: (string-utf8 256),
        creator: principal,
        effectiveness-score: uint,
        total-patients: uint,
        status: (string-utf8 16)
    })

(define-map patient-treatments
    { patient: principal }
    {
        current-protocol: uint,
        treatment-start: uint,
        genetic-marker: (string-utf8 32)
    })

;; Helper Functions
(define-private (validate-string-length (input (string-utf8 256)) (max-len uint))
    (>= max-len (len input)))

(define-private (is-medical-professional (practitioner principal))
    (default-to 
        false
        (get is-active (map-get? medical-professionals practitioner))))

;; Administrative Functions
(define-public (register-medical-professional (practitioner principal) (specialty (string-utf8 64)))
    (begin
        (asserts! (is-eq tx-sender (var-get admin)) ERR_NOT_AUTHORIZED)
        (asserts! (validate-string-length specialty u64) ERR_INVALID_INPUT)
        (asserts! (not (is-eq practitioner (var-get admin))) ERR_INVALID_INPUT)
        (map-set medical-professionals 
            practitioner
            {
                is-active: true,
                specialty: specialty
            })
        (ok true)))

;; Protocol Management Functions
(define-public (create-protocol 
    (genetic-marker (string-utf8 32))
    (treatment-details (string-utf8 256)))
    (let ((new-id (+ (var-get protocol-counter) u1)))
        (begin
            (asserts! (is-medical-professional tx-sender) ERR_NOT_AUTHORIZED)
            (asserts! (validate-string-length genetic-marker u32) ERR_INVALID_INPUT)
            (asserts! (validate-string-length treatment-details u256) ERR_INVALID_INPUT)
            (var-set protocol-counter new-id)
            (map-set treatment-protocols
                { protocol-id: new-id }
                {
                    genetic-marker: genetic-marker,
                    treatment-details: treatment-details,
                    creator: tx-sender,
                    effectiveness-score: u0,
                    total-patients: u0,
                    status: u"active"
                })
            (ok new-id))))

(define-public (verify-protocol (protocol-id uint))
    (let ((protocol (unwrap! (map-get? treatment-protocols { protocol-id: protocol-id })
                            ERR_NOT_FOUND)))
        (begin
            (asserts! (is-medical-professional tx-sender) ERR_NOT_AUTHORIZED)
            (asserts! (is-eq (get creator protocol) tx-sender) ERR_NOT_AUTHORIZED)
            (asserts! (> protocol-id u0) ERR_INVALID_INPUT)
            (map-set treatment-protocols
                { protocol-id: protocol-id }
                (merge protocol 
                    { status: u"verified" }))
            (ok true))))

(define-public (start-treatment (patient principal) (protocol-id uint) (genetic-marker (string-utf8 32)))
    (let ((protocol (unwrap! (map-get? treatment-protocols { protocol-id: protocol-id })
                            ERR_NOT_FOUND)))
        (begin
            (asserts! (is-medical-professional tx-sender) ERR_NOT_AUTHORIZED)
            (asserts! (is-eq (get status protocol) u"verified") ERR_NOT_AUTHORIZED)
            (asserts! (> protocol-id u0) ERR_INVALID_INPUT)
            (asserts! (validate-string-length genetic-marker u32) ERR_INVALID_INPUT)
            (asserts! (not (is-eq patient tx-sender)) ERR_INVALID_INPUT)
            (map-set patient-treatments
                { patient: patient }
                {
                    current-protocol: protocol-id,
                    treatment-start: block-height,
                    genetic-marker: genetic-marker
                })
            (map-set treatment-protocols
                { protocol-id: protocol-id }
                (merge protocol
                    { total-patients: (+ (get total-patients protocol) u1) }))
            (ok true))))

(define-public (record-treatment-outcome (patient principal) (protocol-id uint) (outcome-score uint))
    (let ((protocol (unwrap! (map-get? treatment-protocols { protocol-id: protocol-id })
                            ERR_NOT_FOUND))
          (treatment (unwrap! (map-get? patient-treatments { patient: patient })
                             ERR_NOT_FOUND)))
        (begin
            (asserts! (is-medical-professional tx-sender) ERR_NOT_AUTHORIZED)
            (asserts! (and (>= outcome-score u0) (<= outcome-score MAX_SCORE)) ERR_INVALID_SCORE)
            (asserts! (> protocol-id u0) ERR_INVALID_INPUT)
            (map-set treatment-protocols
                { protocol-id: protocol-id }
                (merge protocol
                    { effectiveness-score: (/ (+ (get effectiveness-score protocol) outcome-score) u2) }))
            (ok true))))

;; Read-Only Functions
(define-read-only (get-protocol-details (protocol-id uint))
    (map-get? treatment-protocols { protocol-id: protocol-id }))

(define-read-only (get-patient-history (patient principal))
    (map-get? patient-treatments { patient: patient }))