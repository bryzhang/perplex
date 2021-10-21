#lang racket

;; Underlying Object is persistent, even when it is passed around and cast to different types.

(require (only-in "../../objects.rkt" → Root INTERFACE CLASS MIXIN new cast-up))
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

(define Bread
  (CLASS extends Root
         ([interface Edible])
         ([field bcounter 0]
          [field fed-birds #f])
         ([method eat () (if (? fed-birds)
                             (begin
                               (printf "This bread is being eaten by the birds. Try again~n")
                               (! fed-birds #f))
                             (begin
                               (! bcounter (+ (? bcounter) 1))
                               (printf "Yum! This bread has been eaten ~v times~n" (? bcounter))))]
          [method feed-to-birds () (begin
                                    (printf "You scatter breadcrumbs and watch contentedly as the birds peck at them~n")
                                    (! fed-birds #t))])))

;; Side note: You cannot instantiate an interface.
(check-error (define food (new Edible Edible)))

;; Eater takes in any Edible food.
(define Eater
  (CLASS extends Root
         ()
         ([field my-food '()])
         ([method set-food (food) (let ([valid-food (cast-up Edible food)])
                                      (! my-food valid-food))]
          [method eat-food () (→ (? my-food) eat)])))

;; BirdFeeder holds its own Bread and feeds it to the birds.
(define BirdFeeder
  (CLASS extends Root
         ()
         ([field my-bread (new Bread Bread)])
         ([method feed-birds () (→ (? my-bread) feed-to-birds)]
          [method get-bread () (? my-bread)])))

;; Our foodEater will try to eat the BirdFeeder's Bread.
(define foodEater (new Eater Eater))
(define birdFeeder (new BirdFeeder BirdFeeder))

(→ birdFeeder feed-birds)
(→ foodEater set-food (→ birdFeeder get-bread))
(→ foodEater eat-food)
(→ foodEater eat-food)
(→ birdFeeder feed-birds)
(→ foodEater eat-food)
(→ foodEater eat-food)