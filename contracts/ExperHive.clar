;; Enhanced ExperHive Smart Contract with Security Framework
;; Version 2.2 - All Security Warnings Fixed

;; ============================================================================
;; SECURITY CONSTANTS
;; ============================================================================

;; Role-based access control
(define-constant ROLE_ADMIN u1)
(define-constant ROLE_VERIFIER u2)
(define-constant ROLE_MODERATOR u3)
(define-constant ROLE_USER u4)

;; Security limits
(define-constant MAX_BATCH_SIZE u50)
(define-constant RATE_LIMIT_WINDOW u144) ;; ~24 hours in blocks
(define-constant MAX_ACTIONS_PER_WINDOW u100)
(define-constant MAX_PENDING_OPERATIONS u20)
(define-constant MULTISIG_EXPIRY_BLOCKS u1440) ;; ~10 days

;; Original Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ENDORSEMENT_EXPIRY_BLOCKS u52560) ;; ~365 days
(define-constant CHALLENGE_DURATION_BLOCKS u1440) ;; ~10 days
(define-constant REPUTATION_DECAY_BLOCKS u7200) ;; ~50 days
(define-constant MAX_REPUTATION_SCORE u10000)
(define-constant MIN_REPUTATION_SCORE u100)

;; Additional Security Constants
(define-constant MAX_OPERATION_AMOUNT u1000000000000) ;; Max STX amount for operations
(define-constant MIN_OPERATION_AMOUNT u1000) ;; Min STX amount for operations
(define-constant MAX_OPERATION_STRING_LENGTH u64)
(define-constant MAX_PRINCIPAL_OPERATIONS_PER_WINDOW u10)

;; ============================================================================
;; ERROR CONSTANTS
;; ============================================================================

;; Original Error Constants
(define-constant ERR_NOT_AUTHORIZED (err u403))
(define-constant ERR_INVALID_INPUT (err u400))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_ALREADY_EXISTS (err u409))
(define-constant ERR_INSUFFICIENT_FUNDS (err u402))
(define-constant ERR_CHALLENGE_EXPIRED (err u410))
(define-constant ERR_CHALLENGE_NOT_ACTIVE (err u411))
(define-constant ERR_NFT_NOT_FOUND (err u412))
(define-constant ERR_INVALID_DATA (err u413))

;; Enhanced Security Error Constants
(define-constant ERR_REENTRANCY (err u500))
(define-constant ERR_RATE_LIMITED (err u501))
(define-constant ERR_INSUFFICIENT_ROLE (err u502))
(define-constant ERR_PAUSED (err u503))
(define-constant ERR_MULTISIG_REQUIRED (err u504))
(define-constant ERR_OPERATION_EXPIRED (err u505))
(define-constant ERR_INSUFFICIENT_APPROVALS (err u506))
(define-constant ERR_ALREADY_APPROVED (err u507))
(define-constant ERR_INVALID_PRINCIPAL (err u508))
(define-constant ERR_INVALID_AMOUNT (err u509))
(define-constant ERR_OPERATION_LIMIT_EXCEEDED (err u510))

;; ============================================================================
;; DATA VARIABLES
;; ============================================================================

;; Original Data Variables
(define-data-var next-challenge-id uint u1)
(define-data-var next-nft-id uint u1)
(define-data-var platform-fee-rate uint u250) ;; 2.5%

;; Security State Variables
(define-data-var contract-paused bool false)
(define-data-var reentrancy-guard bool false)
(define-data-var next-operation-id uint u1)
(define-data-var emergency-mode bool false)

;; ============================================================================
;; SECURITY MAPS
;; ============================================================================

;; Role management
(define-map user-roles principal uint)
(define-map role-permissions uint (list 20 (string-ascii 32)))

;; Rate limiting
(define-map user-action-count 
    (tuple (user principal) (window uint))
    uint)

;; Principal operation tracking for additional security
(define-map principal-operation-count
    (tuple (principal principal) (window uint))
    uint)

;; Multi-signature operations
(define-map pending-operations
    uint
    (tuple
        (operation (string-ascii 64))
        (target principal)
        (amount uint)
        (approvals (list 5 principal))
        (required-approvals uint)
        (expires-at uint)
        (executed bool)))

(define-map operation-approvals
    (tuple (operation-id uint) (approver principal))
    bool)

;; Security audit trail
(define-map security-events
    uint
    (tuple
        (event-type (string-ascii 32))
        (user principal)
        (timestamp uint)
        (details (string-ascii 128))))

;; ============================================================================
;; ORIGINAL MAPS (Unchanged)
;; ============================================================================

(define-map skills {user: principal} (list 10 (string-ascii 32)))
(define-map endorsements (tuple (endorsed principal) (skill (string-ascii 32))) (list 10 principal))
(define-map skill-categories (string-ascii 32) (list 10 (string-ascii 32)))
(define-map verified-skills 
    (tuple (user principal) (skill (string-ascii 32))) 
    (tuple (verified bool) (verifier principal)))
(define-map skill-ratings 
    (tuple (rated principal) (skill (string-ascii 32))) 
    (tuple (total-score uint) (rating-count uint)))
(define-map endorsement-timestamps
    (tuple (endorsed principal) (endorser principal) (skill (string-ascii 32)))
    uint)
(define-map skill-experience
    (tuple (user principal) (skill (string-ascii 32)))
    (tuple (level (string-ascii 12)) (years uint)))
(define-map endorser-weights principal uint)
(define-map authorized-verifiers principal bool)

;; Enhanced Feature Maps
(define-map skill-challenges
    uint ;; challenge-id
    (tuple
        (creator principal)
        (skill (string-ascii 32))
        (title (string-ascii 64))
        (description (string-ascii 256))
        (difficulty uint) ;; 1-5
        (reward uint) ;; STX amount
        (deadline uint) ;; block height
        (max-participants uint)
        (status (string-ascii 20)) ;; "active", "completed", "cancelled"
        (created-at uint)))

(define-map challenge-participants
    (tuple (challenge-id uint) (participant principal))
    (tuple
        (submission-hash (string-ascii 64))
        (submitted-at uint)
        (score uint) ;; 0-100
        (reviewed bool)))

(define-map challenge-reviews
    (tuple (challenge-id uint) (participant principal) (reviewer principal))
    (tuple
        (score uint) ;; 0-100
        (feedback (string-ascii 256))
        (reviewed-at uint)))

