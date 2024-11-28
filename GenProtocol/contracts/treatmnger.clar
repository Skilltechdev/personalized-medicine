;; Title: Personalized Treatment Protocol Management
;; Description: Smart contract for managing personalized medical treatment protocols based on genetic markers
;; Author: Claude
;; Version: 1.0.0

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_INVALID_SCORE (err u102))
(define-constant ERR_ALREADY_VERIFIED (err u103))
(define-constant MAX_VERIFIERS u5)
(define-constant MIN_SCORE u0)
(define-constant MAX_SCORE u100)

;; Data Variables
(define-data-var protocol-counter uint u0)
(define-data-var admin principal CONTRACT_OWNER)

;; Data Maps
(define-map medical-professionals 
    principal 
    {
        is-active: bool,
        specialty: (string-utf8 64),
        verification-count: uint
    })

(define-map treatment-protocols
    { protocol-id: uint }
    {
        genetic-marker: (string-utf8 32),
        treatment-details: (string-utf8 256),
        creation-date: uint,
        effectiveness-score: uint,
        total-patients: uint,
        status: (string-utf8 16),
        creator: principal,
        verified-by: (list MAX_VERIFIERS principal),
        version: uint
    })

(define-map patient-treatments
    { patient: principal }
    {
        current-protocol: uint,
        treatment-start: uint,
        treatment-history: (list 20 {
            protocol-id: uint,
            start-date: uint,
            end-date: uint,
            outcome-score: uint
        }),
        genetic-marker: (string-utf8 32)
    })

(define-map protocol-versions
    { base-protocol-id: uint }
    { current-version: uint,
      version-history: (list 10 uint) })

;; Events
(define-public (print-treatment-event (protocol-id uint) (event-type (string-utf8 24)) (details (string-utf8 64)))
    (print { protocol-id: protocol-id, event-type: event-type, details: details })
    (ok true))

;; Access Control Functions
(define-private (is-medical-professional (practitioner principal))
    (match (map-get? medical-professionals practitioner)
        professional (get is-active professional)
        false))

(define-private (is-protocol-verified (protocol-id uint))
    (match (map-get? treatment-protocols { protocol-id: protocol-id })
        protocol (> (len (get verified-by protocol)) u2)
        false))

;; Administrative Functions
(define-public (register-medical-professional (practitioner principal) (specialty (string-utf8 64)))
    (begin
        (asserts! (is-eq tx-sender (var-get admin)) ERR_NOT_AUTHORIZED)
        (ok (map-set medical-professionals 
            practitioner
            {
                is-active: true,
                specialty: specialty,
                verification-count: u0
            }))))

;; Protocol Management Functions
(define-public (create-protocol 
    (genetic-marker (string-utf8 32))
    (treatment-details (string-utf8 256)))
    (let 
        ((new-id (+ (var-get protocol-counter) u1)))
        (begin
            (asserts! (is-medical-professional tx-sender) ERR_NOT_AUTHORIZED)
            (var-set protocol-counter new-id)
            (map-set treatment-protocols
                { protocol-id: new-id }
                {
                    genetic-marker: genetic-marker,
                    treatment-details: treatment-details,
                    creation-date: block-height,
                    effectiveness-score: u0,
                    total-patients: u0,
                    status: "active",
                    creator: tx-sender,
                    verified-by: (list),
                    version: u1
                })
            (map-set protocol-versions
                { base-protocol-id: new-id }
                {
                    current-version: u1,
                    version-history: (list new-id)
                })
            (print-treatment-event new-id "protocol-created" genetic-marker)
            (ok new-id))))

(define-public (verify-protocol (protocol-id uint))
    (let ((protocol (unwrap! (map-get? treatment-protocols { protocol-id: protocol-id })
                            ERR_NOT_FOUND)))
        (begin
            (asserts! (is-medical-professional tx-sender) ERR_NOT_AUTHORIZED)
            (asserts! (not (is-some (index-of? (get verified-by protocol) tx-sender))) ERR_ALREADY_VERIFIED)
            (map-set treatment-protocols
                { protocol-id: protocol-id }
                (merge protocol 
                    { verified-by: (append (get verified-by protocol) tx-sender) }))
            (print-treatment-event protocol-id "protocol-verified" (concat "verified-by-" (to-string tx-sender)))
            (ok true))))

