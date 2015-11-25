;;; core-ui.el --- interface settings
;; see lib/ui-defuns.el

(setq-default
 blink-matching-paren nil
 show-paren-delay 0.075

 ;; Multiple cursors across buffers cause a strange redraw delay for
 ;; some things, like auto-complete or evil-mode's cursor color
 ;; switching.
 cursor-in-non-selected-windows  nil
 highlight-nonselected-windows nil

 uniquify-buffer-name-style      nil
 visible-bell                    nil  ; silence of the bells
 use-dialog-box                  nil  ; always avoid GUI
 redisplay-dont-pause            t
 indicate-buffer-boundaries      nil
 indicate-empty-lines            t
 fringes-outside-margins         t
 hl-line-sticky-flag             nil  ; only highlight in one window

 jit-lock-defer-time nil
 jit-lock-stealth-time 1

 resize-mini-windows t)

(defvar narf-fringe-size 6)
(if window-system
    (progn
      (fringe-mode narf-fringe-size)
      (setq frame-title-format '(buffer-file-name "%f" ("%b")))
      (setq initial-frame-alist '((width . 120) (height . 80)))

      (set-frame-font narf-default-font)
      (set-face-attribute 'default t :font narf-default-font)

      (define-fringe-bitmap 'tilde [64 168 16] nil nil 'center)
      (setcdr (assq 'empty-line fringe-indicator-alist) 'tilde)
      (set-fringe-bitmap-face 'tilde 'font-lock-comment-face))
  (menu-bar-mode -1))

(mapc (lambda (x) (set-fontset-font "fontset-default" `(,x . ,x) "DejaVu Sans" nil 'prepend))
      '(?☑ ?☐))

(blink-cursor-mode  1)    ; do blink cursor
(tooltip-mode      -1)    ; show tooltips in echo area

;; Highlight line
(add-hook! (prog-mode puml-mode markdown-mode) 'hl-line-mode)

;; Disable line highlight in visual mode
(defvar narf--hl-line-mode nil)
(make-variable-buffer-local 'narf--hl-line-mode)

(defun narf|hl-line-on ()
  (when narf--hl-line-mode (hl-line-mode +1)))
(defun narf|hl-line-off ()
  (when narf--hl-line-mode (hl-line-mode -1)))

(add-hook! hl-line-mode (if hl-line-mode (setq narf--hl-line-mode t)))
(add-hook! evil-visual-state-entry 'narf|hl-line-off)
(add-hook! evil-visual-state-exit  'narf|hl-line-on)

;; Hide modeline in help windows ;;;;;;;
(add-hook! help-mode (setq-local mode-line-format nil))

;; Highlight TODO/FIXME/NOTE tags ;;;;;;
(defface narf-todo-face  '((t (:inherit font-lock-warning-face))) "Face for TODOs")
(defface narf-fixme-face '((t (:inherit font-lock-warning-face))) "Face for FIXMEs")
(defface narf-note-face  '((t (:inherit font-lock-warning-face))) "Face for NOTEs")
(add-hook! (prog-mode emacs-lisp-mode)
  (font-lock-add-keywords nil '(("\\<\\(TODO\\((.+)\\)?:?\\)"  1 'narf-todo-face prepend)
                                ("\\<\\(FIXME\\((.+)\\)?:?\\)" 1 'narf-fixme-face prepend)
                                ("\\<\\(NOTE\\((.+)\\)?:?\\)"  1 'narf-note-face prepend))))

;; Fade out when unfocused ;;;;;;;;;;;;;
(add-hook! focus-in  (set-frame-parameter nil 'alpha 100))
(add-hook! focus-out (set-frame-parameter nil 'alpha 80))

;; Plugins ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(use-package yascroll
  :commands (yascroll-bar-mode)
  :config
  (add-to-list 'yascroll:enabled-window-systems 'mac)
  (setq yascroll:scroll-bar 'left-fringe
        yascroll:delay-to-hide nil))

(use-package hideshow
  :commands (hs-minor-mode hs-toggle-hiding hs-already-hidden-p)
  :diminish hs-minor-mode
  :config (setq hs-isearch-open t)
  :init
  (after! evil
    (defun narf-load-hs-minor-mode ()
      (hs-minor-mode 1)
      (advice-remove 'evil-toggle-fold 'narf-load-hs-minor-mode))
    (advice-add 'evil-toggle-fold :before 'narf-load-hs-minor-mode))

  ;; Prettify code folding in emacs ;;;;;;
  (define-fringe-bitmap 'hs-marker [16 48 112 240 112 48 16] nil nil 'center)
  (defface hs-face '((t (:background "#ff8")))
    "Face to hightlight the ... area of hidden regions"
    :group 'hideshow)
  (defface hs-fringe-face '((t (:foreground "#888")))
    "Face used to highlight the fringe on folded regions"
    :group 'hideshow)

  (setq hs-set-up-overlay
        (lambda (ov)
          (when (eq 'code (overlay-get ov 'hs))
            (let* ((marker-string "*fringe-dummy*")
                   (marker-length (length marker-string))
                   (display-string (format " ... " (count-lines (overlay-start ov)
                                                                (overlay-end ov)))))
              (put-text-property 0 marker-length 'display
                                 (list 'right-fringe 'hs-marker 'hs-fringe-face) marker-string)
              (put-text-property 0 (length display-string) 'face 'hs-face display-string)
              (overlay-put ov 'before-string marker-string)
              (overlay-put ov 'display display-string))))))

(use-package rainbow-delimiters
  :commands rainbow-delimiters-mode
  :init (add-hook! (emacs-lisp-mode lisp-mode js2-mode scss-mode) 'rainbow-delimiters-mode)
  :config (setq rainbow-delimiters-max-face-count 4))

(use-package rainbow-mode :defer t
  :init
  (add-hook! rainbow-mode
    (when narf--hl-line-mode
      (hl-line-mode (if rainbow-mode -1 1)))))

(use-package volatile-highlights
  :diminish volatile-highlights-mode
  :config
  (vhl/define-extension 'my-undo-tree-highlights
    'undo-tree-undo 'undo-tree-redo)
  (vhl/install-extension 'my-undo-tree-highlights)
  (vhl/define-extension 'my-yank-highlights
    'evil-yank 'evil-paste-after 'evil-paste-before 'evil-paste-pop)
  (vhl/install-extension 'my-yank-highlights)
  (volatile-highlights-mode t))

(use-package nlinum
  :commands nlinum-mode
  :preface
  (defvar narf--hl-nlinum-overlay nil)
  (defvar narf--hl-nlinum-line nil)
  (defvar nlinum-format " %4d ")
  (defface linum-highlight-face '((t (:inherit linum))) "Face for line highlights")
  (setq linum-format "%3d ")
  :init
  (defun narf|nlinum-enable ()
    (nlinum-mode +1)
    (add-hook 'post-command-hook 'narf|nlinum-hl-line t))

  (defun narf|nlinum-disable ()
    (nlinum-mode -1)
    (remove-hook 'post-command-hook 'narf|nlinum-hl-line)
    (narf|nlinum-unhl-line))

  (add-hook!
    (markdown-mode prog-mode scss-mode web-mode)
    'narf|nlinum-enable)
  :config
  (defun narf|nlinum-unhl-line ()
    "Unhighlight line number"
    (when narf--hl-nlinum-overlay
      (let* ((ov narf--hl-nlinum-overlay)
             (disp (get-text-property 0 'display (overlay-get ov 'before-string)))
             (str (nth 1 disp)))
        (put-text-property 0 (length str) 'face 'linum str)
        (setq narf--hl-nlinum-overlay nil
              narf--hl-nlinum-line nil))))

  (defun narf|nlinum-hl-line (&optional line)
    "Highlight line number"
    (let ((line-no (or line (string-to-number (format-mode-line "%l")))))
      (when (and nlinum-mode (not (eq line-no narf--hl-nlinum-line)))
        (let* ((pbol (if line (save-excursion (goto-char (point-min))
                                              (forward-line line-no)
                                              (point-at-bol))
                       (line-beginning-position)))
               (peol (1+ pbol)))
          ;; Handle EOF case
          (let ((max (point-max)))
            (when (>= peol max)
              (setq peol max)))
          (jit-lock-fontify-now pbol peol)
          (let* ((overlays (overlays-in pbol peol))
                 (ov (-first (lambda (item) (overlay-get item 'nlinum)) overlays)))
            (when ov
              (narf|nlinum-unhl-line)
              (let ((str (nth 1 (get-text-property 0 'display (overlay-get ov 'before-string)))))
                (put-text-property 0 (length str) 'face 'linum-highlight-face str)
                (setq narf--hl-nlinum-overlay ov
                      narf--hl-nlinum-line line-no))))))))

  (add-hook! nlinum-mode
    (setq nlinum--width
          (length (int-to-string (count-lines (point-min) (point-max)))))))


;; Mode-line ;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package spaceline-segments
  :init
  (defvar narf--env-version nil)
  (defvar narf--env-command nil)
  (make-variable-buffer-local 'narf--env-version)
  (make-variable-buffer-local 'narf--env-command)
  :config
  (setq-default
   powerline-default-separator nil
   powerline-height 19
   spaceline-highlight-face-func 'spaceline-highlight-face-evil-state)

  (defface mode-line-is-modified nil "Face for mode-line modified symbol")
  (defface mode-line-buffer-file nil "Face for mode-line buffer file path")

  ;; Custom modeline segments
  (spaceline-define-segment narf-buffer-path
    (if buffer-file-name
        (let* ((project-path (let (projectile-require-project-root) (projectile-project-root)))
               (buffer-path (file-relative-name buffer-file-name project-path))
               (max-length (/ (window-width) 2))
               (path-len (length buffer-path)))
          (concat (file-name-nondirectory (directory-file-name project-path))
                  "/"
                  (if (> path-len max-length)
                      (concat "…" (replace-regexp-in-string
                                   "^.*?/" "/"
                                   (substring buffer-path (- path-len max-length) path-len)))
                    buffer-path)))
      "%b")
    :face (if active 'mode-line-buffer-file 'mode-line-inactive)
    :skip-alternate t
    :tight-right t)

  (spaceline-define-segment narf-buffer-modified
    (concat
     (when buffer-file-name
       (concat
        (when (buffer-modified-p) "[+]")
        (unless (file-exists-p buffer-file-name) "[!]")))
     (if buffer-read-only "[RO]"))
    :face mode-line-is-modified
    :when (not (string-prefix-p "*" (buffer-name)))
    :skip-alternate t
    :tight t)

  (spaceline-define-segment narf-buffer-encoding-abbrev
    "The line ending convention used in the buffer."
    (symbol-name buffer-file-coding-system)
    :when (not (string-match-p "\\(utf-8\\|undecided\\)"
                               (symbol-name buffer-file-coding-system))))

  (spaceline-define-segment narf-buffer-position
    "A more vim-like buffer position."
    (let ((start (window-start))
          (end (window-end))
          (pend (point-max)))
      (if (and (eq start 1)
               (eq end pend))
          ":All"
        (let ((perc (/ end 0.01 pend)))
          (cond ((eq start 1) ":Top")
                ((>= perc 100) ":Bot")
                (t (format ":%d%%%%" perc))))))
    :tight t)

  (spaceline-define-segment narf-vc
    "Version control info"
    (concat (downcase vc-mode)
            (case (vc-state buffer-file-name)
              ('edited "+")
              ('conflict "!!!")
              (t "")))
    :when (and active vc-mode)
    :face other-face
    :tight t)

  (spaceline-define-segment narf-env-version
    "A HUD that shows which part of the buffer is currently visible."
    (when (and narf--env-command (not narf--env-version))
      (narf|spaceline-env-update))
    narf--env-version
    :when (and narf--env-version (memq major-mode '(ruby-mode enh-ruby-mode python-mode))))

  (spaceline-define-segment narf-hud
    "A HUD that shows which part of the buffer is currently visible."
    (powerline-hud highlight-face other-face 1)
    :face other-face
    :tight-right t)

  (defface mode-line-count-face nil "")
  (make-variable-buffer-local 'anzu--state)
  (spaceline-define-segment narf-anzu
    "Show the current match number and the total number of matches. Requires
anzu to be enabled."
    (let ((here anzu--current-position)
          (total anzu--total-matched))
      (format " %s/%d%s "
              (anzu--format-here-position here total)
              total (if anzu--overflow-p "+" "")))
    :face (if active 'mode-line-count-face 'mode-line-inactive)
    :when (and (> anzu--total-matched 0) (evil-ex-hl-active-p 'evil-ex-search))
    :skip-alternate t
    :tight t)

  ;; TODO mode-line-iedit-face default face
  (spaceline-define-segment narf-iedit
    "Show the number of matches and what match you're on (or after). Requires
iedit."
    (let ((this-oc (iedit-find-current-occurrence-overlay))
          (length  (or (ignore-errors (length iedit-occurrences-overlays)) 0)))
      (format "%s/%s"
              (save-excursion
                (unless this-oc
                  (iedit-prev-occurrence)
                  (setq this-oc (iedit-find-current-occurrence-overlay)))
                (if this-oc
                    ;; NOTE: Not terribly reliable
                    (- length (-elem-index this-oc iedit-occurrences-overlays))
                  "-"))
              length))
    :face (if active 'mode-line-count-face 'mode-line-inactive)
    :skip-alternate t
    :when (bound-and-true-p iedit-mode))

  ;; TODO mode-line-substitute-face default face
  (defface mode-line-substitute-face nil "")
  ;; TODO This is very hackish; refactor?
  (spaceline-define-segment narf-evil-substitute
    "Show number of :s matches in real time."
    (let ((range (if evil-ex-range
                     (cons (car evil-ex-range) (cadr evil-ex-range))
                   (cons (line-beginning-position) (line-end-position))))
          (pattern (car-safe (evil-delimited-arguments evil-ex-argument 2))))
      (if pattern
          (format "%s matches" (count-matches pattern (car range) (cdr range)) evil-ex-argument)
        " ... "))
    :face (if active 'mode-line-count-face 'mode-line-inactive)
    :skip-alternate t
    :when (and (evil-ex-p) (evil-ex-hl-active-p 'evil-ex-substitute)))

  (spaceline-define-segment narf-major-mode
    (concat "[" mode-name "]")
    :skip-alternate t)

  ;; Initialize modeline
  (spaceline-install
   ;; Left side
   '((evil-state :face highlight-face :when active)
     narf-anzu narf-iedit narf-evil-substitute
     (narf-buffer-path remote-host)
     narf-buffer-modified
     narf-vc
     ((flycheck-error flycheck-warning flycheck-info) :when active))
   ;; Right side
   '((selection-info :face highlight-face :skip-alternate t)
     narf-env-version
     narf-buffer-encoding-abbrev
     (narf-major-mode
      (minor-modes :separator " " :tight t)
      process :when active)
     (global :when active)
     ("%l·%c" narf-buffer-position)
     narf-hud
     )))

(provide 'core-ui)
;;; core-ui.el ends here
