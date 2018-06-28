;; -*- mode:emacs-lisp -*-

(add-to-list 'load-path "~/.emacs.d/my")
(add-to-list 'load-path "~/.emacs.d/lisp")
(add-to-list 'load-path "~/.emacs.d/lisp/auto-install")

(show-paren-mode 1)
(column-number-mode 1)
(delete-selection-mode)

;; emacs-24.4.1 勝手に全てのファイルの行頭にスペースが入る
(electric-indent-mode -1)

(iswitchb-mode 1)

;; (require 'ido)
;; (ido-mode t)
;; (add-hook 'ido-setup-hook
;;           '(lambda()
;;              ;; C-b で確定
;;              (define-key ido-buffer-completion-map (kbd "C-b") 'ido-exit-minibuffer)))

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

(mwg-add-hook-auto-complete)
;;-----------------------------------------------------------------------------
