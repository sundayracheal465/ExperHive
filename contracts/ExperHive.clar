;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ENDORSEMENT_EXPIRY_BLOCKS u52560) ;; ~365 days
(define-constant CHALLENGE_DURATION_BLOCKS u1440) ;; ~10 days
(define-constant REPUTATION_DECAY_BLOCKS u7200) ;; ~50 days
(define-constant MAX_REPUTATION_SCORE u10000)
(define-constant MIN_REPUTATION_SCORE u100)

;; Error Constants
(define-constant ERR_NOT_AUTHORIZED (err u403))
(define-constant ERR_INVALID_INPUT (err u400))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_ALREADY_EXISTS (err u409))
(define-constant ERR_INSUFFICIENT_FUNDS (err u402))
(define-constant ERR_CHALLENGE_EXPIRED (err u410))
(define-constant ERR_CHALLENGE_NOT_ACTIVE (err u411))
(define-constant ERR_NFT_NOT_FOUND (err u412))
(define-constant ERR_INVALID_DATA (err u413))

;; Data Variables
(define-data-var next-challenge-id uint u1)
(define-data-var next-nft-id uint u1)
(define-data-var platform-fee-rate uint u250) ;; 2.5%

;; Original Maps
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

;; New Maps for Enhanced Features

;; 1. Skill-Based Challenge System
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

;; 2. Dynamic Reputation & Trust Scoring
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

;; 5. Skill NFT Certificates & Achievements
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

;; Private Functions - Validation (Enhanced)
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
    (not (is-eq user tx-sender)))

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

;; Enhanced validation for challenge data
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

;; Enhanced validation for NFT data
(define-private (validate-nft-data (nft (tuple (owner principal) (skill (string-ascii 32)) (level (string-ascii 12)) (verification-score uint) (issue-date uint) (issuer principal) (metadata-uri (string-ascii 256)) (achievement-type (string-ascii 32)))))
    (and
        (validate-skill (get skill nft))
        (validate-experience-level (get level nft))
        (validate-score (get verification-score nft))
        (validate-block-height (get issue-date nft))
        (validate-long-string (get metadata-uri nft))
        (validate-achievement-type (get achievement-type nft))))

;; Helper functions for min/max since they don't exist in Clarity
(define-private (min-uint (a uint) (b uint))
    (if (<= a b) a b))

(define-private (max-uint (a uint) (b uint))
    (if (>= a b) a b))

(define-private (clamp-uint (value uint) (min-val uint) (max-val uint))
    (min-uint (max-uint value min-val) max-val))

;; Private Functions - Helpers (Enhanced)
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
    (default-to false (map-get? authorized-verifiers caller)))

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
        (map-set user-reputation user
            (merge current-rep (tuple (last-activity stacks-block-height))))))

;; Original Public Functions (Enhanced with reputation updates)

(define-public (add-authorized-verifier (verifier principal))
    (begin
        (asserts! (is-contract-owner tx-sender) ERR_NOT_AUTHORIZED)
        (asserts! (validate-principal verifier) ERR_INVALID_INPUT)
        (map-set authorized-verifiers verifier true)
        (ok "Verifier added")))

(define-public (add-skill (skill (string-ascii 32)))
    (begin
        (asserts! (validate-skill skill) ERR_INVALID_INPUT)
        (let ((existing (default-to (list) (map-get? skills {user: tx-sender}))))
            (begin
                (asserts! (< (len existing) u10) ERR_INVALID_INPUT)
                (asserts! (not (is-some (index-of existing skill))) ERR_INVALID_INPUT)
                (map-set skills {user: tx-sender} 
                    (unwrap! (as-max-len? (append existing skill) u10) ERR_INVALID_INPUT))
                (update-user-activity tx-sender)
                (ok "Skill added")))))

(define-public (endorse (user principal) (skill (string-ascii 32)))
    (begin
        (asserts! (validate-principal user) ERR_INVALID_INPUT)
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
                (ok "Endorsed")))))

