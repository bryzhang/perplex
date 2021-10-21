#lang racket

;; Fruit does not implement Edible. Banana does.

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
         ([method observe () (begin
                           (! fcounter (+ (? fcounter) 1))
                           (printf "You gaze intently at your fruit for observation #~v~n" (? fcounter)))])))

(define Banana
  (CLASS extends Fruit
         ([interface Edible])
         ([field bcounter 0])
         ([method eat() (begin
                          (! bcounter (+ (? bcounter) 1))
                          (printf "Yum! You've eaten this Banana ~v times~n" (? bcounter)))])))


;; Casting the Banana to its superclass or interface type is fine.
(define banana (new Banana Banana))
(define fruityBanana (cast-up Fruit banana))
(→ fruityBanana observe)
(define edibleBanana (cast-up Edible banana))
(→ edibleBanana eat)

;; Casting a Fruit to Edible should fail, even if the underlying Banana implements Edible.
(check-error (cast-up Edible fruityBanana))
