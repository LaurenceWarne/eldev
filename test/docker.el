(require 'test/common)

(ert-deftest eldev-emacs-docker-emacs-1 ()
  (skip-unless (eldev-docker-executable nil))
  (eldev--test-run "trivial-project"
      ("--quiet"
       "docker"
       "27.2"
       "emacs"
       "--batch"
       "--eval"
       `(prin1 (+ 1 2)))
    (should (string= (substring (string-trim-right stdout) -1) "3"))
    (should (= exit-code 0))))

(provide 'test/emacs-docker)
