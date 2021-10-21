#lang racket

(require (only-in "../../objects.rkt" → Root INTERFACE CLASS MIXIN new cast-up))
(require test-engine/racket-tests)

(define Openable
  (INTERFACE
   ()
   ([method open])))

(define Secure
  (INTERFACE
   ([superinterface Openable])
   ([method displayNeeded]
    [method getStatus]
    [method tryOpen])))

(define Door
  (CLASS extends Root
         ([interface Openable])
         ()
         ([method open () (display "Welcome to the room behind the door...\n")])))

(define LockedSecure
  (MIXIN requires Openable
         exports Secure
         ([field locked #t]
          [field key "golden key"])
         ([method displayNeeded () (display "This object requires a key...\n")]
          [method open () (if (? locked)
                              (display "This object requires a key!\n")
                              (↑ open))]
          [method getStatus () (if (? locked)
                                   (display "This object is locked\n")
                                   (display "This object is unlocked\n"))]
          [method tryOpen (tryKey) (if (? locked)
                                       (! locked (not (equal? tryKey (? key))))
                                       (display "This object is already unlocked\n"))])))

(define MagicSecure
  (MIXIN requires Openable
         exports Secure
         ([field locked #t]
          [field key "abracadabra!"])
         ([method displayNeeded () (display "This object requires magic...\n")]
          [method open () (if (? locked)
                              (display "This object requires magic!\n")
                              (↑ open))]
          [method getStatus () (if (? locked)
                                   (display "This object is magicked\n")
                                   (display "This object is not magicked\n"))]
          [method tryOpen (tryKey) (if (? locked)
                                       (! locked (not (equal? tryKey (? key))))
                                       (display "This object is already unmagicked\n"))])))

(define (program)
  (let* ([LockedDoor (LockedSecure Door)]
         [MagicLockedDoor (MagicSecure LockedDoor)])
    (let* ([myMagicLockedDoor (new MagicLockedDoor MagicLockedDoor)]
           [myLockedDoor (cast-up LockedDoor myMagicLockedDoor)])
      (begin
        (→ myMagicLockedDoor open)
        (→ myMagicLockedDoor getStatus)
        (→ myLockedDoor getStatus)
        (→ myMagicLockedDoor tryOpen "abracadabra!")
        (→ myMagicLockedDoor getStatus)
        (→ myLockedDoor getStatus)
        (→ myMagicLockedDoor open)
        (→ myLockedDoor tryOpen "golden key")
        (→ myMagicLockedDoor getStatus)
        (→ myLockedDoor getStatus)
        (→ myMagicLockedDoor open)))))

(program)