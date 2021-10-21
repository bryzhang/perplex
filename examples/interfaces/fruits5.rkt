#lang racket

;; Fruit implements eat() but does not actually declare itself as an implementer of Edible.

(require (only-in "../../objects.rkt" → Root INTERFACE CLASS new cast-up))
(require test-engine/racket-tests)

(define Edible
  (INTERFACE
   ()
   ([method eat])))

(define Fruit
  (CLASS extends Root
         ()
         ([field fcounter 0])
         ([method eat () (begin
                           (! fcounter (+ (? fcounter) 1))
                           (printf "Yum! This fruit has been eaten ~v times~n" (? fcounter)))])))

(define fruit (new Fruit Fruit))
(check-error (cast-up Edible fruit))