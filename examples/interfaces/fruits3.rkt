#lang racket

;; Banana implements Edible, but relies on its superclass Fruit to actually implement the required methods.

(require (only-in "../../objects.rkt" → Root INTERFACE CLASS new cast-up))
(require test-engine/racket-tests)

(define Edible
  (INTERFACE
   ()
   ([method eat])))

(define Peelable
  (INTERFACE
   ()
   ([method peel])))

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
         ([field peeled #f])
         ([method peel () (if (? peeled)
                              (printf "This banana has already been peeled~n")
                              (begin
                                (printf "You peel the banana and marvel at its glory~n")
                                (! peeled #t)))])))

(define edibleBanana (new Edible Banana))

(define Eater
  (CLASS extends Root
         ()
         ([field my-food '()])
         ([method set-food (food) (let ([valid-food (cast-up Edible food)])
                                      (! my-food valid-food))]
          [method eat-food () (→ (? my-food) eat)]
          [method get-food () (? my-food)])))

(define eater (new Eater Eater))
(define banana (new Banana Banana))
(→ eater set-food banana)
(→ eater eat-food)
(→ eater eat-food)

;; Note that we are getting back the Banana in Edible form. We should NOT be able to Peel it.
(define eatersFood (→ eater get-food))
(check-error (→ eatersFood peel) "method")

;; But, we should still be able to Peel the Banana-type reference to the Banana.
(→ banana peel)