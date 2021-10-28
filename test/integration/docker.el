(require 'test/common)

(defvar eldev--docker-emacs-version "27.2")

(ert-deftest eldev-docker-emacs-1 ()
  (skip-unless (eldev-docker-executable nil))
  (shell-command "docker build -t local/eldev-emacs-dev .")
  (eldev--test-run "trivial-project"
      ("--quiet"
       "docker"
       "local/eldev-emacs-dev" ;eldev--docker-emacs-version
       "emacs"
       "--batch"
       "--eval"
       `(prin1 (+ 1 2)))
    (should (string= (substring (string-trim-right stdout) -1) "3"))
    (should (= exit-code 0))))

(ert-deftest eldev-docker-test-1 ()
  (skip-unless (eldev-docker-executable nil))
  (eldev--test-run "project-c" ("clean" "all")
    (should (= exit-code 0)))
  (eldev--test-run "project-c"
      ("--trace"
       "docker"
       "local/eldev-emacs-dev" ;eldev--docker-emacs-version
       "test")
    (should (= exit-code 0))))

(provide 'test/emacs-docker)
