#lang racket

(require (only-in "../../objects.rkt" → Root INTERFACE CLASS MIXIN new cast-up))
(require test-engine/racket-tests)

;;--------------------------------------------------------------------------------------------------

(define Musicable
  (INTERFACE
   ()
   ([method makeMusic]
    [method setSong])))

(define Instrument
  (CLASS extends Root
         ([interface Musicable])
         ([field song "*musical white noise plays*\n"])
         ([method setSong(newSong) (! song newSong)]
          [method makeMusic () (display (? song))])))

;;--------------------------------------------------------------------------------------------------

(define Stringed
  (INTERFACE
   ()
   ([method restring])))

(define Wind
  (INTERFACE
   ()
   ([method clean])))

(define Polyphonic
  (INTERFACE
   ()
   ([method playChord])))

(define Monophonic
  (INTERFACE
   ()
   ([method playMelody])))

;;--------------------------------------------------------------------------------------------------

(define StringedMixin
  (MIXIN requires Musicable
         exports Stringed
         ([field stringStatus 5])
         ([method makeMusic () (begin
                                 (! stringStatus (- (? stringStatus) 1))
                                 (if (< (? stringStatus) 0)
                                     (display "can't make music with a broken string!\n")
                                     (if (equal? 0 (? stringStatus))
                                         (display "oh no! a string snapped...\n")
                                         (↑ makeMusic))))]
          [method restring () (! stringStatus 5)])))

(define WindMixin
  (MIXIN requires Musicable
         exports Wind
         ([field spitLevel 0])
         ([method makeMusic () (begin
                                 (! spitLevel (+ (? spitLevel) 1))
                                 (if (> (? spitLevel) 5)
                                     (display "too dirty to blow into!\n")
                                     (↑ makeMusic)))]
          [method clean () (! spitLevel 0)])))

(define PolyphonicMixin
  (MIXIN requires Musicable
         exports Polyphonic
         ()
         ([method playChord () (begin
                                 (→ self setSong "multiple notes grace your ears in synchrony!\n")
                                 (→ self makeMusic))])))
         

(define MonophonicMixin
  (MIXIN requires Musicable
         exports Monophonic
         ()
         ([method playMelody () (begin
                                  (→ self setSong "a melody, told in sequential notes, passes you like time.\n")
                                  (→ self makeMusic))])))

;;--------------------------------------------------------------------------------------------------

(define Guitar
  (PolyphonicMixin (StringedMixin Instrument)))

(define Ektara
  (MonophonicMixin (StringedMixin Instrument)))

(define Harmonica
  (PolyphonicMixin (WindMixin Instrument)))

(define Clarinet
  (MonophonicMixin (WindMixin Instrument)))

;;--------------------------------------------------------------------------------------------------

(define (program)
  (let* ([myGuitar (new Guitar Guitar)]
         [myEktara (new Ektara Ektara)]
         [myHarmonica (new Harmonica Harmonica)]
         [myClarinet (new Clarinet Clarinet)])
    (→ myGuitar makeMusic)
    (→ myGuitar playChord)
    (→ myGuitar makeMusic)
    (→ myClarinet playMelody)
    (→ myGuitar makeMusic)
    (→ myGuitar makeMusic)
    (→ myGuitar makeMusic)
    (→ myGuitar restring)
    (→ myGuitar makeMusic)))

(program)