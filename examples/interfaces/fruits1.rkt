#lang racket

;; Fruit and Banana both implement Edible.
;; Banana extends Fruit.
;; FruitEater expects to eat a Fruit.
;; If we provide a Banana, cast to a Fruit, we should see that it is the Banana's "eat" which gets called.

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
         ([field bcounter 0])
         ([method eat () (begin
                           (! bcounter (+ (? bcounter) 1))
                           (printf "Yum! This banana has been eaten ~v times~n" (? bcounter)))])))

(define b1 (new Banana Banana))

(define FruitEater
  (CLASS extends Root
         ()
         ([field my-fruit '()])
         ([method set-fruit (fruit) (let ([valid-fruit (cast-up Fruit fruit)])
                                      (! my-fruit valid-fruit))]
          [method eat-fruit () (→ (? my-fruit) eat)])))

(define e1 (new FruitEater FruitEater))
(→ e1 set-fruit b1)
(→ e1 eat-fruit)
(→ b1 eat)
(→ e1 eat-fruit)