(define-map user-reputation
    principal
    (tuple
        (overall-score uint)
        (accuracy-rate uint) ;; percentage 0-100
        (endorsement-accuracy uint) ;; how accurate their endorsements are
        (last-activity uint) ;; block height
        (total-endorsements-given uint)
        (total-endorsements-received uint)
        (challenges-completed uint)
        (challenges-created uint)
        (fraud-flags uint)))

(define-map endorsement-accuracy
    (tuple (endorser principal) (endorsed principal) (skill (string-ascii 32)))
    (tuple
        (accuracy-score uint) ;; 0-100, calculated based on later validations
        (validation-count uint)))

(define-map skill-nfts
    uint ;; token-id
    (tuple
        (owner principal)
        (skill (string-ascii 32))
        (level (string-ascii 12)) ;; "Beginner", "Intermediate", "Expert", "Master"
        (verification-score uint) ;; combined score from endorsements, ratings, challenges
        (issue-date uint)
        (issuer principal) ;; who issued the NFT (verifier or system)
        (metadata-uri (string-ascii 256))
        (achievement-type (string-ascii 32)))) ;; "skill-mastery", "challenge-winner", "top-endorser"

(define-map nft-ownership uint principal)
(define-map user-nft-count principal uint)

(define-map achievement-requirements
    (string-ascii 32) ;; achievement-type
    (tuple
        (min-endorsements uint)
        (min-rating uint)
        (min-challenges uint)
        (min-reputation uint)))

;; ============================================================================
;; ENHANCED VALIDATION FUNCTIONS
;; ============================================================================

