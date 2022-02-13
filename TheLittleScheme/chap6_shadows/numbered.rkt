#lang racket
; The atom? primitive
;
(define atom?
    (lambda (x)
        (and (not (pair? x)) (not (null? x)))))

; The numbered? function determines whether a representation of an arithmetic
; expression contains only numbers besides the o+, ox and o^ (for +, * and exp).
;
(define numbered?
    (lambda (aexp) 
        (cond 
            ((atom? aexp) (number? aexp))
            ((eq? (car (cdr aexp)) 'o+)
                (and (numbered? (car aexp))
                    (numbered? (car (cdr (cdr aexp))))))       ; 加上 car 是因为最后的 cdr 会加上 ()
            ((eq? (car (cdr aexp)) 'ox)
                (and (numbered? (car aexp))
                    (numbered? (car (cdr (cdr aexp))))))
            ((eq? (car (cdr aexp)) 'o^)
                (and (numbered? (car aexp))
                    (numbered? (car (cdr (cdr aexp))))))
            (else #f))))

; Examples of numbered?
;
(display "------ numbered? ------\n")
(numbered? '5)                               ; #t
(numbered? '(5 o+ 5))                        ; #t
(numbered? '(5 o+ a))                        ; #f
(numbered? '(5 ox (3 o^ 2)))                 ; #t
(numbered? '(5 ox (3 'foo 2)))               ; #f
(numbered? '((5 o+ 2) ox (3 o^ 2)))          ; #t
(numbered? '((5 o+ 2) ox (3 o^ (5 o+ 2))))          ; #t

(define aexp '((5 o+ 2) ox (3 o^ (5 o+ 2))))
(car aexp)                  ; '(5 o+ 2)
(cdr aexp)                  ; '(ox (3 o^ (5 o+ 2)))
(cdr (cdr aexp))            ; '((3 o^ (5 o+ 2)))
(car (cdr (cdr aexp)))      ; '(3 o^ (5 o+ 2))

; Assuming aexp is a numeric expression, numbered? can be simplified
;
(define numbered2?
    (lambda (aexp) 
        (cond 
            ((atom? aexp) (number? aexp))
            (else 
                (and (numbered2? (car aexp))
                    (numbered2? (car (cdr (cdr aexp)))))) )))

; Tests of numbered?
;
(display "------ numbered2? ------\n")
(numbered2? '5)                               ; #t
(numbered2? '(5 o+ 5))                        ; #t
(numbered2? '(5 ox (3 o^ 2)))                 ; #t
(numbered2? '((5 o+ 2) ox (3 o^ 2)))          ; #t


; The value function determines the value of an arithmetic expression
;
(define value
    (lambda (nexp) 
        (cond 
            ((atom? nexp) nexp)
            ((eq? (car (cdr nexp)) 'o+)
                (+ (value (car nexp))
                    (value (car (cdr (cdr nexp))))))
            ((eq? (car (cdr nexp)) 'ox)
                (* (value (car nexp))
                    (value (car (cdr (cdr nexp))))))
            (else 
                (expt (value (car nexp))
                    (value (car (cdr (cdr nexp)))))))))

; Examples of value
;
(display "------ value ------\n")
(value 13)                                   ; 13
(value '(1 o+ 3))                            ; 4
(value '(1 o+ (3 o^ 4)))                     ; 82


; It's best to invent 1st-sub-exp and 2nd-sub-exp functions
; instead of writing (car (cdr (cdr nexp))), etc.
; These are for prefix notation.
; eg (* 2 3)
;
(define 1st-sub-exp
    (lambda (aexp)
        (car (cdr aexp))))

(define 2nd-sub-exp
    (lambda (aexp)
        (car (cdr (cdr aexp))) ))

(define operator
    (lambda (aexp)
        (car aexp)))

(define value-prefix
    (lambda (nexp) 
        (cond 
            ((atom? nexp) nexp)
            ((eq? (operator nexp) 'o+) 
                (+ (value-prefix (1st-sub-exp nexp))
                    (value-prefix (2nd-sub-exp nexp))))
            ((eq? (operator nexp) 'ox)
                (* (value-prefix (1st-sub-exp nexp))
                    (value-prefix (2nd-sub-exp nexp))))
            ((eq? (operator nexp) 'o^)
                (expt (value-prefix (1st-sub-exp nexp))
                    (value-prefix (2nd-sub-exp nexp))))
            (else #f))))

; Examples of value-prefix-helper
;
(display "------ value-prefix ------\n")
(value-prefix 13)                            ; 13
(value-prefix '(o+ 3 4))                     ; 7
(value-prefix '(ox 3 4))                     ; 12
(value-prefix '(ox 3 (o+ 5 6)))              ; 33
(value-prefix '(o+ 1 (o^ 3 4)))              ; 82