(define-public (rate-skill (user principal) (skill (string-ascii 32)) (rating uint))
    (begin
        (asserts! (validate-principal user) ERR_INVALID_INPUT)
        (asserts! (validate-skill skill) ERR_INVALID_INPUT)
        (asserts! (validate-rating rating) ERR_INVALID_INPUT)
        (asserts! (check-skill-exists user skill) ERR_NOT_FOUND)
        (asserts! (can-rate-skill tx-sender user) ERR_NOT_AUTHORIZED)
        (let ((current-ratings (get-safe-ratings user skill)))
            (map-set skill-ratings 
                (tuple (rated user) (skill skill))
                (tuple 
                    (total-score (+ (get total-score current-ratings) rating))
                    (rating-count (+ (get rating-count current-ratings) u1))))
            (update-user-activity tx-sender)
            (ok "Rating added"))))

;; 1. Skill-Based Challenge System Functions

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
            (asserts! (validate-skill skill) ERR_INVALID_INPUT)
            (asserts! (validate-medium-string title) ERR_INVALID_INPUT)
            (asserts! (validate-long-string description) ERR_INVALID_INPUT)
            (asserts! (validate-difficulty difficulty) ERR_INVALID_INPUT)
            (asserts! (validate-reward-amount reward) ERR_INVALID_INPUT)
            (asserts! (> duration-blocks u0) ERR_INVALID_INPUT)
            (asserts! (> max-participants u0) ERR_INVALID_INPUT)
            (asserts! (<= max-participants u100) ERR_INVALID_INPUT) ;; Reasonable limit
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
            (ok challenge-id))))

(define-public (participate-in-challenge
    (challenge-id uint)
    (submission-hash (string-ascii 64)))
    (let ((challenge (unwrap! (map-get? skill-challenges challenge-id) ERR_NOT_FOUND)))
        (begin
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
            
            (update-user-activity tx-sender)
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
            (asserts! (validate-challenge-data challenge) ERR_INVALID_DATA)
            (asserts! (validate-principal participant) ERR_INVALID_INPUT)
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
            
            (ok "Review submitted"))))

(define-public (complete-challenge (challenge-id uint))
    (let ((challenge (unwrap! (map-get? skill-challenges challenge-id) ERR_NOT_FOUND)))
        (begin
            (asserts! (validate-challenge-data challenge) ERR_INVALID_DATA)
            (asserts! (is-eq tx-sender (get creator challenge)) ERR_NOT_AUTHORIZED)
            (asserts! (is-eq (get status challenge) "active") ERR_CHALLENGE_NOT_ACTIVE)
            
            (map-set skill-challenges challenge-id
                (merge challenge (tuple (status "completed"))))
            
            ;; Award NFT to top performer (simplified logic)
            (try! (award-challenge-nft challenge-id))
            
            (ok "Challenge completed"))))

;; 2. Dynamic Reputation & Trust Scoring Functions

(define-public (update-endorsement-accuracy
    (endorser principal)
    (endorsed principal)
    (skill (string-ascii 32))
    (accuracy-score uint))
    (begin
        (asserts! (is-authorized-verifier tx-sender) ERR_NOT_AUTHORIZED)
        (asserts! (validate-principal endorser) ERR_INVALID_INPUT)
        (asserts! (validate-principal endorsed) ERR_INVALID_INPUT)
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
        
        (ok "Accuracy updated")))

