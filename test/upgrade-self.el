(require 'tar-mode)
(require 'test/common)


;; `upgrade-self' must run exactly the same in normal and `external dependencies' mode,
;; i.e. basically ignore the latter.

;; Upgrading _self_ must succeed even from a non-project directory (`empty-project').
(eldev-ert-defargtest eldev-upgrade-self-1 (test-project mode)
                      (("trivial-project" 'normal)
                       ("trivial-project" 'external)
                       ("empty-project"   'normal)
                       ("empty-project"   'external))
  (eldev--test-with-external-dir test-project ()
    :enabled (eq mode 'external)
    (eldev--test-create-eldev-archive "eldev-archive-1")
    (eldev--test-create-eldev-archive "eldev-archive-2" "999.9")
    (let ((eldev--test-eldev-local (concat ":pa:" (eldev--test-tmp-subdir "eldev-archive-1")))
          (eldev--test-eldev-dir   (eldev--test-tmp-subdir "upgrade-self-root")))
      (ignore-errors (delete-directory eldev--test-eldev-dir t))
      (eldev--test-run nil ("version")
        (should (string= stdout (format "eldev %s\n" (eldev-message-version (eldev-find-package-descriptor 'eldev)))))
        (should (= exit-code 0)))
      (eldev--test-run nil (:eval `("--setup" ,`(setf eldev--upgrade-self-from-forced-pa ,(eldev--test-tmp-subdir "eldev-archive-2"))
                                    ,@(when (eq mode 'external) `(,(format "--external=%s" external-dir)))
                                    "upgrade-self"))
        (should (string= stdout "Upgraded or installed 1 package\n"))
        (should (= exit-code 0)))
      (eldev--test-run nil ("version")
        (should (string= stdout "eldev 999.9\n"))
        (should (= exit-code 0))))))

