(require 'test/common)

(defvar eldev--emacs-docker-version "27.2")

(ert-deftest eldev-emacs-docker-emacs-1 ()
  (skip-unless (executable-find "docker"))
  (eldev--test-run "trivial-project"
      ("emacs-docker" eldev--emacs-docker-version "emacs" "--batch")
    (should (= exit-code 0))))

(ert-deftest eldev-emacs-docker-emacs-2 ()
  (skip-unless (executable-find "docker"))
  (eldev--test-run "trivial-project"
      ("--quiet"
       "emacs-docker"
       eldev--emacs-docker-version
       "emacs"
       "--batch"
       "--eval"
       `(prin1 (+ 1 2)))
    (should (string= (substring (string-trim-right stdout "\n*") -1) "3"))
    (should (= exit-code 0))))

(provide 'test/emacs-docker)
