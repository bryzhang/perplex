#lang racket
(require racket/vector)
(require racket/set)
(require racket/local)

(provide Root → INTERFACE CLASS MIXIN new cast-up)

;;--------------------------------------------------------------------------------------------------

;; defmac is like define-syntax-rule, except that it additionally supports two optional parameters. 
;; #:keywords <id> ... specifies keywords in the resulting macro
;; #:captures <id> ... specifies names that are inserted unhygienically
;; OOPLAI (http://www.dcc.uchile.cl/etanter/ooplai) uses defmac all along.

;; directly inspired by http://tmp.barzilay.org/defmac.ss by Eli Barzilay.
;; (this version is just a rewrite of Eli's, with a slightly different syntax
;; and using syntax-parse to handle the optional parameters)

(require (for-syntax syntax/parse))

(define-syntax (defmac stx)
  (syntax-parse stx
    [(defmac (name:identifier . xs) 
       (~optional (~seq #:keywords key:identifier ...) #:defaults ([(key 1) '()]))
       (~optional (~seq #:captures cap:identifier ...) #:defaults ([(cap 1) '()]))
       body:expr)
     #'(define-syntax (name stx)
         (syntax-case stx (key ...)
           [(name . xs)
            (with-syntax ([cap (datum->syntax stx 'cap stx)] ...)
              (syntax body))]))]))

;;-------------------------------------------------------------------------------------------------

;; Root: The ultimate ancestor of all Objects
(define Root
  (λ (msg . args)
    (match msg
      ['-all-methods (set)]
      ['-knows-method #f]
      ['-all-types (set)]
      ['-can-be-type #f]
      ['-hiding-methods '()]
      ['-superclass '()]
      ['-local-interfaces '()]
      ['-all-fields '()])))

;; Object: Represents a single Object with its base Class and its stateful Values.
(struct object (class values))

;; Typed-Object: Denotes the current runtime Type for a given Object.
(struct typed-object (type obj))

;; Cast-Up: Safely casts a Typed-Object for use as a more general type, Target.
;; Note that Target can be a superclass or a superinterface.
(define (cast-up target tobj)
  (let ([type (typed-object-type tobj)]
        [obj (typed-object-obj tobj)])
    (if (type '-can-be-type target)
        (typed-object target obj)
        (error "cannot cast" type target))))

;; →: Apply a Method to a Typed-Object.
;; Validation occurs from the runtime Type.
;; Definition comes from the lowest Class whose method definition is connected to the runtime Type.
(defmac (→ to m arg ...)
  (letrec ([helper (λ (runtime-type current-class return-class target-method)
                     (if (or (eq? current-class runtime-type)
                             (set-member? (current-class '-local-interfaces) runtime-type))
                         return-class
                         (let ([return-class (if (set-member? (current-class '-hiding-methods) target-method)
                                                 (current-class '-superclass)
                                                 return-class)])
                           (helper runtime-type (current-class '-superclass) return-class target-method))))])
    (letrec ([typed-obj to]
             [type (typed-object-type typed-obj)]
             [obj (typed-object-obj typed-obj)]
             [class (object-class obj)])
      (if (type '-knows-method 'm)
          ;; Find lowest connected method definition to the runtime Type
          (((helper type class class 'm) '-lookup 'm) typed-obj arg ...)
          (error "message not understood:" 'm)))))

; New: Create an instance of a Class with the given runtime Type.
(define (new type class . init-vals)
  (cast-up type (apply class (cons '-create init-vals))))

;;--------------------------------------------------------------------------------------------------

(defmac (INTERFACE ([superinterface super] ...)
                   ([method mname] ...))
  #:keywords superinterface method
  (letrec ([methods (foldl (λ (a b) (set-union b (a '-all-methods))) (set 'mname ...) (list super ...))]
           [interface
               (λ (msg . args)
                 (match msg
                   ['-create (error "cannot instantiate interface")]
                   ['-all-methods methods]
                   ['-all-types types]
                   ['-knows-method (set-member? methods (first args))]
                   ['-can-be-type (set-member? types (first args))]))]
           [types (foldl (λ (a b) (set-union b (a '-all-types))) (set interface) (list super ...))])
    interface))

;;--------------------------------------------------------------------------------------------------

;; Field shadowing, not moving this into CLASS because it's bloated enough as-is
(define (find-last fd fields)
  (letrec ([find-last-helper
            (λ (fd fields curr last)
              (cond
                [(empty? fields) last]
                [(eq? (car (first fields)) fd) (find-last-helper fd (cdr fields) (+ curr 1) curr)]
                [else (find-last-helper fd (cdr fields) (+ curr 1) last)]))])
    (let ([last (find-last-helper fd fields 0 -1)])
      (if (equal? last -1)
          (error "field not found:" fd)
          last))))

;; Helper to abstract class creation logic away from MIXIN and CLASS macros.
(define (class-helper scls-expr interfaces fields methods hiding-methods)
  (let* ([scls scls-expr])
    ;; Check that all required methods are implemented
    (let* ([required (foldl (λ (a b) (set-union b (a '-all-methods))) (set) interfaces)]
           [implemented (set-union (foldl (λ (a b) (set-add b (car a))) (set) methods) (scls '-all-methods))])
      (if (not (subset? required implemented))
          (error "required methods not implemented:" (set-subtract required (set-intersect required implemented)))
          (letrec ([class (λ (msg . args)
                            (match msg
                              ['-create
                               (let* ([values (list->vector (map cdr fields))]
                                      [o (typed-object class (object class values))])
                                 (when (not (empty? args))
                                   (let ([found (assoc 'initialize methods)])
                                     (if found
                                         (apply (cdr found) (cons o args))
                                         (error "initialize not implemented in:" class))))
                                 o)]
                              ['-all-methods implemented]
                              ['-knows-method (set-member? implemented (first args))]
                              ['-all-types types]
                              ['-all-fields fields]
                              ['-hiding-methods hiding-methods]
                              ['-superclass scls]
                              ['-local-interfaces interfaces]
                              ['-can-be-type (set-member? types (first args))]
                              ['-lookup (let ([found (assoc (first args) methods)])
                                          (if found (cdr found) (scls '-lookup (first args))))]))]
                   [types (set-union (foldl (λ (a b) (set-union b (a '-all-types))) (set class) interfaces) (scls '-all-types))])
            class)))))

;;--------------------------------------------------------------------------------------------------

(defmac (MIXIN requires in-iface
               exports out-iface
               ([field fname fval] ...)
               ([method mname (mparam ...) mbody ...] ...))
  #:keywords requires exports field method
  #:captures self ? ! ↑
  ;; Check that the exported interface is implemented
  (let* ([required (out-iface '-all-methods)]
         [implemented (set-union (in-iface '-all-methods) (set 'mname ...))])
    (if (not (subset? required implemented))
        (error "mixin: required methods not implemented:" (set-subtract required (set-intersect required implemented)))
        ;; Generate a function that can be applied to a parameterizing superclass to return a new class
        (λ (scls-expr)
          (let ([scls scls-expr])
            ;; Check that the superclass explicitly implements the required interface
            (if (not (scls '-can-be-type in-iface))
                (error "mixin: superclass does not implement required interface")
                (let* ([interfaces (list out-iface)]
                       [fields (append (scls '-all-fields) (list (cons 'fname fval) ...))]
                       [statically-inherited-methods (in-iface '-all-methods)]
                       ;; ? ! and ↑ are the reason why I can't use a more general class-helper... Macros are confusing.
                       [methods
                        (local [(defmac (? f) #:captures self
                                  (vector-ref (object-values (typed-object-obj self)) (find-last 'f fields)))
                                (defmac (! f v) #:captures self
                                  (vector-set! (object-values (typed-object-obj self)) (find-last 'f fields) v))
                                ;; super() is only valid for methods that are statically known, via the
                                ;; required interface, to be implemented in the super
                                (defmac (↑ md . args) #:captures self
                                  (let ([inherited-methods (in-iface '-all-methods)])
                                    (if (set-member? inherited-methods 'md)
                                        ((scls '-lookup 'md) self . args)
                                        (error "cannot invoke super() on" 'md))))]
                          (list (cons 'mname (λ (self mparam ...) mbody ...)) ...))]
                       ;; Any non-required implemented method is assumed to be unrelated to any overlapping
                       ;; method definitions in the as-yet-provided superclass
                       [hiding (set-subtract (set 'mname ...) (in-iface '-all-methods))])
                  (class-helper scls interfaces fields methods hiding))))))))

(defmac (CLASS extends scls-expr
               ([interface iface] ...)
               ([field fname fval] ...)
               ([method mname (mparam ...) mbody ...] ...))
  #:keywords extends interface field method
  #:captures self ? ! ↑
  (let* ([scls scls-expr]
         [interfaces (list iface ...)]
         [fields (append (scls '-all-fields) (list (cons 'fname fval) ...))]
         [methods
          (local [(defmac (? f) #:captures self
                    (vector-ref (object-values (typed-object-obj self)) (find-last 'f fields)))
                  (defmac (! f v) #:captures self
                    (vector-set! (object-values (typed-object-obj self)) (find-last 'f fields) v))
                  ;; For regular classes, super() is valid for all known methods
                  (defmac (↑ md . args) #:captures self
                    (let ([all-methods (set-union (set 'mname ...) (scls '-all-methods))])
                      (if (set-member? all-methods 'md)
                          ((scls '-lookup 'md) self . args)
                          (error "cannot invoke super() on" 'md))))]
           (list (cons 'mname (λ (self mparam ...) mbody ...)) ...))]
         ;; Regular classes always implicitly inherit/override all methods
         [hiding '()])
    (class-helper scls interfaces fields methods hiding)))