;; Trying to upgrade from the archive we have bootstrapped.  Nothing to do.
(eldev-ert-defargtest eldev-upgrade-self-2 (mode)
                      ('normal 'external)
  (eldev--test-create-eldev-archive "eldev-archive-1")
  (eldev--test-with-external-dir "trivial-project" ()
    :enabled (eq mode 'external)
    (let ((eldev--test-eldev-local (concat ":pa:" (eldev--test-tmp-subdir "eldev-archive-1")))
          (eldev--test-eldev-dir   (eldev--test-tmp-subdir "upgrade-self-root")))
      (ignore-errors (delete-directory eldev--test-eldev-dir t))
      (eldev--test-run nil ("version")
        (should (string= stdout (format "eldev %s\n" (eldev-message-version (eldev-find-package-descriptor 'eldev)))))
        (should (= exit-code 0)))
      (eldev--test-run nil (:eval `("--setup" ,`(setf eldev--upgrade-self-from-forced-pa ,(eldev--test-tmp-subdir "eldev-archive-1"))
                                    ,@(when (eq mode 'external) `(,(format "--external=%s" external-dir)))
                                    "upgrade-self"))
        (should (string= stdout "Eldev is up-to-date\n"))
        (should (= exit-code 0)))
      (eldev--test-run nil ("version")
        (should (string= stdout (format "eldev %s\n" (eldev-message-version (eldev-find-package-descriptor 'eldev)))))
        (should (= exit-code 0))))))


(eldev-ert-defargtest eldev-upgrade-self-dry-run-1 (mode)
                      ('normal 'external)
  (eldev--test-create-eldev-archive "eldev-archive-1")
  (eldev--test-create-eldev-archive "eldev-archive-2" "999.9")
  (eldev--test-with-external-dir "trivial-project" ()
    :enabled (eq mode 'external)
    (let ((eldev--test-eldev-local (concat ":pa:" (eldev--test-tmp-subdir "eldev-archive-1")))
          (eldev--test-eldev-dir   (eldev--test-tmp-subdir "upgrade-self-root")))
      (ignore-errors (delete-directory eldev--test-eldev-dir t))
      (eldev--test-run nil ("version")
        (should (string= stdout (format "eldev %s\n" (eldev-message-version (eldev-find-package-descriptor 'eldev)))))
        (should (= exit-code 0)))
      (eldev--test-run nil (:eval `("--setup" ,`(setf eldev--upgrade-self-from-forced-pa ,(eldev--test-tmp-subdir "eldev-archive-2"))
                                    ,@(when (eq mode 'external) `(,(format "--external=%s" external-dir)))
                                    "upgrade-self" "--dry-run"))
        ;; `--dry-run' intentionally produces exactly the same output.
        (should (string= stdout "Upgraded or installed 1 package\n"))
        (should (= exit-code 0)))
      (eldev--test-run nil ("version")
        ;; But it doesn't actually upgrade anything.
        (should (string= stdout (format "eldev %s\n" (eldev-message-version (eldev-find-package-descriptor 'eldev)))))
        (should (= exit-code 0))))))


;; Reported as issue #43.  The problem was that when the new version had new (or
;; substantially changed) macro definitions, other files would be byte-compiled
;; incorrectly, against old (or missing) definitions.
(eldev-ert-defargtest eldev-upgrade-self-new-macros-1 (mode)
                      ('normal 'external)
  (when (eq system-type 'windows-nt)
    ;; The issue is in editing `.tar' archive with Emacs.
    (ert-skip "this test is known to fail on Windows because of an issue unrelated to Eldev"))
  (eldev--test-create-eldev-archive "eldev-archive-1")
  (let ((inhibit-message t)
        (archive-2-dir   (eldev--test-create-eldev-archive "eldev-archive-2" "999.9"))
        tar-buffers)
    ;; Inject a macro for testing purposes.  We can edit `.tar' archives with Elisp
    ;; functions, though in quite an ugly way.
    (unwind-protect
        (with-current-buffer (car (push (find-file-noselect (expand-file-name "eldev-999.9.tar" archive-2-dir)) tar-buffers))
          ;; If the macro and its usage were in the same file, bug would not be triggered.
          (dolist (entry '(("eldev.el"      "(defun eldev--test-function () (eldev--test-new-macro))")
                           ("eldev-util.el" "(defmacro eldev--test-new-macro () 1)")))
            (goto-char 1)
            (search-forward (format "/%s" (car entry)))
            (with-current-buffer (car (push (tar-extract) tar-buffers))
              (search-forward "\n(provide 'eldev")
              (forward-line)
              (insert (cadr entry) "\n")
              (save-buffer)))
          (save-buffer))
      (dolist (buffer tar-buffers)
        (kill-buffer buffer))))
  (eldev--test-with-external-dir "trivial-project" ()
    :enabled (eq mode 'external)
    (let ((eldev--test-eldev-local (concat ":pa:" (eldev--test-tmp-subdir "eldev-archive-1")))
          (eldev--test-eldev-dir   (eldev--test-tmp-subdir "upgrade-self-root")))
      (ignore-errors (delete-directory eldev--test-eldev-dir t))
      (eldev--test-run nil ("version")
        (should (string= stdout (format "eldev %s\n" (eldev-message-version (eldev-find-package-descriptor 'eldev)))))
        (should (= exit-code 0)))
      (eldev--test-run nil (:eval `("--setup" ,`(setf eldev--upgrade-self-from-forced-pa ,(eldev--test-tmp-subdir "eldev-archive-2"))
                                    ,@(when (eq mode 'external) `(,(format "--external=%s" external-dir)))
                                    "upgrade-self"))
        (should (string= stdout "Upgraded or installed 1 package\n"))
        (should (= exit-code 0)))
      (eldev--test-run nil ("version")
        (should (string= stdout "eldev 999.9\n"))
        (should (= exit-code 0)))
      (eldev--test-run nil ("eval" `(eldev--test-function))
        (should (string= stdout "1\n"))
        (should (= exit-code 0))))))


(provide 'test/upgrade-self)