;; Changed from public to read-only since it only calculates and returns a value
(define-read-only (calculate-user-reputation (user principal))
    (let ((current-rep (get-safe-reputation user))
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

;; 5. Skill NFT Certificates & Achievements Functions

(define-public (mint-skill-nft
    (recipient principal)
    (skill (string-ascii 32))
    (level (string-ascii 12))
    (achievement-type (string-ascii 32))
    (metadata-uri (string-ascii 256)))
    (let ((nft-id (var-get next-nft-id))
          (verification-score (get-endorsement-score recipient skill)))
        (begin
            (asserts! (is-authorized-verifier tx-sender) ERR_NOT_AUTHORIZED)
            (asserts! (validate-principal recipient) ERR_INVALID_INPUT)
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
            (asserts! (validate-nft-data nft) ERR_INVALID_DATA)
            (asserts! (is-eq tx-sender (get owner nft)) ERR_NOT_AUTHORIZED)
            (asserts! (validate-principal recipient) ERR_INVALID_INPUT)
            
            (map-set skill-nfts nft-id
                (merge nft (tuple (owner recipient))))
            (map-set nft-ownership nft-id recipient)
            
            ;; Update NFT counts safely
            (let ((sender-count (default-to u0 (map-get? user-nft-count tx-sender))))
                (map-set user-nft-count tx-sender 
                    (if (> sender-count u0) (- sender-count u1) u0)))
            (map-set user-nft-count recipient 
                (+ (default-to u0 (map-get? user-nft-count recipient)) u1))
            
            (ok "NFT transferred"))))

;; Enhanced Read-Only Functions

(define-read-only (get-challenge-details (challenge-id uint))
    (map-get? skill-challenges challenge-id))

(define-read-only (get-challenge-participation 
    (challenge-id uint) 
    (participant principal))
    (map-get? challenge-participants 
        (tuple (challenge-id challenge-id) (participant participant))))

(define-read-only (get-user-reputation-score (user principal))
    (calculate-user-reputation user))

(define-read-only (get-nft-details (nft-id uint))
    (map-get? skill-nfts nft-id))

(define-read-only (get-user-nfts (user principal))
    (default-to u0 (map-get? user-nft-count user)))

(define-read-only (get-weighted-endorsements 
    (user principal) 
    (skill (string-ascii 32)))
    (let ((endorsers (get-endorsements user skill)))
        (fold + (map get-endorser-weight endorsers) u0)))

(define-read-only (get-endorsements (user principal) (skill (string-ascii 32)))
    (let ((endorsement-list (default-to (list) (map-get? endorsements (tuple (endorsed user) (skill skill))))))
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
    (tuple 
        (experience (map-get? skill-experience (tuple (user user) (skill skill))))
        (endorsements (get-endorsements user skill))
        (rating (get-skill-rating user skill))
        (verification (map-get? verified-skills (tuple (user user) (skill skill))))
        (reputation-score (get-user-reputation-score user))
        (endorsement-score (get-endorsement-score user skill))))

;; Remaining original functions (unchanged but with reputation updates where applicable)

(define-public (add-verified-skill 
    (user principal) 
    (skill (string-ascii 32)) 
    (category (string-ascii 32)))
    (begin
        (asserts! (is-authorized-verifier tx-sender) ERR_NOT_AUTHORIZED)
        (asserts! (validate-principal user) ERR_INVALID_INPUT)
        (asserts! (validate-skill skill) ERR_INVALID_INPUT)
        (asserts! (validate-string-length category) ERR_INVALID_INPUT)
        (map-set verified-skills 
            (tuple (user user) (skill skill))
            (tuple (verified true) (verifier tx-sender)))
        (update-user-activity user)
        (ok "Skill verified")))

(define-public (endorse-with-expiry 
    (user principal) 
    (skill (string-ascii 32)))
    (begin
        (asserts! (validate-principal user) ERR_INVALID_INPUT)
        (asserts! (validate-skill skill) ERR_INVALID_INPUT)
        (asserts! (check-skill-exists user skill) ERR_NOT_FOUND)
        (let ((current-block stacks-block-height))
            (begin
                (map-set endorsement-timestamps
                    (tuple (endorsed user) (endorser tx-sender) (skill skill))
                    current-block)
                (endorse user skill)))))

(define-public (update-skill-experience
    (skill (string-ascii 32))
    (level (string-ascii 12))
    (years uint))
    (begin
        (asserts! (validate-skill skill) ERR_INVALID_INPUT)
        (asserts! (validate-experience-level level) ERR_INVALID_INPUT)
        (asserts! (validate-years years) ERR_INVALID_INPUT)
        (asserts! (check-skill-exists tx-sender skill) ERR_NOT_FOUND)
        (map-set skill-experience
            (tuple (user tx-sender) (skill skill))
            (tuple (level level) (years years)))
        (update-user-activity tx-sender)
        (ok "Experience updated")))

(define-public (set-endorser-weight 
    (endorser principal) 
    (weight uint))
    (begin
        (asserts! (is-contract-owner tx-sender) ERR_NOT_AUTHORIZED)
        (asserts! (validate-principal endorser) ERR_INVALID_INPUT)
        (asserts! (validate-weight weight) ERR_INVALID_INPUT)
        (map-set endorser-weights endorser weight)
        (ok "Weight set")))

(define-public (add-skill-category (category (string-ascii 32)) (subcategories (list 10 (string-ascii 32))))
    (begin
        (asserts! (is-contract-owner tx-sender) ERR_NOT_AUTHORIZED)
        (asserts! (validate-string-length category) ERR_INVALID_INPUT)
        (map-set skill-categories category subcategories)
        (ok "Category added")))

(define-public (revoke-endorsement 
    (user principal) 
    (skill (string-ascii 32)))
    (let ((endorsers (get-endorsements user skill)))
        (begin
            (asserts! (validate-principal user) ERR_INVALID_INPUT)
            (asserts! (validate-skill skill) ERR_INVALID_INPUT)
            (asserts! (is-some (index-of endorsers tx-sender)) ERR_NOT_FOUND)
            (map-set endorsements 
                (tuple (endorsed user) (skill skill))
                (filter remove-sender endorsers))
            (update-user-activity tx-sender)
            (ok "Endorsement revoked"))))

(define-public (verify-experience
    (user principal)
    (skill (string-ascii 32))
    (verified bool))
    (begin
        (asserts! (is-authorized-verifier tx-sender) ERR_NOT_AUTHORIZED)
        (asserts! (validate-principal user) ERR_INVALID_INPUT)
        (asserts! (validate-skill skill) ERR_INVALID_INPUT)
        (map-set verified-skills
            (tuple (user user) (skill skill))
            (tuple (verified verified) (verifier tx-sender)))
        (update-user-activity user)
        (ok "Experience verified")))

(define-read-only (get-skill-category (category (string-ascii 32)))
    (default-to (list) (map-get? skill-categories category)))

(define-read-only (is-endorsement-valid 
    (endorsed principal) 
    (endorser principal) 
    (skill (string-ascii 32)))
    (let ((timestamp (default-to u0 
            (map-get? endorsement-timestamps 
                (tuple (endorsed endorsed) (endorser endorser) (skill skill))))))
        (and 
            (> timestamp u0)
            (>= (+ timestamp ENDORSEMENT_EXPIRY_BLOCKS) stacks-block-height))))

(define-read-only (get-verified-experience
    (user principal)
    (skill (string-ascii 32)))
    (map-get? verified-skills (tuple (user user) (skill skill))))

;; Example usage:
;; Add a skill to your profile
;; (contract-call? .experhive add-skill "JavaScript")

;; Endorse another user's skill
;; (contract-call? .experhive endorse 'SP1ABC...DEF "JavaScript")

;; Create a coding challenge
;; (contract-call? .experhive create-challenge "JavaScript" "Build a DeFi App" "Create a decentralized exchange" u3 u1000000 u1440 u10)

;; Participate in a challenge
;; (contract-call? .experhive participate-in-challenge u1 "ipfs://QmABC123...")

;; Check user's reputation score
;; (contract-call? .experhive get-user-reputation-score 'SP1ABC...DEF)