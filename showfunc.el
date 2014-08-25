(defvar show-func-map nil 
  "Keymap for show-func temporary buffer.")

(if show-func-map ()
  (setq show-func-map (make-sparse-keymap))
  (suppress-keymap show-func-map t)
  (define-key show-func-map "q" 'kill-func-buffer)
  (set-keymap-parent show-func-map widget-keymap)
)

(defun kill-func-buffer (&rest _ignore)
  "Cancel the function dialog."
  (interactive)
  (kill-buffer (current-buffer))
)

(defun show-func ()
  "Show the cpp functions in the current buffer"
  (interactive)
  (setq regExD (make-hash-table :test 'equal))
  (puthash "c++-mode" "^\\([\s-]\\{0,\\}[[:alpha:]][^if|^wh]\\)\\(\\)\\(.*\\)::\\(\\w+\\)(\\(.*\\))\\(.*\\)\n.*{" regExD)
  (puthash "python-mode" "^\\([\s-]\\{0,\\}\\)def\\(.*\\):" regExD)
  (puthash "emacs-lisp-mode" "^\\([\s-]\\{0,\\}\\)(defun\\(.*\\)(.*)" regExD)
  (puthash "go-mode" "^\\([\s-]\\{0,\\}\\)func\\(.*\\)(.*).*{" regExD)
  (setq currentmode major-mode)
  (setq regex (gethash (format "%s" currentmode) regExD))
  (unless regex (setq regex (gethash "c++-mode" regExD)))
 
;  (message "%s %s" currentmode regex)

  ;; build the functions buffer
  (setq buf-name "*Functions*")
  (let ((current (current-buffer))      ; buffer where to search
        (buffer (get-buffer-create buf-name))
        (nb 0)                          ; count found occurences
        (fct-name nil)                  ; name of the found function
        (fct-loc nil))                  ; location of the found function
    (save-excursion
      (set-buffer buffer)
      (let ((inhibit-read-only t))
        (erase-buffer))
      (widget-insert "Click or type RET on a function to explore it. Click on Cancel or type \"q\" to quit.\n\n")
      (set-buffer current)

      (save-restriction
        (widen)
        (goto-char (point-min))
        (while (re-search-forward regex nil t)
          (progn
            (setq nb (1+ nb))
            (setq fct-name (replace-regexp-in-string "[\t\n{]*" "" (buffer-substring (match-beginning 0) (match-end 0))))
            (setq fct-loc (point))
            (set-buffer buffer)
            ;; insert hyperlink to the source code
            (widget-create 'push-button
                           :button-face 'default
                           :tag fct-name
                           :value (cons current fct-loc)
                           :help-echo (concat "Jump to " fct-name)
                           :notify (lambda (widget &rest ignore)
                                     (pop-to-buffer (car (widget-value widget)))
                                     (goto-char (cdr (widget-value widget)))
						             (kill-buffer buf-name)
                                    )
             )
            (widget-insert "\n")
            (set-buffer current))))

      (set-buffer buffer)
      (widget-insert (format "\n%d occurence%s found in %s\n" nb
                             (if (> nb 1) "s" "") (buffer-name current)))
      (widget-create 'push-button
                     :tag "Cancel"
                     :notify 'kill-func-buffer)
      (use-local-map show-func-map)
      (setq buffer-read-only t)
      )
    (pop-to-buffer buffer))
)
