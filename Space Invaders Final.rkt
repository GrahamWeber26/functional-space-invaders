;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-beginner-abbr-reader.ss" "lang")((modname |Space Invaders Final|) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #f)))
; SPACE INVADERS: ENCOUNTERS WITH EARTH
; Author: Graham Weber (with functions from Wynn Miller)
; CS 208 Program Design
; September 26, 2021

; INSTRUCTIONS
; The game is ready to play as is. Just click "run".
; However, you may wish to customize the game setup
     ; To play a different level, change the run main parameter to "startmedium" or "starthard"
          ; You can also create your own ufo list and startstate and pass that into main
     ; To customize the tank and background, edit the selectedTank or selectedBg definitions
     ; To make it harder, increase the UFOSPEED

; Libraries
(require 2htdp/universe)
(require 2htdp/image)

; Images - There are multiple images for each object which are called using the "selected..." functions
    ; Abrams tank
    (define ABRAMSPEED 7)
    (define abrams
        (above
         (rectangle 5 15 "solid" "olive")
         (rectangle 20 8 "solid" "olive")
            (overlay/align/offset
                "middle" "bottom"
                (rectangle 50 16 "solid" "olive")
                0 10
                (beside (circle 10 "solid" "black") (circle 10 "solid" "black") (circle 10 "solid" "black")))))


    ; boat tank
    (define WARSHIPSPEED 7)
    (define warship
        (above
            (rectangle 5 15 "solid" "grey")
            (rectangle 20 8 "solid" "grey")
            (rotate 180 (wedge 30 180 "solid" "grey"))))

    ; Saucer ufo
    (define saucer
        (overlay/offset
        (ellipse 60 10 "solid" "grey")
        0 -6
        (circle 12.5 "solid" "blue")))


    ; Boomer missile
    (define boomer
        (overlay/offset
            (above (triangle 7 "solid" "white")
                    (rectangle 5 10 "solid" "white"))
            0 7
            (triangle 9 "solid" "white")))

    ; City Road BG
    (define bgCityRoad
        (bitmap "city-road-small.jpg"))

    ; City Water BG
    (define bgCityWater
        (bitmap "city-water-small.jpg"))

    ; Suburbs BG
    (define bgSuburbs
        (bitmap "suburbs-cool-small.jpg"))

    ;* blank Background
    (define WIDTH 1000)
    (define HEIGHT 700)
    (define emptyBg
        (empty-scene WIDTH HEIGHT))

