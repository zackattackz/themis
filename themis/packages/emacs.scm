
(define-module (themis packages emacs)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix build-system emacs)
  #:use-module (gnu packages emacs-xyz)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages admin))

(define-public emacs-exwm-themis
  (package
    (inherit emacs-exwm)
    (name "emacs-exwm-themis")
    (inputs (modify-inputs
	     (package-inputs emacs-exwm)
	     (append shepherd procps)))
    (arguments
     `(#:emacs ,emacs
       #:phases
       (modify-phases %standard-phases
         (add-after 'build 'install-xsession
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (xsessions (string-append out "/share/xsessions"))
                    (bin (string-append out "/bin"))
                    (exwm-executable (string-append bin "/exwm")))
               ;; Add a .desktop file to xsessions
               (mkdir-p xsessions)
               (mkdir-p bin)
               (make-desktop-entry-file
                (string-append xsessions "/exwm.desktop")
                #:name ,name
                #:comment ,(package-synopsis emacs-exwm)
                #:exec exwm-executable
                #:try-exec exwm-executable)
               ;; Add a shell wrapper to bin
               (with-output-to-file exwm-executable
                 (lambda _
                   (format #t "#!~a ~@
                     [ -f \"$HOME/.profile\"] && . \"$HOME/.profile\" ~@
                     ~a +SI:localuser:$USER ~@
                     export _JAVA_AWT_WM_NONREPARENTING=1 ~@
                     [ -z \"$(~a -u $USER shepherd)\" ] && ~a ~@
                     exec ~a --exit-with-session ~a -mm --use-exwm ~%"
                           (search-input-file inputs "/bin/sh")
                           (search-input-file inputs "/bin/xhost")
			   (search-input-file inputs "/bin/pgrep")
			   (search-input-file inputs "/bin/shepherd")
                           (search-input-file inputs "/bin/dbus-launch")
                           (search-input-file inputs "/bin/emacs"))))
               (chmod exwm-executable #o555)
               #t))))))))
