(require 'test/common)

(defvar eldev--docker-emacs-version "27.2")

(ert-deftest eldev-docker-emacs-1 ()
  (skip-unless (eldev-docker-executable nil))
  (let ((eldev--test-eldev-local (expand-file-name default-directory)))
    (eldev--test-run "trivial-project"
        ("--quiet"
         "docker"
         eldev--docker-emacs-version
         "emacs"
         "--batch"
         "--eval"
         `(prin1 (+ 1 2)))
        (should (string= (substring (string-trim-right stdout) -1) "3"))
        (should (= exit-code 0)))))

(ert-deftest eldev-docker-test-1 ()
  (skip-unless (eldev-docker-executable nil))
  (eldev--test-run "project-c" ("clean" "all")
    (should (= exit-code 0)))
  (let ((eldev--test-eldev-local (expand-file-name default-directory)))
    (eldev--test-run "project-c"
        ("docker"
        eldev--docker-emacs-version
        "test")
        (should (= exit-code 0)))))

(provide 'test/emacs-docker)