; Constants, selected images, and structs
    ; UFO vertical speed
    (define UFOSPEED 2)

    ; Projectile speed
    (define PSPEED 15)

    ; Tank image                           **CUSTOMIZE**
      ; options: "abrams", "warship"
    (define selectedTank abrams)

    ; ufo Image
    (define selectedUfo saucer)

    ; projectile Image
    (define selectedProjectile boomer)

    ; Background Image                           **CUSTOMIZE**
       ; options: "bgCityRoad", "bgCityWater", "bgSuburbs"
    (define selectedBackground bgCityWater)

    ; FLoor location
    (define FLOOR (* (image-height selectedBackground) 0.96))

    ; Final Image
    (define renderFinal
    (overlay/align "middle" "middle"
                    (text "GAME OVER" 24 "red")
                    selectedBackground))


    ; A ufo is a Posn.
    (define-struct ufo [x y])
        ; interpretation (make-posn x y) is the ufo's location 
        ; (using the top-down, left-to-right convention)
    
    ; A Tank is a structure:
    (define-struct tank [loc vel])
        ; (make-tank Number Number). 
        ; interpretation (make-tank x dx) specifies the position:
        ; (x, HEIGHT) and the tank's speed: dx pixels/tick 
    
    ; A projectile is a structure:
    (define-struct projectile [x y vel])
        ; (make-projectile number number number)
        ; interpretation (make-projectile x y) specifies the projectile's position (x y) and speed (vel)

    ; A status is a structure
    (define-struct status [ufo tank ammo score])
        ;;; (make-status (make-ufo number number) (make-tank number number) (make-ammo boolean boolean boolean ) number)
        ;;; (make-status '() (make-tank number number) (make-ammo boolean boolean boolean ) number)
        ;;; interpretation: (make-status ufo tank ammo score) specifies the tanks, ufos, 
            ;;; and projectiles currently in the world, and the player's score.

    ; An ammo is a structure
    (define-struct ammo [slot1 slot2 slot3])
        ; (make-ammo boolean boolean boolean)
        ; interpretation: (make-ammo boolean boolean boolean) specifies the number of projectiles available to fire


; endGame Function - Append string with newline from https://stackoverflow.com/questions/15423969/newline-in-scheme-racket
        ; gs is a status: 
            ; (make-status ufo tank projectile score)
        ; signature: status -> Image
        ; purpose: render end image and end game
        ; header: (define (endGame gs) ...)
        ; I/O examples:
            ; (make-status (make-ufo 50 FLOOR) (make-tank 100 5) (make-ammo #true #false #false) 0) -> End image with text "GAME OVER" in middle
            ; (make-status '() (make-tank 100 5) (make-ammo #true #false #false) 0) -> End image with text "YOU WIN!" in middle
        ; (define (endGame gs)
        ;     (cond
        ;         [(empty? (status-ufo gs)) ...]
        ;         [(ufoLanded? (status-ufo gs)) ...]
        ;         [else ...])
    (define (endGame gs)
        (cond
            [(empty? (status-ufo gs)) (overlay/align "middle" "middle" (text "YOU WIN!" 48 "green") (rectangle 320 100 "solid" "black") selectedBackground)]
            [(ufoLanded? (status-ufo gs)) (overlay/align "middle" "middle" (text "GAME OVER" 48 "red") (rectangle 320 100 "solid" "black") selectedBackground)]
            [else (overlay/align "middle" "middle" (text (string-append "ERROR" "\n" "Something went wrong...") 24 "red") (rectangle 320 100 "solid" "black") selectedBackground)]))


; MOVE FUNCTION
    ; gs is a status:
            ; (make-status ufo tank projectile score)
        ; signature: status -> status
        ; purpose: move objects to next position every tick, depending if missile is fired
        ; (define (move gs) ...)
        ; I/O examples
        ;   (make-status (make-ufo 50 75) (make-tank 100 5) #false) -> (make-status (make-ufo 50 78) (make-tank 100 5) #false)
        ;   (make-status (make-ufo 75 100) (make-tank 75 5) (make-projectiles 75 200 3)) -> (make-status (make-ufo 75 103) (make-tank 75 5) (make-projectiles 75 195 3))
        ;(define (move gs)
        ;  (cond
        ;    [... (make-ufo ...)]
        ;    [... (make-ufo ...) (make-projectile ...)]))
    (check-expect (move (make-status (cons (make-ufo 75 100) (cons (make-ufo 250 250) '())) (make-tank 75 5) (make-ammo #false #false #false) 0))
        (make-status (cons (make-ufo 75 102) (cons (make-ufo 250 252) '())) (make-tank 75 5) (make-ammo #false #false #false) 0))
    (define (move gs)
        (make-status (cond [(empty? (status-ufo gs)) #false]
                            [else (moveUfos gs)])
                    (status-tank gs)
                    (moveProjectiles gs)
                    (status-score gs)))


; moveUfos FUNCTION - This function was written with help from Wynn Miller
    ; gs is a status:
        ; (make-status ufo tank projectile score)
    ; gs -> gs
    ; purpose: move ufos down based on game state
    ; header: (define (moveUfos gs) ...)
    ; I/O Examples
        ; (make-status (cons (make-ufo 75 100) (cons (make-ufo 250 250))) (make-tank 75 5) (make-ammo'())) -> 
        ;     (make-status (cons (make-ufo 75 102) (cons (make-ufo 250 252))) (make-tank 75 5) (make-ammo'()))
    ; Template
    ; (define (moveUfos gs)
    ;     (cond
    ;         [(empty? (status-ufo gs)) ...]
    ;         [else (if (or "ufo goes below floor" "projectile hits ufo") ... "check next"]))
    (check-expect (moveUfos (make-status (cons (make-ufo 75 100) (cons (make-ufo 250 250) '())) (make-tank 75 5) (make-ammo #false #false #false) 0))
        (make-status (cons (make-ufo 75 102) (cons (make-ufo 250 252) '())) (make-tank 75 5) (make-ammo #false #false #false) 0))

    (define (moveUfos gs)
    (cond
        [(empty? (status-ufo gs)) '()]
        [else (if (or (>= (ufo-y (first (status-ufo gs))) FLOOR) 
                    (if (posn? (ammo-slot1 (status-ammo gs))) (ufoCollideSingle (ammo-slot1 (status-ammo gs)) (first (status-ufo gs))) #false) 
                    (if (posn? (ammo-slot2 (status-ammo gs))) (ufoCollideSingle (ammo-slot2 (status-ammo gs)) (first (status-ufo gs))) #false)
                    (if (posn? (ammo-slot3 (status-ammo gs))) (ufoCollideSingle (ammo-slot3 (status-ammo gs)) (first (status-ufo gs))) #false))
                (remove (first (status-ufo gs)) (status-ufo gs))
                (cons (make-ufo (ufo-x (first (status-ufo gs))) (+ (ufo-y (first (status-ufo gs))) UFOSPEED)) 
                    (moveUfos (make-status (rest (status-ufo gs)) (status-tank gs) (status-ammo gs) (status-score gs)))))]))

; moveProjectiles Function - This function was written by Wynn Miller
    ; gs is a status:
        ; (make-status ufo tank projectile score)
    ; gs -> gs
    ; purpose: move projectiles up based on gamestate
    ; header: (define (moveProjectiles strikers) ...)
    ; I/O Examples
        ; (make-status ufo  tank (make-ammo (make-projectile 75 100 7) (make-projectile 80 120 7) #false) 0) ->
        ; (make-status ufo  tank (make-ammo (make-projectile 75 93 7) (make-projectile 80 113 7) #false) 0)
    ; Template
    ; (define (moveProjectiles strikers)
    ;     (make-ammo 
    ;         (if "slot1 is not false" (if "slot1 has not collided" "move slot 1" #false) #false)
    ;         (if "slot2 is not false" (if "slot2 has not collided" "move slot 2" #false) #false)
    ;         (if "slot3 is not false" (if "slot3 has not collided" "move slot 3" #false) #false)))
        ; (if (posn? (ammo-slot1 (status-ammo strikers)))
        ;     (if (ufoCollide (ammo-slot1 (status-ammo strikers)) (status-ufo strikers))
        ;         #false
        ;         (moveOneP (ammo-slot1 (status-ammo strikers))))    
        ;     #false)
        ; (if (posn? (ammo-slot2 (status-ammo strikers)))
        ;     (if (ufoCollide (ammo-slot2 (status-ammo strikers)) (status-ufo strikers))
        ;         #false
        ;         (moveOneP (ammo-slot2 (status-ammo strikers))))    
        ;     #false)
        ; (if (posn? (ammo-slot3 (status-ammo strikers)))
        ;     (if (ufoCollide (ammo-slot3 (status-ammo strikers)) (status-ufo strikers))
        ;         #false
        ;         (moveOneP (ammo-slot3 (status-ammo strikers))))    
        ;     #false)))
    (check-expect (make-status (cons (make-ufo 75 100) (cons (make-ufo 250 250) '()))  (make-tank 75 5) (make-ammo #false #false #false) 0)
        (make-status (cons (make-ufo 75 100) (cons (make-ufo 250 250) '()))  (make-tank 75 5) (make-ammo #false #false #false) 0))
    (check-expect (make-status (cons (make-ufo 75 100) (cons (make-ufo 250 250) '()))  (make-tank 75 5) (make-ammo (make-projectile 75 100 7) #false #false) 0)
        (make-status (cons (make-ufo 75 100) (cons (make-ufo 250 250) '()))  (make-tank 75 5) (make-ammo (make-projectile 75 93 7) #false #false) 0))

    (define (moveProjectiles strikers)
        (make-ammo
        (if (posn? (ammo-slot1 (status-ammo strikers)))
            (if (ufoCollide (ammo-slot1 (status-ammo strikers)) (status-ufo strikers))
                #false
                (moveOneP (ammo-slot1 (status-ammo strikers))))    
            #false)
        (if (posn? (ammo-slot2 (status-ammo strikers)))
            (if (ufoCollide (ammo-slot2 (status-ammo strikers)) (status-ufo strikers))
                #false
                (moveOneP (ammo-slot2 (status-ammo strikers))))    
            #false)
        (if (posn? (ammo-slot3 (status-ammo strikers)))
            (if (ufoCollide (ammo-slot3 (status-ammo strikers)) (status-ufo strikers))
                #false
                (moveOneP (ammo-slot3 (status-ammo strikers))))    
            #false)))

    ; ufoCollide FUNCTION - This helper function was written by Wynn Miller
        ; p is a projectile
            ; (make-projectile x y vel)
            ; x and y are the p's position, vel is p's speed in pixels/tick.
        ; lou is a ufo
            ; (make-ufo (cons (make-ufo x y) '()))
            ; x and y are the ufo's position
        ; signature: p, lou -> boolean
        ; purpose: check if projectile hit any of the ufos
        ; header: (define (ufoCollide p lou) ...)
    (define (ufoCollide p lou)
        (cond
            [(empty? lou) #false]
            [else (if (and (<= (abs (- (posn-y p) (ufo-y (first lou)))) (/ (image-height selectedUfo) 1))
                        (<= (abs (- (posn-x p) (ufo-x (first lou)))) (/ (image-height selectedUfo) 1)))
                        #true
                        (ufoCollide p (rest lou)))]))

    ; ufoCollideSingle helper function - This helper function was written by Wynn Miller
        ; projectile is a structure
            ; (make-projectile x y vel)
            ; x and y are the p's position, vel is p's speed in pixels/tick.
        ; signature: projectile -> projectile
        ; purpose: check if projectile hit ufo
        ; header: (define (moveProjectile p) ...)
    (define (ufoCollideSingle p ufo)
        (if (and (<= (abs (- (posn-y p) (ufo-y ufo))) (/ (image-height selectedUfo) 1))
                (<= (abs (- (posn-x p) (ufo-x ufo))) (/ (image-height selectedUfo) 1)))
            #true
            #false))

    ; moveOneP helper function - This helper function was written by Wynn Miller
        ; projectile is a structure
            ; (make-projectile x y vel)
            ; x and y are the p's position, vel is p's speed in pixels/tick.
        ; signature: projectile -> projectile
        ; purpose: move projectile up unless it is above the screen
        ; header: (define (moveProjectile p) ...)
    (define (moveOneP p)
        (if
            (posn? p)
            (if (<= (posn-y p) 0)
                #false
                (make-posn (posn-x p) (- (posn-y p) PSPEED)))
            p))


; RENDER FUNCTION
    ; gs is a status:
        ; (make-status ufo tank ammo score)
    ; signature: status -> Image
    ; purpose: render image of current game state every tick
    ; header: (define (render gs) ...)
    ; I/O examples
        ; (world state with 2 ufos and 1 projectile) -> (image with tank, 2 ufos and 1 projectile)
        ; (world state with 1 ufo and 0 projectile) -> (image with tank and 1 ufo)
    ; (define (render gs)
        ; (cond [(= (status-projectile gs) #false) ... "render ufos and tank" ...]
            ; [else ... "render projectiles, ufos and tank" ...]))
    ; Template
    ; (define (render gs)
    ;     (renderAmmo ...)))
    (define (render gs)
        (renderAmmo (status-ammo gs) (renderUfos (status-ufo gs) (renderTank (status-tank gs)))))

; RENDERTANK FUNCTION
    ; tank is a structure
        ;   (make-tank loc vel)
        ; loc is the x-position of the tank; vel is it's speed in pixels/tick
    ; signature: tank -> Image
    ; purpose: render image of tank
    ; header: (define (renderTank t) ...)
    ; I/O examples
        ; (make-tank 100 5) -> image of tank at x-position 100, y-position FLOOR on the selected background
    ; Function Template
    ; (define (renderTank t)
        ; (place-image t (tank-x t) Floor bg)))
    (define (renderTank t)
        (place-image selectedTank (tank-loc t) FLOOR selectedBackground))

; RENDERUFOs FUNCTION - This function was adapted from exercises 148 and 158 of the "How to Design Programs" textbook.
    ; lou is a list of ufos
        ;   (list '())
        ;   (list (make-ufo x y) (make-ufo x y) (make-ufo x y))
    ; im is an image
        ;   (place-image selectedProjectile (place-image selectedTank (place-image selectedUfo 
        ;        100 100 selectedBackground) 200 FLOOR selectedBackground) 200 50 selectedBackground)
        ; x and y are the position of the ufo
    ; signature: lou, image -> Image
    ; purpose: render image of ufo(s) on top of tank and bg
    ; header: (define (renderUfos lou im) ...)
    ; I/O examples
            ; (cons (make-ufo 150 250) '()) image of tank on background -> image of ufo at x-position 150,
                ; y-position 250 on image of tank and background
            ; (cons (make-ufo 150 250) (cons (make-ufo 300 140) '())) image of tank on background -> 
                ; image of 2 ufos on image of tank and background
            ; (cons
    ; Template
    ; (define (renderUfos lou im)
    ;     (cond
    ;         [(empty? lou) im]
    ;         [else ...]))
    (define (renderUfos lou im)
    (cond
        [(empty? lou) im]
        [else (place-image selectedUfo (ufo-x (first lou)) (ufo-y (first lou))
                        (renderUfos (rest lou) im))]))


; RENDERPROJECTILES FUNCTION
    ; lop is a list of projectiles
        ;   (list '())
        ;   (list (make-projectile x y vel) (make-projectile x y vel))
        ; x and y are the p's position, vel is p's speed in pixels/tick.
        ; signature: Projectile, Image -> Image
        ; purpose: render image of projectile(s) on top of everything else
        ; header: (define (renderProjectiles p im) ...)
        ; I/O examples
            ; (cons '()) image of ufos and tank on background -> same image
            ; (cons (make-projectiles 100 10) (cons (make-projectiles 100 10) '())) image of ufos and 
                ; tank on background -> image of 2 projectiles, ufos, and a tank on background
        ; Function Template
        ; (define (renderProjectiles p im)
        ;  (cond
        ;    [(empty? lou) '()]
        ;    [else (place-image ...) (renderUfo (rest lou))]))
    ;(define (renderProjectiles lop im)
    ;    (cond
    ;        [(empty? lop) im]
    ;        [else (renderProjectiles (rest lop) (renderOneP (first lop) im))]))

    ; RENDERONEP helper function
        ; projectile is a structure
        ;   (make-projectile x y vel)
        ; x and y are the p's position, vel is p's speed in pixels/tick.
        ; signature: Projectile, Image -> Image
        ; purpose: render image of projectile(s) on top of everything else
        ; header: (define (renderProjectiles p im) ...)
    (define (renderOneP p im)
        (place-image selectedProjectile (projectile-x p) (projectile-y p) im))

; renderAmmo Function - This function was written by Wynn Miller
    ; ammo is an ammo
        ; (make-ammo boolean boolean boolean)
    ; signature: ammo, Image -> Image
    ; purpose: render image of projectile(s) on top of everything else
    ; header: (define (renderAmmo ammo im) ...)
    ; I/O examples
        ; (make-ammo #false #false #false) image of ufos and tank on background -> same image
        ; (make-ammo (make-projectiles 100 10) (make-projectiles 100 10) #false)) image of ufos and 
            ; tank on background -> image of 2 projectiles, ufos, and a tank on background
    ; Function Template
        ; (define (renderProjectiles p im)
        ;     (place-image selectedProjectile "ammo 1 x ammo 1 y"
        ;         (place-image selectedProjectile "ammo 2 x ammo 2 y"
        ;             (place-image selectedProjectile "ammo 3 x ammo 3 y")))
    (check-expect (renderAmmo (make-ammo #false #false #false) selectedBackground)
        selectedBackground)
    (check-expect (renderAmmo (make-ammo (make-projectiles 100 10) (make-projectiles 50 75) #false) selectedBackground)
        (place-image selectedProjectile 100 10
            (place-image selectedProjectile 50 75
                selectedBackground)))

    (define (renderAmmo ammo im)
        (place-image
            selectedProjectile 
            (if (posn? (ammo-slot1 ammo)) (posn-x (ammo-slot1 ammo)) -1000)
            (if (posn? (ammo-slot1 ammo)) (posn-y (ammo-slot1 ammo)) -1000)
            (place-image
                selectedProjectile
                (if (posn? (ammo-slot2 ammo)) (posn-x (ammo-slot2 ammo)) -1000)
                (if (posn? (ammo-slot2 ammo)) (posn-y (ammo-slot2 ammo)) -1000)
                (place-image
                    selectedProjectile
                    (if (posn? (ammo-slot3 ammo)) (posn-x (ammo-slot3 ammo)) -1000)
                    (if (posn? (ammo-slot3 ammo)) (posn-y (ammo-slot3 ammo)) -1000)
                    im))))

; ACTIONS FUNCTION
    ; gs is a status:
            ; (make-status ufo tank projectile score)
        ; signature: gs -> gs
        ; purpose: interpret key presses to change gamestate
        ; header: (define (actions status key) ...)
        ; I/O examples
            ; (make-status ufo (make-tank 100 5) ammo score) "right" -> (make-status ufo (make-tank 105 5) ammo score)
            ; (make-status ufo tank (make-ammo #false #false #false) score) " " ->
            ;     (make-status ufo tank (make-ammo (make-ammo (make-projectile 100 FLOOR)) #false #false) score)
        ; (define (actions gs key)
        ;     (cond
        ;         [(string=? key "right") "move tank right"]
        ;         [(string=? key "left") "move tank left"]
        ;         [(string=? key " ") "fire missile"]
        ;         [else "render same gs"]))
    (check-expect (actions (make-status (make-tank 10 5) (cons (make-ufo 50 50) '()) (make-ammo #false #false #false) 0) "j")
        (make-status (make-tank 10 5) (cons (make-ufo 50 50) '()) (make-ammo #false #false #false) 0))
    (check-expect (actions (make-status (make-tank 10 5) (cons (make-ufo 50 50) '()) (make-ammo #false #false #false) 0) " ")
        (make-status (make-tank 10 5) (cons (make-ufo 50 50) '()) (make-ammo (make-projectile 10 FLOOR PSPEED) #false #false) 0))
    (check-expect (actions (make-status (make-tank 10 5) (cons (make-ufo 50 50) '()) (make-ammo (make-projectile 10 FLOOR PSPEED) #false #false) 0) "right")
        (make-status (make-tank 15 5) (cons (make-ufo 50 50) '()) (make-ammo (make-projectile 10 FLOOR PSPEED) #false #false) 0))

    (define (actions gs key)
        (cond
            [(string=? key "right") (if (> (tank-loc (status-tank gs)) (image-width selectedBackground)) gs (make-status (status-ufo gs) (moveTankRight (status-tank gs)) (status-ammo gs) (status-score gs)))]
            [(string=? key "left") (if (< (tank-loc (status-tank gs)) 0) gs (make-status (status-ufo gs) (moveTankLeft (status-tank gs)) (status-ammo gs)  (status-score gs)))]
            [(string=? key " ") (make-status (status-ufo gs) (status-tank gs) (fire gs)  (status-score gs))]
            [else gs]))

    ; moveTankRight FUNCTION
        ; t is a tank
        ;   (make-tank loc vel)
        ; signature: tank -> tank
        ; purpose: move tank right by velocity
        ; header: (define (moveTankRight t) ...)
        ; I/O Examples
    (define (moveTankRight t)
        (make-tank (+ (tank-loc t) (tank-vel t)) (tank-vel t)))

    ; moveTankLeft FUNCTION
        ; t is a tank
        ;   (make-tank loc vel)
        ; signature: tank -> tank
        ; purpose: move tank left by velocity
        ; header: (define (moveTankLeft t) ...)
        ; I/O Examples
    (define (moveTankLeft t)
        (make-tank (- (tank-loc t) (tank-vel t)) (tank-vel t)))

; FIRE FUNCTION
    ; strikers is a status:
            ; (make-status ufo tank ammo score)
    ; signature: strikers -> strikers
    ; purpose: fire a projectile based on keypress
    ; header: (define (fire strikers) ...)
    ; I/O examples
        ; (fire (make-status tank ufo (make-ammo #false #false #false) 0)) -> (make-status tank ufo (make-ammo (make-projectile 50 FLOOR) #false #false) 0)
        ; (fire (make-status tank ufo (make-ammo (make-projectile 50 50) #false #false) 0)) -> 
        ;     (make-status tank ufo (make-ammo (make-projectile 50 50) (make-projectile 50 FLOOR) #false) 0)
    ; Template
    ; (define (fire strikers)
        ; (cond
        ;     [("if slot1 false") ...]
        ;     [("slot2 is false") ...]
        ;     [("slot3 is false") ...]
        ;     [else (status-ammo strikers)]))
    (check-expect (fire (make-status (make-tank 10 5) (cons (make-ufo 50 50) '()) (make-ammo #false #false #false) 0))
        (make-ammo (make-projectile 10 FLOOR PSPEED) #false #false))
    (check-expect (fire (make-status (make-tank 10 5) (cons (make-ufo 50 50) '()) (make-ammo (make-projectile 100 100 PSPEED) #false #false) 0))
        (make-ammo (make-projectile 100 100 PSPEED) (make-projectile 10 FLOOR PSPEED) #false))

    (define (fire strikers)
        (cond
            [(boolean? (ammo-slot1 (status-ammo strikers)))
                (make-ammo
                    (make-posn (tank-loc (status-tank strikers)) (+ FLOOR 5))
                    (ammo-slot2 (status-ammo strikers))
                    (ammo-slot3 (status-ammo strikers)))]
            [(boolean? (ammo-slot2 (status-ammo strikers)))
                (make-ammo
                    (ammo-slot1 (status-ammo strikers))
                    (make-posn (tank-loc (status-tank strikers)) (+ FLOOR 5))
                    (ammo-slot3 (status-ammo strikers)))]
            [(boolean? (ammo-slot3 (status-ammo strikers)))
                (make-ammo
                    (ammo-slot1 (status-ammo strikers))
                    (ammo-slot2 (status-ammo strikers))
                    (make-posn (tank-loc (status-tank strikers)) (+ FLOOR 5)))]
            [else (status-ammo strikers)]))


; gameOver? Function
    ; gs is a status:
            ; (make-status ufo tank projectile score)
    ; signature: gs -> gs
    ; purpose: Checks if game is over
    ; header: (define (gameOver? gs) ...)
    ; I/O examples
    ; (define (gameOver? gs)
    ;     (cond
    ;         ["UFO hits ground" "l"]
    ;         ["Missile hits UFO" "w"]
    ;         [else #false]))
    ; (check-expect (gameOver? (make-status (make-ufo)) #true)

    (define (gameOver? gs)
        (cond
            [(empty? (status-ufo gs)) #true]
            [else (ufoLanded? (status-ufo gs))]))

    ; ufoLanded? Function
    ; lou is a list of ufos
    ;   (list '())
    ;   (list (make-ufo x y) (make-ufo x y) (make-ufo x y))
    ; signature: lou -> lou
    ; purpose: Checks if any ufo has landed
    ; header: (define (ufoLanded? lou) ...)
    ; I/O examples

    ; Template
        ; (define (ufoLanded? lou)
        ;     (cond
        ;         [(empty? lou) #false]
        ;         [(>= (ufo-y (first lou)) FLOOR) #true]
        ;         [else (ufoLanded? (rest lou))]))
    (check-expect (ufoLanded? '()) #false)
    (check-expect (ufoLanded? (cons (make-ufo 100 100) '())) #false)
    (check-expect (ufoLanded? (cons (make-ufo 100 100) (cons (make-ufo 200 FLOOR) '()))) #true)

    (define (ufoLanded? lou)
        (cond
            [(empty? lou) #false]
            [(>= (ufo-y (first lou)) FLOOR) #true]
            [else (ufoLanded? (rest lou))]))


; MAIN FUNCTION
    ; gs is a status:
        ; (make-status ufo tank projectile score)
    ; gs -> gs
    ; This is the main function
    ; Move time, render images, convert keys into actions
    ;(define main gs)
    ;  (big-bang gs
    ;    [on-tick ...]
    ;    [to-draw ...]
    ;    [on-key ...]
    ;    [stop-when ...]))
    (define (main gs)
        (big-bang gs
            [on-tick move]
            [to-draw render]
            [on-key actions]
            [stop-when gameOver? endGame]))   

; Define initial states
(define easylou
    (cons (make-ufo 200 -10) '()))

(define mediumlou
    (cons (make-ufo 10 -10)
        (cons (make-ufo 50 -30)
            (cons (make-ufo 90 -50)
                (cons (make-ufo 130 -70) 
                    (cons (make-ufo 170 -90) 
                        (cons (make-ufo 210 -110) 
                            (cons (make-ufo 250 -130) '()))))))))

(define hardlou
    (cons (make-ufo 10 -10)
        (cons (make-ufo 70 -50)
            (cons (make-ufo 150 -50)
                (cons (make-ufo 200 -80) 
                    (cons (make-ufo 120 -100) 
                        (cons (make-ufo 210 -110) 
                            (cons (make-ufo 250 -130) '()))))))))

(define starteasy
  (make-status easylou (make-tank (/ WIDTH 2) ABRAMSPEED) (make-ammo #false #false #false) 0))

(define startmedium
    (make-status mediumlou (make-tank (/ WIDTH 2) ABRAMSPEED) (make-ammo #false #false #false) 0))

(define starthard
    (make-status hardlou (make-tank (/ WIDTH 2) WARSHIPSPEED) (make-ammo #false #false #false) 0))

; Run program
(main startmedium)