#lang racket

;; We both know that it's a Banana, but once you cast it to a Fruit, there's no going back.

(require (only-in "../../objects.rkt" → Root INTERFACE CLASS new cast-up))
(require test-engine/racket-tests)

(define Edible
  (INTERFACE
   ()
   ([method eat])))

(define Fruit
  (CLASS extends Root
         ([interface Edible])
         ([field fcounter 0])
         ([method eat () (begin
                           (! fcounter (+ (? fcounter) 1))
                           (printf "Yum! This fruit has been eaten ~v times~n" (? fcounter)))])))

(define Banana
  (CLASS extends Fruit
         ([interface Edible])
         ([field bcounter 0]
          [field peeled #f])
         ([method peel () (if (? peeled)
                              (printf "This banana has already been peeled~n")
                              (begin
                                (printf "You peel the banana and marvel at its glory~n")
                                (! peeled #t)))])))

(define banana (new Banana Banana))
(define fruitifiedBanana (cast-up Fruit banana))
(check-error (→ peel fruitifiedBanana))
(check-error (cast-up Banana fruitifiedBanana))