;; Patient Treatment Functions
(define-public (start-treatment (patient principal) (protocol-id uint) (genetic-marker (string-utf8 32)))
    (let ((protocol (unwrap! (map-get? treatment-protocols { protocol-id: protocol-id })
                            ERR_NOT_FOUND)))
        (begin
            (asserts! (is-medical-professional tx-sender) ERR_NOT_AUTHORIZED)
            (asserts! (is-protocol-verified protocol-id) ERR_NOT_AUTHORIZED)
            (map-set patient-treatments
                { patient: patient }
                {
                    current-protocol: protocol-id,
                    treatment-start: block-height,
                    treatment-history: (list {
                        protocol-id: protocol-id,
                        start-date: block-height,
                        end-date: u0,
                        outcome-score: u0
                    }),
                    genetic-marker: genetic-marker
                })
            (map-set treatment-protocols
                { protocol-id: protocol-id }
                (merge protocol
                    { total-patients: (+ (get total-patients protocol) u1) }))
            (print-treatment-event protocol-id "treatment-started" (concat "patient-" (to-string patient)))
            (ok true))))

(define-public (record-treatment-outcome 
    (patient principal) 
    (protocol-id uint)
    (outcome-score uint))
    (let ((protocol (unwrap! (map-get? treatment-protocols { protocol-id: protocol-id })
                            ERR_NOT_FOUND))
          (treatment (unwrap! (map-get? patient-treatments { patient: patient })
                             ERR_NOT_FOUND)))
        (begin
            (asserts! (is-medical-professional tx-sender) ERR_NOT_AUTHORIZED)
            (asserts! (and (>= outcome-score MIN_SCORE) (<= outcome-score MAX_SCORE)) ERR_INVALID_SCORE)
            ;; Update protocol effectiveness score
            (map-set treatment-protocols
                { protocol-id: protocol-id }
                (merge protocol
                    { effectiveness-score: (/ (+ (get effectiveness-score protocol) outcome-score) u2) }))
            ;; Update patient treatment history
            (map-set patient-treatments
                { patient: patient }
                (merge treatment
                    { treatment-history: (append (get treatment-history treatment)
                        {
                            protocol-id: protocol-id,
                            start-date: (get treatment-start treatment),
                            end-date: block-height,
                            outcome-score: outcome-score
                        }) }))
            (print-treatment-event protocol-id "outcome-recorded" (concat "score-" (to-string outcome-score)))
            (ok true))))

;; Read-Only Functions
(define-read-only (get-protocol-details (protocol-id uint))
    (map-get? treatment-protocols { protocol-id: protocol-id }))

(define-read-only (get-patient-history (patient principal))
    (map-get? patient-treatments { patient: patient }))

(define-read-only (get-protocols-by-marker (genetic-marker (string-utf8 32)))
    (filter protocols-map-to-list genetic-marker))

(define-private (protocols-map-to-list (protocol { protocol-id: uint }))
    (match (map-get? treatment-protocols protocol)
        value (is-eq (get genetic-marker value) genetic-marker)
        false))

;; Protocol Version Management
(define-public (create-protocol-version 
    (base-protocol-id uint)
    (treatment-details (string-utf8 256)))
    (let ((base-protocol (unwrap! (map-get? treatment-protocols { protocol-id: base-protocol-id })
                                 ERR_NOT_FOUND))
          (version-info (unwrap! (map-get? protocol-versions { base-protocol-id: base-protocol-id })
                                ERR_NOT_FOUND))
          (new-id (+ (var-get protocol-counter) u1)))
        (begin
            (asserts! (is-medical-professional tx-sender) ERR_NOT_AUTHORIZED)
            (var-set protocol-counter new-id)
            ;; Create new protocol version
            (map-set treatment-protocols
                { protocol-id: new-id }
                (merge base-protocol {
                    treatment-details: treatment-details,
                    creation-date: block-height,
                    effectiveness-score: u0,
                    total-patients: u0,
                    verified-by: (list),
                    version: (+ (get current-version version-info) u1)
                }))
            ;; Update version tracking
            (map-set protocol-versions
                { base-protocol-id: base-protocol-id }
                {
                    current-version: (+ (get current-version version-info) u1),
                    version-history: (append (get version-history version-info) new-id)
                })
            (print-treatment-event new-id "version-created" (concat "base-" (to-string base-protocol-id)))
            (ok new-id))))