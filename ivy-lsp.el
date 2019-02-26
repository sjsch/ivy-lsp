;;; ivy-lsp.el --- Search for language server symbols using ivy.

;; Author: Sam Schweigel <s.schweigel@gmail.com>
;; Version: 0.1
;; Package-Requires: ((emacs "25.1") (ivy "0.10.0"))
;; Keywords: ivy, lsp, search

(require 'lsp)
(require 'ivy)

(defun ivy-lsp-format-result (root result)
  (let* ((fullpath (gethash "uri" (gethash "location" result)))
         (file (file-relative-name (string-remove-prefix "file://" fullpath) root))
         (kind (alist-get (gethash "kind" result) lsp--symbol-kind))
         (loc (let ((locs (gethash "location" result)))
                (if (sequencep locs)
                    locs
                  (list locs)))))
    (propertize
     (concat
      (propertize file 'face dired-directory-face)
      " "
      (propertize kind 'face font-lock-builtin-face)
      " "
      (gethash "name" result))
     'location loc)))

(defun ivy-lsp-symbols-function (workspaces root str)
  (or
   (ivy-more-chars)
   (with-lsp-workspaces workspaces
     (let* ((results (lsp-send-request
                      (lsp-make-request "workspace/symbol"
                                        (list str)))))
       (mapcar (lambda (r)
                 (ivy-lsp-format-result
                  root r))
               results)))))

;;;###autoload
(defun ivy-lsp-symbols ()
  "Perform an interactive symbol search."
  (interactive)
  (let ((workspaces (lsp-workspaces))
        (root (lsp-workspace-root)))
    (ivy-read "Symbol: " (lambda (s) (ivy-lsp-symbols-function
                                      workspaces root s))
              :dynamic-collection t
              :history 'ivy-lsp-symbols-history
              :caller 'ivy-lsp-symbols
              :action (lambda (r)
                        (xref--show-xrefs
                         (lsp--locations-to-xref-items
                          (get-text-property 0 'location r))
                         nil)))))

;;; ivy-lsp.el ends here
