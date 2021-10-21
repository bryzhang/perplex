#lang racket

;; Fruit claims to implement Edible, but does not actually implement eat().

(require (only-in "../../objects.rkt" → Root INTERFACE CLASS new cast-up))
(require test-engine/racket-tests)

(define Edible
  (INTERFACE
   ()
   ([method eat])))

(check-error (define Fruit
  (CLASS extends Root
         ([interface Edible])
         ([field fcounter 0])
         ())))