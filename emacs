;; -*- mode:emacs-lisp -*-

(add-to-list 'load-path "~/.emacs.d/my")
(add-to-list 'load-path "~/.emacs.d/lisp")
(add-to-list 'load-path "~/.emacs.d/lisp/auto-install")

(keyboard-translate ?\C-h ?\C-?)

(show-paren-mode 1)
(column-number-mode 1)
(delete-selection-mode)

;; emacs-24.4.1 勝手に全てのファイルの行頭にスペースが入る
(electric-indent-mode -1)

;(setq vc-handled-backends '(RCS CVS SVN SCCS Bzr Git Hg Mtn Arch))
(setq vc-handled-backends '(RCS CVS SVN SCCS Bzr Hg Mtn Arch))
(put 'narrow-to-region 'disabled nil)
(put 'narrow-to-page 'disabled nil)

(setq inhibit-startup-message t)

(custom-set-variables
 '(safe-local-variable-values
   (quote
    ((sh-indent-comment . t)
     (flycheck-sh-bash-args "-O" "extglob")
     (ps-mode-tab . 2)
     (mwg-no-delete-trailing-whitespaces . t)
     (c-basic-offset 2)
     (eval sh-set-shell "bash")))))

;;-----------------------------------------------------------------------------
;; mwg.el (https://github.com/akinomyoga/myemacs)

(load "cc-mode") ;; somehow this is needed in neumann
(load "mwg")
(mwg-init-tabwidth 2)
(mwg-init-pcmark)
(mwg-init-mouse)

(custom-set-variables
 '(frame-background-mode 'light))
(mwg-init-custom-color)

(mwg-add-hook-csharp) ;; recursive load error??
(mwg-add-hook-gnuplot "C:\\usr\\prog\\gnuplot\\bin\\pgnuplot.exe")
(mwg-add-hook-bashfc)
(mwg-add-hook-xml-mode)
(mwg-add-hook-mwg-c++exp)
(mwg-add-hook-mwg-ttx)
(mwg-setup-mwg-doxygen)
(mwg-add-hook-js2-mode)

;; (setq auto-mode-alist (append
;;                        '(("\\.\\([xs]?html?\\)$" . xml-mode))
;;                        auto-mode-alist))

;;-----------------------------------------------------------------------------
;; settings for switching buffers

(iswitchb-mode 1)

;; ido に乗り換えようとして暫く使ったが微妙だった

;; (require 'ido)
;; (ido-mode t)
;; (add-hook 'ido-setup-hook
;;           '(lambda()
;;              ;; C-b で確定
;;              (define-key ido-buffer-completion-map (kbd "C-b") 'ido-exit-minibuffer)))

;;-----------------------------------------------------------------------------
;; package-install でインストールした package の初期化
;;
;;   package-initialize は init.el の後に実行されるので、
;;   init.el の中で package.el でインストールした package に触る事ができない。
;;
;;   実際に auto-complete-mode の時には皆 init.el の中で (package-initialize) している様だ。
;;   特に ac-modes の既定値に追加を行うのが難しい。
;;   更にいうならばここで auto-complete-config をロードするしかない。
;;   http://stackoverflow.com/questions/11127109/emacs-24-package-system-initialization-problems
;;
(require 'package)
(setq package-enable-at-startup nil)
(add-to-list 'package-archives '("melpa" . "http://melpa.milkbox.net/packages/") t)
(add-to-list 'package-archives '("marmalade" . "http://marmalade-repo.org/packages/"))
(package-initialize)

;; 2018-06-28: 以下の padparadscha 由来の設定が
;;   何のためにあったのか不明
(defvar mwg/config/package.guard nil)
(eval-after-load "package"
  (unless mwg/config/package.guard
    (setq mwg/config/package.guard t)
    (require 'package)
    (add-to-list 'package-archives
                 '("melpa" . "http://melpa.org/packages/") t)
    (when (< emacs-major-version 24)
      ;; For important compatibility libraries like cl-lib
      (add-to-list 'package-archives '("gnu" . "http://elpa.gnu.org/packages/")))
    (package-initialize)))

;;-----------------------------------------------------------------------------
;; settings for auto-complete-mode

(mwg-add-hook-auto-complete)

;;
;; company-mode を試してみたが補完されたりされなかったりが分からない。
;; C++ で試していると補完される単語は補完されるが、
;; 補完されない単語の方が多い。dabbrev ではちゃんと補完できるのに、
;; company-mode の補完候補としては列挙されないのである。
;; ちゃんと dabbrev も company-backends に登録されている。謎だ。
;;
;; (progn
;;   ;; from http://qiita.com/sune2/items/b73037f9e85962f5afb7
;;   (add-hook 'after-init-hook 'global-company-mode) ; 全バッファで有効にする 
;;   (setq company-idle-delay 0) ; デフォルトは0.5
;;   (setq company-minimum-prefix-length 3) ; デフォルトは4
;;   ;; (setq company-selection-wrap-around t) ; 候補の一番下でさらに下に行こうとすると一番上に戻る

;;   ;; from http://qiita.com/wh11e7rue/items/6ffe27797c3eac13b67e
;;   (copy-face 'popup-menu-face 'company-tooltip)
;;   (copy-face 'popup-menu-face 'company-tooltip-common)
;;   (copy-face 'popup-menu-selection-face 'company-tooltip-selection)
;;   (copy-face 'popup-menu-selection-face 'company-tooltip-common-selection)
;;   (copy-face 'popup-menu-summary-face 'company-tooltip-annotation)
;;   (copy-face 'popup-menu-selection-face 'company-tooltip-annotation-selection)
;;   (copy-face 'popup-scroll-bar-background-face 'company-scrollbar-bg)
;;   (copy-face 'popup-scroll-bar-foreground-face 'company-scrollbar-fg)
;;   (copy-face 'ac-completion-face 'company-preview)
;;   (copy-face 'ac-completion-face 'company-preview-common))

;;-----------------------------------------------------------------------------
;; settings for spell checker (ispell)

(setq ispell-program-name "aspell"
      ispell-extra-args '("--sug-mode=ultra" "--lang=en_US"))

;;-----------------------------------------------------------------------------
;; settings for auto-complete-clang-async

;; (require 'auto-complete-clang-async)
;; (defun ac-cc-mode-setup ()
;;   (setq ac-clang-complete-executable "~/.emacs.d/lisp/auto-complete/clang-complete")
;;   (setq ac-sources '(ac-source-clang-async))
;;   (ac-clang-launch-completion-process))
;; (defun my-ac-config ()
;;   (add-hook 'c-mode-common-hook 'ac-cc-mode-setup)
;;   (add-hook 'auto-complete-mode-hook 'ac-common-setup)
;;   (global-auto-complete-mode t))
;; (my-ac-config)
;;
;; Process clang-complete segmentation fault (core dumped)

;;-----------------------------------------------------------------------------
;; settings for auto-complete-clang

;; ;; v1
;; (require 'auto-complete-clang)
;; (setq ac-quick-help-delay 0)
;; (defun my-ac-config ()
;;   (setq-default ac-sources '(ac-source-abbrev ac-source-dictionary ac-source-words-in-same-mode-buffers))
;;   (add-hook 'c++-mode-hook 'my-ac-cc-mode-setup)
;;   (global-auto-complete-mode t))
;; (defun my-ac-cc-mode-setup ()
;;   (setq ac-sources (append '(ac-source-clang ac-source-yasnippet) ac-sources))
;;   (setq ac-clang-prefix-header "/home/murase/test/cpp/stdlib.pch"))
;; (my-ac-config)

;; ;; v2 やはり遅いので off にする。
;; (defun my-ac-cc-mode-clang-setup ()
;;   (require 'auto-complete-clang)
;;   ;; (setq ac-quick-help-delay 0)
;;   ;; (setq ac-clang-prefix-header "/home/murase/.emacs.d/lisp/stdlib.pch"
;;   ;;       ac-clang-flags '("-std=c++11" "-w" "-ferror-limit" "1"))
;;   (setq clang-completion-pch "/home/murase/.emacs.d/lisp/auto-complete-clang.pch"
;;         clang-completion-flags '("-std=c++11" "-w" "-ferror-limit" "1")
;;         clang-completion-suppress-error t)
;;   (setq ac-sources (append '(ac-source-clang-complete) ac-sources)))
;;
;; ;; laguerre に於ける設定
;; (defun my-ac-cc-mode-clang-setup ()
;;   (require 'auto-complete-clang)
;;   (setq clang-completion-pch "/home/murase/.emacs.d/lisp/auto-complete-clang.pch"
;;         clang-completion-flags '("-std=c++11" "--gcc-toolchain=/home/murase/opt/gcc/4.8.3"
;;                                  "-w" )
;;         ;; "-ferror-limit" "1" このオプションはあると×
;;         clang-completion-suppress-error t)
;;   (setq ac-sources (append '(ac-source-clang-complete) ac-sources)))
;;
;; (add-hook 'c++-mode-hook 'my-ac-cc-mode-clang-setup)

;;-----------------------------------------------------------------------------
;; laguerre の既定の設定

;; ;; enable visual feedback on selections
;; ;(setq transient-mark-mode t)

;; ;; default to better frame titles
;; (setq frame-title-format
;;       (concat  "%b - emacs@" (system-name)))

;; default to unified diffs
(setq diff-switches "-u")

;; ;; always end a file with a newline
;; ;(setq require-final-newline 'query)

;; ;;; uncomment for CJK utf-8 support for non-Asian users
;; ;; (require 'un-define)

;;-----------------------------------------------------------------------------
;; 日本語入力の設定

;; (eval-after-load "kkc"
;;   '(progn
;;      (define-key kkc-keymap [S-left] 'kkc-shorter)
;;      (define-key kkc-keymap [S-right] 'kkc-longer)
;;      (define-key kkc-keymap [up] 'kkc-prev)
;;      (define-key kkc-keymap [down] 'kkc-next)
;;      (define-key kkc-keymap [right] 'kkc-next-phrase)
;;      (define-key kkc-keymap "\C-g" 'kkc-cancel)

;;      (define-key kkc-keymap [f6] 'kkc-hiragana)
;;      (define-key kkc-keymap [f7] 'kkc-katakana)

;;      (define-key kkc-keymap "\C-i" nil)
;;      (define-key kkc-keymap "\C-o" nil)
;;      (define-key kkc-keymap "\C-c" nil)))
;; (defun quail-define-rules/special-kana ()
;;   (quail-define-rules
;;    ("la" "ぁ") ("li" "ぃ") ("lu" "ぅ") ("le" "ぇ") ("lo" "ぉ")
;;    ("lka" "ヵ") ("lke" "ヶ") ("ltu" "っ") ("ltsu" "っ")
;;    ("lwa" "ゎ") ("lya" "ゃ") ("lyu" "ゅ") ("lyo" "ょ")
;;    ("dha" ["でゃ"]) ("dhi" ["でぃ"]) ("dhu" ["でゅ"]) ("dhe" ["でぇ"]) ("dho" ["でょ"])
;;    ("tha" ["てゃ"]) ("thi" ["てぃ"]) ("thu" ["てゅ"]) ("the" ["てぇ"]) ("tho" ["てょ"])
;;    ("wyi" "ゐ") ("wye" "ゑ")))
;; (eval-after-load "leim/quail/japanese"
;;   '(quail-define-rules/special-kana))

;;-----------------------------------------------------------------------------
;; Evil (vim like key-bindings in emacs)
;;   これは本来の Emacs の操作が全然できなくなるので駄目

;; (require 'evil)
;; (evil-mode 1)
;; (setq evil-insert-state-map nil)

;;-----------------------------------------------------------------------------

