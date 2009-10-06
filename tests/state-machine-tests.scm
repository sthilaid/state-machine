;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Test suite for the state machine system
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(include "test-macro.scm")
(include "../include/scm-lib_.scm") ;; req by test-macro
(include "../include/class.scm")
(include "../include/state-machine.scm")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Predicate test
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (gen-state sym) (lambda (_) (write sym)))
(define (empty-state _) '...)
(define-state-machine pred-test-sm
  'A
  ((A empty-state)
   (B empty-state)
   (C empty-state))
  ((* * empty-state)))
(define-test predicate-test "YNNNYNNNY" 'ok
  (let ((out (lambda (x) (write (if x 'Y 'N))))
        (sm (new pred-test-sm)))
    (out (pred-test-sm-A? sm))
    (out (pred-test-sm-B? sm))
    (out (pred-test-sm-C? sm))
    (transition sm 'B)
    (out (pred-test-sm-A? sm))
    (out (pred-test-sm-B? sm))
    (out (pred-test-sm-C? sm))
    (transition sm 'C)
    (out (pred-test-sm-A? sm))
    (out (pred-test-sm-B? sm))
    (out (pred-test-sm-C? sm))
    'ok))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Usage exemple: Simple state machine test
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-state-machine simple-sm
  'A
  ((A (lambda (_) (write 'A)))
   (B (lambda (_) (write 'B)))
   (C (lambda (_) (write 'C)))
   (D (lambda (_) (write 'D))))
  ((A B (lambda (_) (write 'ab)))
   (A C (lambda (_) (write 'ac)))
   (C D (lambda (_) (write 'cd)))
   (* A (lambda (_) (write '*a)))
   (* * (lambda (_) (write '**)))))

(define-test simple-test "AabB**D*aAacCcdD" 'ok
  (let ((sm (new simple-sm)))
    (state-machine-start sm)
    (transition sm 'B)
    (transition sm 'D)
    (transition sm 'A)
    (transition sm 'C)
    (transition sm 'D)
    'ok))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Usage exemple: Binary string parser
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-class binary-analysis (state-machine)
  (slot: bin-str)
  (slot: decimal-number)
  (constructor: (lambda (self input)
                  (set-fields! self binary-analysis
                               ((bin-str input) (decimal-number 0)))
                  (init! cast: '(state-machine) self))))

(define (binary-analysis-next-state! ba)
  (let ((str (binary-analysis-bin-str ba)))
    (if (string=? str "")
        'finished!
        (case (string-ref str 0)
          ((#\0) 'zero)
          ((#\1) 'one)
          (else 'error)))))

(define-state-machine binary-analysis
  'start
  ((start (lambda (self)
            (transition self (binary-analysis-next-state! self))))
   (zero (lambda (self)
           (update! self binary-analysis bin-str
                    (lambda (b) (substring b 1 (string-length b))))
           (update! self binary-analysis decimal-number
                    (lambda (x) (* x 2)))
           (transition self (binary-analysis-next-state! self))))
   (one (lambda (self)
          (update! self binary-analysis bin-str
                   (lambda (b) (substring b 1 (string-length b))))
          (update! self binary-analysis decimal-number
                   (lambda (x) (+ (* x 2) 1)))
          (transition self (binary-analysis-next-state! self))))
   (error (lambda (_) (pp "invalid binary number!")))
   (finished! (lambda (self) (binary-analysis-decimal-number self))))
  ((* * (lambda (_) 'O_o)))
  create-new-class?: #f)

(define-test binary-analysis "" 171
  (state-machine-start (new binary-analysis "10101011")))