;; Comprehensive principal validation
(define-private (validate-trusted-principal (user principal))
    (and 
        (not (is-eq user tx-sender))
        (not (is-eq user (as-contract tx-sender)))
        (not (is-eq user 'SP000000000000000000002Q6VF78)) ;; Burn address
        (is-standard user))) ;; Ensure it's a standard principal

;; Enhanced operation string validation
(define-private (validate-operation-string (operation (string-ascii 64)))
    (and 
        (not (is-eq operation ""))
        (<= (len operation) MAX_OPERATION_STRING_LENGTH)
        (> (len operation) u3) ;; Minimum meaningful operation length
        ;; Check for valid operation types
        (or 
            (is-eq operation "transfer-funds")
            (is-eq operation "update-contract")
            (is-eq operation "emergency-action")
            (is-eq operation "role-management")
            (is-eq operation "parameter-update"))))

;; Enhanced amount validation
(define-private (validate-operation-amount (amount uint))
    (and 
        (>= amount MIN_OPERATION_AMOUNT)
        (<= amount MAX_OPERATION_AMOUNT)
        (not (is-eq amount u0))))

;; Enhanced approval count validation
(define-private (validate-approval-count (count uint))
    (and 
        (> count u0)
        (<= count u5)
        (not (is-eq count u0))))

;; Principal operation rate limiting
(define-private (check-principal-operation-limit (target-principal principal))
    (let ((current-window (/ stacks-block-height RATE_LIMIT_WINDOW))
          (current-count (default-to u0 
            (map-get? principal-operation-count (tuple (principal target-principal) (window current-window))))))
        (begin
            (asserts! (< current-count MAX_PRINCIPAL_OPERATIONS_PER_WINDOW) ERR_OPERATION_LIMIT_EXCEEDED)
            (map-set principal-operation-count 
                (tuple (principal target-principal) (window current-window))
                (+ current-count u1))
            (ok true))))

;; Sanitize and validate operation data
(define-private (sanitize-operation-data 
    (operation (string-ascii 64))
    (target principal)
    (amount uint))
    (begin
        (asserts! (validate-operation-string operation) ERR_INVALID_INPUT)
        (asserts! (validate-trusted-principal target) ERR_INVALID_PRINCIPAL)
        (asserts! (validate-operation-amount amount) ERR_INVALID_AMOUNT)
        (ok true)))

;; Safe operation string sanitizer
(define-private (sanitize-operation-string (operation (string-ascii 64)))
    (if (validate-operation-string operation)
        operation
        "emergency-action"))

;; Safe principal sanitizer
(define-private (sanitize-principal (target principal))
    (if (validate-trusted-principal target)
        target
        'SP000000000000000000002Q6VF78)) ;; Default to burn address if invalid

;; Safe amount sanitizer
(define-private (sanitize-amount (amount uint))
    (if (validate-operation-amount amount)
        amount
        MIN_OPERATION_AMOUNT))

;; Safe approval count sanitizer
(define-private (sanitize-approval-count (count uint))
    (if (validate-approval-count count)
        count
        u1))

;; ============================================================================
;; SECURITY FUNCTIONS - FIXED RETURN TYPES
;; ============================================================================

;; Initialize contract owner with admin role
(map-set user-roles CONTRACT_OWNER ROLE_ADMIN)

;; Security check functions with proper return types
(define-private (check-reentrancy)
    (begin
        (asserts! (not (var-get reentrancy-guard)) ERR_REENTRANCY)
        (var-set reentrancy-guard true)
        (ok true)))

(define-private (clear-reentrancy)
    (begin
        (var-set reentrancy-guard false)
        (ok true)))

(define-private (check-not-paused)
    (begin
        (asserts! (not (var-get contract-paused)) ERR_PAUSED)
        (ok true)))

(define-private (check-rate-limit (user principal))
    (let ((current-window (/ stacks-block-height RATE_LIMIT_WINDOW))
          (current-count (default-to u0 
            (map-get? user-action-count (tuple (user user) (window current-window))))))
        (begin
            (asserts! (< current-count MAX_ACTIONS_PER_WINDOW) ERR_RATE_LIMITED)
            (map-set user-action-count 
                (tuple (user user) (window current-window))
                (+ current-count u1))
            (ok true))))

(define-private (has-role (user principal) (required-role uint))
    (let ((user-role (default-to ROLE_USER (map-get? user-roles user))))
        (<= required-role user-role)))

(define-private (check-emergency-mode)
    (begin
        (asserts! (not (var-get emergency-mode)) ERR_PAUSED)
        (ok true)))

;; Enhanced authorization wrapper with proper error handling
(define-private (with-security-checks (user principal) (required-role uint))
    (begin
        (try! (check-reentrancy))
        (try! (check-not-paused))
        (try! (check-emergency-mode))
        (try! (check-rate-limit user))
        (asserts! (has-role user required-role) ERR_INSUFFICIENT_ROLE)
        (ok true)))

;; Log security events
(define-private (log-security-event (event-type (string-ascii 32)) (user principal) (details (string-ascii 128)))
    (let ((event-id (var-get next-operation-id)))
        (begin
            (map-set security-events event-id
                (tuple
                    (event-type event-type)
                    (user user)
                    (timestamp stacks-block-height)
                    (details details)))
            (var-set next-operation-id (+ event-id u1))
            (ok event-id))))

;; ============================================================================
;; EMERGENCY & ADMIN FUNCTIONS
;; ============================================================================

(define-public (emergency-pause)
    (begin
        (asserts! (has-role tx-sender ROLE_ADMIN) ERR_NOT_AUTHORIZED)
        (var-set contract-paused true)
        (unwrap-panic (log-security-event "emergency-pause" tx-sender "Contract paused by admin"))
        (ok "Contract paused")))

(define-public (emergency-unpause)
    (begin
        (asserts! (has-role tx-sender ROLE_ADMIN) ERR_NOT_AUTHORIZED)
        (var-set contract-paused false)
        (unwrap-panic (log-security-event "emergency-unpause" tx-sender "Contract unpaused by admin"))
        (ok "Contract unpaused")))

(define-public (activate-emergency-mode)
    (begin
        (asserts! (has-role tx-sender ROLE_ADMIN) ERR_NOT_AUTHORIZED)
        (var-set emergency-mode true)
        (unwrap-panic (log-security-event "emergency-mode" tx-sender "Emergency mode activated"))
        (ok "Emergency mode activated")))

(define-public (deactivate-emergency-mode)
    (begin
        (asserts! (has-role tx-sender ROLE_ADMIN) ERR_NOT_AUTHORIZED)
        (var-set emergency-mode false)
        (unwrap-panic (log-security-event "emergency-mode-off" tx-sender "Emergency mode deactivated"))
        (ok "Emergency mode deactivated")))

;; Role management
(define-public (grant-role (user principal) (role uint))
    (begin
        (try! (with-security-checks tx-sender ROLE_ADMIN))
        (asserts! (<= role ROLE_ADMIN) ERR_INVALID_INPUT)
        (asserts! (validate-trusted-principal user) ERR_INVALID_PRINCIPAL)
        (map-set user-roles user role)
        (unwrap-panic (log-security-event "role-granted" user "Role granted"))
        (unwrap-panic (clear-reentrancy))
        (ok "Role granted")))

(define-public (revoke-role (user principal))
    (begin
        (try! (with-security-checks tx-sender ROLE_ADMIN))
        (asserts! (not (is-eq user CONTRACT_OWNER)) ERR_NOT_AUTHORIZED) ;; Can't revoke owner
        (asserts! (validate-trusted-principal user) ERR_INVALID_PRINCIPAL)
        (map-set user-roles user ROLE_USER)
        (unwrap-panic (log-security-event "role-revoked" user "Role revoked"))
        (unwrap-panic (clear-reentrancy))
        (ok "Role revoked")))

;; Multi-signature operations for critical functions - SECURITY ENHANCED
(define-public (create-multisig-operation 
    (operation (string-ascii 64))
    (target principal)
    (amount uint)
    (required-approvals uint))
    (let ((operation-id (var-get next-operation-id)))
        (begin
            (try! (with-security-checks tx-sender ROLE_ADMIN))
            
            ;; Pre-validate all inputs before sanitization
            (asserts! (validate-operation-string operation) ERR_INVALID_INPUT)
            (asserts! (validate-trusted-principal target) ERR_INVALID_PRINCIPAL)
            (asserts! (validate-operation-amount amount) ERR_INVALID_AMOUNT)
            (asserts! (validate-approval-count required-approvals) ERR_INVALID_INPUT)
            
            ;; Now safely sanitize the validated inputs
            (let ((sanitized-operation (sanitize-operation-string operation))
                  (sanitized-target (sanitize-principal target))
                  (sanitized-amount (sanitize-amount amount))
                  (sanitized-approvals (sanitize-approval-count required-approvals)))
                
                ;; Double-check with sanitized data
                (try! (sanitize-operation-data sanitized-operation sanitized-target sanitized-amount))
                (try! (check-principal-operation-limit sanitized-target))
                
                (map-set pending-operations operation-id
                    (tuple
                        (operation sanitized-operation)
                        (target sanitized-target)
                        (amount sanitized-amount)
                        (approvals (list tx-sender))
                        (required-approvals sanitized-approvals)
                        (expires-at (+ stacks-block-height MULTISIG_EXPIRY_BLOCKS))
                        (executed false)))
                
                (map-set operation-approvals
                    (tuple (operation-id operation-id) (approver tx-sender))
                    true)
                
                (var-set next-operation-id (+ operation-id u1))
                (unwrap-panic (log-security-event "multisig-created" tx-sender sanitized-operation))
                (unwrap-panic (clear-reentrancy))
                (ok operation-id)))))

(define-public (approve-multisig-operation (operation-id uint))
    (let ((operation-data (unwrap! (map-get? pending-operations operation-id) ERR_NOT_FOUND)))
        (begin
            (try! (with-security-checks tx-sender ROLE_ADMIN))
            
            ;; Extract and pre-validate operation data
            (let ((raw-operation (get operation operation-data))
                  (raw-target (get target operation-data))
                  (raw-amount (get amount operation-data)))
                
                ;; Validate the stored operation data
                (asserts! (validate-operation-string raw-operation) ERR_INVALID_INPUT)
                (asserts! (validate-trusted-principal raw-target) ERR_INVALID_PRINCIPAL)
                (asserts! (validate-operation-amount raw-amount) ERR_INVALID_AMOUNT)
                
                ;; Sanitize the validated data
                (let ((validated-operation (sanitize-operation-string raw-operation))
                      (validated-target (sanitize-principal raw-target))
                      (validated-amount (sanitize-amount raw-amount)))
                    
                    ;; Re-validate the operation data
                    (try! (sanitize-operation-data validated-operation validated-target validated-amount))
                    (asserts! (not (get executed operation-data)) ERR_INVALID_INPUT)
                    (asserts! (< stacks-block-height (get expires-at operation-data)) ERR_OPERATION_EXPIRED)
                    (asserts! (is-none (map-get? operation-approvals 
                        (tuple (operation-id operation-id) (approver tx-sender)))) ERR_ALREADY_APPROVED)
                    
                    (map-set operation-approvals
                        (tuple (operation-id operation-id) (approver tx-sender))
                        true)
                    
                    (let ((current-approvals (get approvals operation-data)))
                        (map-set pending-operations operation-id
                            (merge operation-data 
                                (tuple (approvals (unwrap! (as-max-len? (append current-approvals tx-sender) u5) ERR_INVALID_INPUT))))))
                    
                    (unwrap-panic (log-security-event "multisig-approved" tx-sender validated-operation))
                    (unwrap-panic (clear-reentrancy))
                    (ok "Operation approved"))))))

;; ============================================================================
;; ORIGINAL VALIDATION FUNCTIONS (Enhanced with security)
;; ============================================================================

(define-private (validate-string-length (str (string-ascii 32)))
    (and 
        (not (is-eq str ""))
        (<= (len str) u32)))

(define-private (validate-long-string (str (string-ascii 256)))
    (and 
        (not (is-eq str ""))
        (<= (len str) u256)))

(define-private (validate-medium-string (str (string-ascii 64)))
    (and 
        (not (is-eq str ""))
        (<= (len str) u64)))

(define-private (validate-principal (user principal))
    (validate-trusted-principal user))

(define-private (validate-skill (skill (string-ascii 32)))
    (and 
        (not (is-eq skill ""))
        (< (len skill) u32)))

(define-private (validate-rating (rating uint))
    (and (> rating u0) (<= rating u5)))

(define-private (validate-score (score uint))
    (and (>= score u0) (<= score u100)))

(define-private (validate-years (years uint))
    (and (>= years u0) (<= years u100)))

(define-private (validate-weight (weight uint))
    (and (> weight u0) (<= weight u100)))

(define-private (validate-difficulty (difficulty uint))
    (and (>= difficulty u1) (<= difficulty u5)))

(define-private (validate-block-height (height uint))
    (and (> height u0) (<= height u4294967295))) ;; Max uint32

(define-private (validate-reward-amount (amount uint))
    (and (> amount u0) (<= amount u1000000000000))) ;; Max reasonable STX amount

(define-private (validate-experience-level (level (string-ascii 12)))
    (or 
        (is-eq level "Beginner")
        (is-eq level "Intermediate")
        (is-eq level "Expert")
        (is-eq level "Master")))

(define-private (validate-challenge-status (status (string-ascii 20)))
    (or 
        (is-eq status "active")
        (is-eq status "completed")
        (is-eq status "cancelled")))

(define-private (validate-achievement-type (achievement-type (string-ascii 32)))
    (or 
        (is-eq achievement-type "skill-mastery")
        (is-eq achievement-type "challenge-winner")
        (is-eq achievement-type "top-endorser")
        (is-eq achievement-type "mentor")
        (is-eq achievement-type "learner")))

(define-private (validate-challenge-data (challenge (tuple (creator principal) (skill (string-ascii 32)) (title (string-ascii 64)) (description (string-ascii 256)) (difficulty uint) (reward uint) (deadline uint) (max-participants uint) (status (string-ascii 20)) (created-at uint))))
    (and
        (validate-skill (get skill challenge))
        (validate-medium-string (get title challenge))
        (validate-long-string (get description challenge))
        (validate-difficulty (get difficulty challenge))
        (validate-reward-amount (get reward challenge))
        (validate-block-height (get deadline challenge))
        (> (get max-participants challenge) u0)
        (validate-challenge-status (get status challenge))
        (validate-block-height (get created-at challenge))))

(define-private (validate-nft-data (nft (tuple (owner principal) (skill (string-ascii 32)) (level (string-ascii 12)) (verification-score uint) (issue-date uint) (issuer principal) (metadata-uri (string-ascii 256)) (achievement-type (string-ascii 32)))))
    (and
        (validate-skill (get skill nft))
        (validate-experience-level (get level nft))
        (validate-score (get verification-score nft))
        (validate-block-height (get issue-date nft))
        (validate-long-string (get metadata-uri nft))
        (validate-achievement-type (get achievement-type nft))))

;; ============================================================================
;; HELPER FUNCTIONS (Unchanged)
;; ============================================================================

(define-private (min-uint (a uint) (b uint))
    (if (<= a b) a b))

(define-private (max-uint (a uint) (b uint))
    (if (>= a b) a b))

(define-private (clamp-uint (value uint) (min-val uint) (max-val uint))
    (min-uint (max-uint value min-val) max-val))

(define-private (check-skill-exists (user principal) (skill (string-ascii 32)))
    (let ((user-skills (default-to (list) (map-get? skills {user: user}))))
        (is-some (index-of user-skills skill))))

(define-private (get-safe-ratings (user principal) (skill (string-ascii 32)))
    (default-to 
        (tuple (total-score u0) (rating-count u0)) 
        (map-get? skill-ratings (tuple (rated user) (skill skill)))))

(define-private (get-safe-endorsers (user principal) (skill (string-ascii 32)))
    (default-to 
        (list) 
        (map-get? endorsements (tuple (endorsed user) (skill skill)))))

(define-private (get-safe-reputation (user principal))
    (default-to
        (tuple
            (overall-score u1000)
            (accuracy-rate u50)
            (endorsement-accuracy u50)
            (last-activity u0)
            (total-endorsements-given u0)
            (total-endorsements-received u0)
            (challenges-completed u0)
            (challenges-created u0)
            (fraud-flags u0))
        (map-get? user-reputation user)))

(define-private (remove-sender (endorser principal))
    (not (is-eq endorser tx-sender)))

(define-private (is-contract-owner (caller principal))
    (is-eq caller CONTRACT_OWNER))

(define-private (is-authorized-verifier (caller principal))
    (or 
        (default-to false (map-get? authorized-verifiers caller))
        (has-role caller ROLE_VERIFIER)))

(define-private (get-endorser-weight (endorser principal))
    (default-to u1 (map-get? endorser-weights endorser)))

(define-private (calculate-reputation-decay (last-activity uint))
    (let ((blocks-since-activity (if (>= stacks-block-height last-activity)
                                    (- stacks-block-height last-activity)
                                    u0)))
        (if (> blocks-since-activity REPUTATION_DECAY_BLOCKS)
            (/ blocks-since-activity REPUTATION_DECAY_BLOCKS)
            u0)))

(define-private (update-user-activity (user principal))
    (let ((current-rep (get-safe-reputation user)))
        (begin
            (map-set user-reputation user
                (merge current-rep (tuple (last-activity stacks-block-height))))
            (ok true))))

;; ============================================================================
;; ENHANCED PUBLIC FUNCTIONS (With Security)
;; ============================================================================

(define-public (add-authorized-verifier (verifier principal))
    (begin
        (try! (with-security-checks tx-sender ROLE_ADMIN))
        (asserts! (validate-trusted-principal verifier) ERR_INVALID_PRINCIPAL)
        (map-set authorized-verifiers verifier true)
        (map-set user-roles verifier ROLE_VERIFIER)
        (unwrap-panic (log-security-event "verifier-added" verifier "Authorized verifier added"))
        (unwrap-panic (clear-reentrancy))
        (ok "Verifier added")))

(define-public (add-skill (skill (string-ascii 32)))
    (begin
        (try! (with-security-checks tx-sender ROLE_USER))
        (asserts! (validate-skill skill) ERR_INVALID_INPUT)
        (let ((existing (default-to (list) (map-get? skills {user: tx-sender}))))
            (begin
                (asserts! (< (len existing) u10) ERR_INVALID_INPUT)
                (asserts! (not (is-some (index-of existing skill))) ERR_INVALID_INPUT)
                (map-set skills {user: tx-sender} 
                    (unwrap! (as-max-len? (append existing skill) u10) ERR_INVALID_INPUT))
                (unwrap-panic (update-user-activity tx-sender))
                (unwrap-panic (clear-reentrancy))
                (ok "Skill added")))))

(define-public (endorse (user principal) (skill (string-ascii 32)))
    (begin
        (try! (with-security-checks tx-sender ROLE_USER))
        (asserts! (validate-trusted-principal user) ERR_INVALID_PRINCIPAL)
        (asserts! (validate-skill skill) ERR_INVALID_INPUT)
        (asserts! (check-skill-exists user skill) ERR_NOT_FOUND)
        (let ((endorsers (get-safe-endorsers user skill))
              (endorser-rep (get-safe-reputation tx-sender))
              (endorsed-rep (get-safe-reputation user)))
            (begin
                (asserts! (< (len endorsers) u10) ERR_INVALID_INPUT)
                (asserts! (not (is-some (index-of endorsers tx-sender))) ERR_INVALID_INPUT)
                (map-set endorsements 
                    (tuple (endorsed user) (skill skill)) 
                    (unwrap! (as-max-len? (append endorsers tx-sender) u10) ERR_INVALID_INPUT))
                ;; Update reputation for both parties
                (map-set user-reputation tx-sender
                    (merge endorser-rep 
                        (tuple 
                            (total-endorsements-given (+ (get total-endorsements-given endorser-rep) u1))
                            (last-activity stacks-block-height))))
                (map-set user-reputation user
                    (merge endorsed-rep 
                        (tuple 
                            (total-endorsements-received (+ (get total-endorsements-received endorsed-rep) u1))
                            (last-activity stacks-block-height))))
                (unwrap-panic (clear-reentrancy))
                (ok "Endorsed")))))

(define-public (rate-skill (user principal) (skill (string-ascii 32)) (rating uint))
    (begin
        (try! (with-security-checks tx-sender ROLE_USER))
        (asserts! (validate-trusted-principal user) ERR_INVALID_PRINCIPAL)
        (asserts! (validate-skill skill) ERR_INVALID_INPUT)
        (asserts! (validate-rating rating) ERR_INVALID_INPUT)
        (asserts! (check-skill-exists user skill) ERR_NOT_FOUND)
        (asserts! (can-rate-skill tx-sender user) ERR_NOT_AUTHORIZED)
        (let ((current-ratings (get-safe-ratings user skill)))
            (begin
                (map-set skill-ratings 
                    (tuple (rated user) (skill skill))
                    (tuple 
                        (total-score (+ (get total-score current-ratings) rating))
                        (rating-count (+ (get rating-count current-ratings) u1))))
                (unwrap-panic (update-user-activity tx-sender))
                (unwrap-panic (clear-reentrancy))
                (ok "Rating added")))))

;; ============================================================================
;; CHALLENGE SYSTEM (Enhanced with Security)
;; ============================================================================

(define-public (create-challenge
    (skill (string-ascii 32))
    (title (string-ascii 64))
    (description (string-ascii 256))
    (difficulty uint)
    (reward uint)
    (duration-blocks uint)
    (max-participants uint))
    (let ((challenge-id (var-get next-challenge-id))
          (creator-rep (get-safe-reputation tx-sender))
          (deadline (+ stacks-block-height duration-blocks)))
        (begin
            (try! (with-security-checks tx-sender ROLE_USER))
            (asserts! (validate-skill skill) ERR_INVALID_INPUT)
            (asserts! (validate-medium-string title) ERR_INVALID_INPUT)
            (asserts! (validate-long-string description) ERR_INVALID_INPUT)
            (asserts! (validate-difficulty difficulty) ERR_INVALID_INPUT)
            (asserts! (validate-reward-amount reward) ERR_INVALID_INPUT)
            (asserts! (> duration-blocks u0) ERR_INVALID_INPUT)
            (asserts! (> max-participants u0) ERR_INVALID_INPUT)
            (asserts! (<= max-participants u100) ERR_INVALID_INPUT)
            (asserts! (>= (stx-get-balance tx-sender) reward) ERR_INSUFFICIENT_FUNDS)
            
            ;; Transfer reward to contract
            (try! (stx-transfer? reward tx-sender (as-contract tx-sender)))
            
            (map-set skill-challenges challenge-id
                (tuple
                    (creator tx-sender)
                    (skill skill)
                    (title title)
                    (description description)
                    (difficulty difficulty)
                    (reward reward)
                    (deadline deadline)
                    (max-participants max-participants)
                    (status "active")
                    (created-at stacks-block-height)))
            
            ;; Update creator reputation
            (map-set user-reputation tx-sender
                (merge creator-rep 
                    (tuple 
                        (challenges-created (+ (get challenges-created creator-rep) u1))
                        (last-activity stacks-block-height))))
            
            (var-set next-challenge-id (+ challenge-id u1))
            (unwrap-panic (log-security-event "challenge-created" tx-sender title))
            (unwrap-panic (clear-reentrancy))
            (ok challenge-id))))

(define-public (participate-in-challenge
    (challenge-id uint)
    (submission-hash (string-ascii 64)))
    (let ((challenge (unwrap! (map-get? skill-challenges challenge-id) ERR_NOT_FOUND)))
        (begin
            (try! (with-security-checks tx-sender ROLE_USER))
            (asserts! (validate-challenge-data challenge) ERR_INVALID_DATA)
            (asserts! (validate-medium-string submission-hash) ERR_INVALID_INPUT)
            (asserts! (is-eq (get status challenge) "active") ERR_CHALLENGE_NOT_ACTIVE)
            (asserts! (< stacks-block-height (get deadline challenge)) ERR_CHALLENGE_EXPIRED)
            (asserts! (not (is-eq tx-sender (get creator challenge))) ERR_INVALID_INPUT)
            (asserts! (is-none (map-get? challenge-participants 
                (tuple (challenge-id challenge-id) (participant tx-sender)))) ERR_ALREADY_EXISTS)
            
            (map-set challenge-participants
                (tuple (challenge-id challenge-id) (participant tx-sender))
                (tuple
                    (submission-hash submission-hash)
                    (submitted-at stacks-block-height)
                    (score u0)
                    (reviewed false)))
            
            (unwrap-panic (update-user-activity tx-sender))
            (unwrap-panic (clear-reentrancy))
            (ok "Participation recorded"))))

(define-public (review-challenge-submission
    (challenge-id uint)
    (participant principal)
    (score uint)
    (feedback (string-ascii 256)))
    (let ((challenge (unwrap! (map-get? skill-challenges challenge-id) ERR_NOT_FOUND))
          (submission (unwrap! (map-get? challenge-participants 
            (tuple (challenge-id challenge-id) (participant participant))) ERR_NOT_FOUND)))
        (begin
            (try! (with-security-checks tx-sender ROLE_VERIFIER))
            (asserts! (validate-challenge-data challenge) ERR_INVALID_DATA)
            (asserts! (validate-trusted-principal participant) ERR_INVALID_PRINCIPAL)
            (asserts! (or (is-eq tx-sender (get creator challenge)) 
                         (is-authorized-verifier tx-sender)) ERR_NOT_AUTHORIZED)
            (asserts! (validate-score score) ERR_INVALID_INPUT)
            (asserts! (validate-long-string feedback) ERR_INVALID_INPUT)
            
            (map-set challenge-reviews
                (tuple (challenge-id challenge-id) (participant participant) (reviewer tx-sender))
                (tuple
                    (score score)
                    (feedback feedback)
                    (reviewed-at stacks-block-height)))
            
            ;; Update submission with score
            (map-set challenge-participants
                (tuple (challenge-id challenge-id) (participant participant))
                (merge submission (tuple (score score) (reviewed true))))
            
            (unwrap-panic (clear-reentrancy))
            (ok "Review submitted"))))

(define-public (complete-challenge (challenge-id uint))
    (let ((challenge (unwrap! (map-get? skill-challenges challenge-id) ERR_NOT_FOUND)))
        (begin
            (try! (with-security-checks tx-sender ROLE_USER))
            (asserts! (validate-challenge-data challenge) ERR_INVALID_DATA)
            (asserts! (is-eq tx-sender (get creator challenge)) ERR_NOT_AUTHORIZED)
            (asserts! (is-eq (get status challenge) "active") ERR_CHALLENGE_NOT_ACTIVE)
            
            (map-set skill-challenges challenge-id
                (merge challenge (tuple (status "completed"))))
            
            ;; Award NFT to top performer (simplified logic)
            (try! (award-challenge-nft challenge-id))
            
            (unwrap-panic (clear-reentrancy))
            (ok "Challenge completed"))))

;; ============================================================================
;; REPUTATION & NFT FUNCTIONS (Enhanced with Security)
;; ============================================================================

(define-public (update-endorsement-accuracy
    (endorser principal)
    (endorsed principal)
    (skill (string-ascii 32))
    (accuracy-score uint))
    (begin
        (try! (with-security-checks tx-sender ROLE_VERIFIER))
        (asserts! (validate-trusted-principal endorser) ERR_INVALID_PRINCIPAL)
        (asserts! (validate-trusted-principal endorsed) ERR_INVALID_PRINCIPAL)
        (asserts! (validate-skill skill) ERR_INVALID_INPUT)
        (asserts! (validate-score accuracy-score) ERR_INVALID_INPUT)
        
        (let ((current-accuracy (default-to 
                (tuple (accuracy-score u50) (validation-count u0))
                (map-get? endorsement-accuracy 
                    (tuple (endorser endorser) (endorsed endorsed) (skill skill))))))
            (map-set endorsement-accuracy
                (tuple (endorser endorser) (endorsed endorsed) (skill skill))
                (tuple
                    (accuracy-score (/ (+ (* (get accuracy-score current-accuracy) 
                                            (get validation-count current-accuracy))
                                         accuracy-score)
                                      (+ (get validation-count current-accuracy) u1)))
                    (validation-count (+ (get validation-count current-accuracy) u1)))))
        
        (unwrap-panic (clear-reentrancy))
        (ok "Accuracy updated")))

(define-public (mint-skill-nft
    (recipient principal)
    (skill (string-ascii 32))
    (level (string-ascii 12))
    (achievement-type (string-ascii 32))
    (metadata-uri (string-ascii 256)))
    (let ((nft-id (var-get next-nft-id))
          (verification-score (get-endorsement-score recipient skill)))
        (begin
            (try! (with-security-checks tx-sender ROLE_VERIFIER))
            (asserts! (validate-trusted-principal recipient) ERR_INVALID_PRINCIPAL)
            (asserts! (validate-skill skill) ERR_INVALID_INPUT)
            (asserts! (validate-experience-level level) ERR_INVALID_INPUT)
            (asserts! (validate-achievement-type achievement-type) ERR_INVALID_INPUT)
            (asserts! (validate-long-string metadata-uri) ERR_INVALID_INPUT)
            
            (map-set skill-nfts nft-id
                (tuple
                    (owner recipient)
                    (skill skill)
                    (level level)
                    (verification-score verification-score)
                    (issue-date stacks-block-height)
                    (issuer tx-sender)
                    (metadata-uri metadata-uri)
                    (achievement-type achievement-type)))
            
            (map-set nft-ownership nft-id recipient)
            (map-set user-nft-count recipient 
                (+ (default-to u0 (map-get? user-nft-count recipient)) u1))
            
            (var-set next-nft-id (+ nft-id u1))
            (unwrap-panic (log-security-event "nft-minted" recipient achievement-type))
            (unwrap-panic (clear-reentrancy))
            (ok nft-id))))

(define-private (award-challenge-nft (challenge-id uint))
    (let ((challenge (unwrap! (map-get? skill-challenges challenge-id) ERR_NOT_FOUND)))
        (begin
            (asserts! (validate-challenge-data challenge) ERR_INVALID_DATA)
            ;; Simplified: award to challenge creator for now
            ;; In a full implementation, this would find the highest scoring participant
            (mint-skill-nft 
                (get creator challenge)
                (get skill challenge)
                "Expert"
                "challenge-winner"
                "https://experhive.com/nft/challenge-winner"))))

(define-public (transfer-nft (nft-id uint) (recipient principal))
    (let ((nft (unwrap! (map-get? skill-nfts nft-id) ERR_NFT_NOT_FOUND)))
        (begin
            (try! (with-security-checks tx-sender ROLE_USER))
            (asserts! (validate-nft-data nft) ERR_INVALID_DATA)
            (asserts! (is-eq tx-sender (get owner nft)) ERR_NOT_AUTHORIZED)
            (asserts! (validate-trusted-principal recipient) ERR_INVALID_PRINCIPAL)
            
            (map-set skill-nfts nft-id
                (merge nft (tuple (owner recipient))))
            (map-set nft-ownership nft-id recipient)
            
            ;; Update NFT counts safely
            (let ((sender-count (default-to u0 (map-get? user-nft-count tx-sender))))
                (map-set user-nft-count tx-sender 
                    (if (> sender-count u0) (- sender-count u1) u0)))
            (map-set user-nft-count recipient 
                (+ (default-to u0 (map-get? user-nft-count recipient)) u1))
            
            (unwrap-panic (log-security-event "nft-transferred" recipient "NFT transferred"))
            (unwrap-panic (clear-reentrancy))
            (ok "NFT transferred"))))

;; ============================================================================
;; REMAINING ORIGINAL FUNCTIONS (Enhanced with Security)
;; ============================================================================

(define-public (add-verified-skill 
    (user principal) 
    (skill (string-ascii 32)) 
    (category (string-ascii 32)))
    (begin
        (try! (with-security-checks tx-sender ROLE_VERIFIER))
        (asserts! (validate-trusted-principal user) ERR_INVALID_PRINCIPAL)
        (asserts! (validate-skill skill) ERR_INVALID_INPUT)
        (asserts! (validate-string-length category) ERR_INVALID_INPUT)
        (map-set verified-skills 
            (tuple (user user) (skill skill))
            (tuple (verified true) (verifier tx-sender)))
        (unwrap-panic (update-user-activity user))
        (unwrap-panic (clear-reentrancy))
        (ok "Skill verified")))

(define-public (endorse-with-expiry 
    (user principal) 
    (skill (string-ascii 32)))
    (begin
        (try! (with-security-checks tx-sender ROLE_USER))
        (asserts! (validate-trusted-principal user) ERR_INVALID_PRINCIPAL)
        (asserts! (validate-skill skill) ERR_INVALID_INPUT)
        (asserts! (check-skill-exists user skill) ERR_NOT_FOUND)
        (let ((current-block stacks-block-height))
            (begin
                (map-set endorsement-timestamps
                    (tuple (endorsed user) (endorser tx-sender) (skill skill))
                    current-block)
                (try! (endorse user skill))
                (unwrap-panic (clear-reentrancy))
                (ok "Endorsed with expiry")))))

(define-public (update-skill-experience
    (skill (string-ascii 32))
    (level (string-ascii 12))
    (years uint))
    (begin
        (try! (with-security-checks tx-sender ROLE_USER))
        (asserts! (validate-skill skill) ERR_INVALID_INPUT)
        (asserts! (validate-experience-level level) ERR_INVALID_INPUT)
        (asserts! (validate-years years) ERR_INVALID_INPUT)
        (asserts! (check-skill-exists tx-sender skill) ERR_NOT_FOUND)
        (map-set skill-experience
            (tuple (user tx-sender) (skill skill))
            (tuple (level level) (years years)))
        (unwrap-panic (update-user-activity tx-sender))
        (unwrap-panic (clear-reentrancy))
        (ok "Experience updated")))

(define-public (set-endorser-weight 
    (endorser principal) 
    (weight uint))
    (begin
        (try! (with-security-checks tx-sender ROLE_ADMIN))
        (asserts! (validate-trusted-principal endorser) ERR_INVALID_PRINCIPAL)
        (asserts! (validate-weight weight) ERR_INVALID_INPUT)
        (map-set endorser-weights endorser weight)
        (unwrap-panic (clear-reentrancy))
        (ok "Weight set")))

(define-public (add-skill-category (category (string-ascii 32)) (subcategories (list 10 (string-ascii 32))))
    (begin
        (try! (with-security-checks tx-sender ROLE_ADMIN))
        (asserts! (validate-string-length category) ERR_INVALID_INPUT)
        (map-set skill-categories category subcategories)
        (unwrap-panic (clear-reentrancy))
        (ok "Category added")))

(define-public (revoke-endorsement 
    (user principal) 
    (skill (string-ascii 32)))
    (let ((endorsers (get-endorsements user skill)))
        (begin
            (try! (with-security-checks tx-sender ROLE_USER))
            (asserts! (validate-trusted-principal user) ERR_INVALID_PRINCIPAL)
            (asserts! (validate-skill skill) ERR_INVALID_INPUT)
            (asserts! (is-some (index-of endorsers tx-sender)) ERR_NOT_FOUND)
            (map-set endorsements 
                (tuple (endorsed user) (skill skill))
                (filter remove-sender endorsers))
            (unwrap-panic (update-user-activity tx-sender))
            (unwrap-panic (clear-reentrancy))
            (ok "Endorsement revoked"))))

(define-public (verify-experience
    (user principal)
    (skill (string-ascii 32))
    (verified bool))
    (begin
        (try! (with-security-checks tx-sender ROLE_VERIFIER))
        (asserts! (validate-trusted-principal user) ERR_INVALID_PRINCIPAL)
        (asserts! (validate-skill skill) ERR_INVALID_INPUT)
        (map-set verified-skills
            (tuple (user user) (skill skill))
            (tuple (verified verified) (verifier tx-sender)))
        (unwrap-panic (update-user-activity user))
        (unwrap-panic (clear-reentrancy))
        (ok "Experience verified")))

;; ============================================================================
;; READ-ONLY FUNCTIONS (Enhanced with Security Info) - SECURITY ENHANCED
;; ============================================================================

(define-read-only (calculate-user-reputation (user principal))
    (let ((validated-user (if (is-standard user) user 'SP000000000000000000002Q6VF78))
          (current-rep (get-safe-reputation validated-user))
          (decay-factor (calculate-reputation-decay (get last-activity current-rep)))
          (base-score (get overall-score current-rep))
          (endorsement-bonus (* (get total-endorsements-received current-rep) u10))
          (challenge-bonus (* (get challenges-completed current-rep) u50))
          (accuracy-bonus (* (get endorsement-accuracy current-rep) u5))
          (fraud-penalty (* (get fraud-flags current-rep) u100)))
        (let ((new-score (+ base-score endorsement-bonus challenge-bonus accuracy-bonus)))
            (let ((final-score (if (> new-score fraud-penalty)
                                  (- new-score fraud-penalty)
                                  MIN_REPUTATION_SCORE)))
                (let ((decayed-score (if (> decay-factor u0)
                                       (if (> final-score (* decay-factor u10))
                                           (- final-score (* decay-factor u10))
                                           MIN_REPUTATION_SCORE)
                                       final-score)))
                    (clamp-uint decayed-score MIN_REPUTATION_SCORE MAX_REPUTATION_SCORE))))))

(define-read-only (get-challenge-details (challenge-id uint))
    (map-get? skill-challenges challenge-id))

(define-read-only (get-challenge-participation 
    (challenge-id uint) 
    (participant principal))
    (let ((validated-participant (if (is-standard participant) participant 'SP000000000000000000002Q6VF78)))
        (map-get? challenge-participants 
            (tuple (challenge-id challenge-id) (participant validated-participant)))))

(define-read-only (get-user-reputation-score (user principal))
    (calculate-user-reputation user))

(define-read-only (get-nft-details (nft-id uint))
    (map-get? skill-nfts nft-id))

(define-read-only (get-user-nfts (user principal))
    (let ((validated-user (if (is-standard user) user 'SP000000000000000000002Q6VF78)))
        (default-to u0 (map-get? user-nft-count validated-user))))

(define-read-only (get-weighted-endorsements 
    (user principal) 
    (skill (string-ascii 32)))
    (let ((endorsers (get-endorsements user skill)))
        (fold + (map get-endorser-weight endorsers) u0)))

(define-read-only (get-endorsements (user principal) (skill (string-ascii 32)))
    (let ((validated-user (if (is-standard user) user 'SP000000000000000000002Q6VF78))
          (endorsement-list (default-to (list) (map-get? endorsements (tuple (endorsed validated-user) (skill skill))))))
        ;; Validate that we have a proper list
        (if (> (len endorsement-list) u10)
            (list) ;; Return empty list if somehow corrupted
            endorsement-list)))

(define-read-only (get-skill-rating (user principal) (skill (string-ascii 32)))
    (let ((ratings (get-safe-ratings user skill)))
        (if (is-eq (get rating-count ratings) u0)
            u0
            (/ (get total-score ratings) (get rating-count ratings)))))

(define-read-only (can-rate-skill (rater principal) (user principal))
    (and 
        (not (is-eq rater user))
        (> (default-to u0 (map-get? endorser-weights rater)) u0)))

(define-read-only (get-endorsement-score
    (user principal)
    (skill (string-ascii 32)))
    (let ((weighted-score (get-weighted-endorsements user skill))
          (rating-score (get-skill-rating user skill))
          (reputation-bonus (/ (get-user-reputation-score user) u100)))
        (+ (* weighted-score u2) rating-score reputation-bonus)))

(define-read-only (get-skill-details
    (user principal)
    (skill (string-ascii 32)))
    (let ((validated-user (if (is-standard user) user 'SP000000000000000000002Q6VF78)))
        (tuple 
            (experience (map-get? skill-experience (tuple (user validated-user) (skill skill))))
            (endorsements (get-endorsements validated-user skill))
            (rating (get-skill-rating validated-user skill))
            (verification (map-get? verified-skills (tuple (user validated-user) (skill skill))))
            (reputation-score (get-user-reputation-score validated-user))
            (endorsement-score (get-endorsement-score validated-user skill)))))

(define-read-only (get-skill-category (category (string-ascii 32)))
    (default-to (list) (map-get? skill-categories category)))

(define-read-only (is-endorsement-valid 
    (endorsed principal) 
    (endorser principal) 
    (skill (string-ascii 32)))
    (let ((validated-endorsed (if (is-standard endorsed) endorsed 'SP000000000000000000002Q6VF78))
          (validated-endorser (if (is-standard endorser) endorser 'SP000000000000000000002Q6VF78))
          (timestamp (default-to u0 
            (map-get? endorsement-timestamps 
                (tuple (endorsed validated-endorsed) (endorser validated-endorser) (skill skill))))))
        (and 
            (> timestamp u0)
            (>= (+ timestamp ENDORSEMENT_EXPIRY_BLOCKS) stacks-block-height))))

(define-read-only (get-verified-experience
    (user principal)
    (skill (string-ascii 32)))
    (let ((validated-user (if (is-standard user) user 'SP000000000000000000002Q6VF78)))
        (map-get? verified-skills (tuple (user validated-user) (skill skill)))))

;; ============================================================================
;; SECURITY READ-ONLY FUNCTIONS
;; ============================================================================

(define-read-only (get-user-role (user principal))
    (let ((validated-user (if (is-standard user) user 'SP000000000000000000002Q6VF78)))
        (default-to ROLE_USER (map-get? user-roles validated-user))))

(define-read-only (is-contract-paused)
    (var-get contract-paused))

(define-read-only (is-emergency-mode-active)
    (var-get emergency-mode))

(define-read-only (get-user-rate-limit (user principal))
    (let ((current-window (/ stacks-block-height RATE_LIMIT_WINDOW))
          (validated-user (if (is-standard user) user 'SP000000000000000000002Q6VF78)))
        (default-to u0 (map-get? user-action-count (tuple (user validated-user) (window current-window))))))

(define-read-only (get-pending-operation (operation-id uint))
    (map-get? pending-operations operation-id))

(define-read-only (get-security-event (event-id uint))
    (map-get? security-events event-id))

(define-read-only (has-operation-approval (operation-id uint) (approver principal))
    (let ((validated-approver (if (is-standard approver) approver 'SP000000000000000000002Q6VF78)))
        (default-to false (map-get? operation-approvals (tuple (operation-id operation-id) (approver validated-approver))))))

;; ============================================================================
;; CONTRACT INITIALIZATION
;; ============================================================================

;; Initialize default achievement requirements
(map-set achievement-requirements "skill-mastery"
    (tuple (min-endorsements u5) (min-rating u4) (min-challenges u2) (min-reputation u2000)))
(map-set achievement-requirements "challenge-winner"
    (tuple (min-endorsements u3) (min-rating u3) (min-challenges u1) (min-reputation u1500)))
(map-set achievement-requirements "top-endorser"
    (tuple (min-endorsements u10) (min-rating u4) (min-challenges u0) (min-reputation u2500)))
(map-set achievement-requirements "mentor"
    (tuple (min-endorsements u15) (min-rating u5) (min-challenges u5) (min-reputation u5000)))
(map-set achievement-requirements "learner"
    (tuple (min-endorsements u1) (min-rating u2) (min-challenges u0) (min-reputation u500)))
