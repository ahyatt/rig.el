;;; rig.el ---                                  -*- lexical-binding: t; -*-

;; Copyright (C) 2016  Ellis Adigvom

;; Author:  <ellisadigvom@gmail.com>
;; Keywords: 
;; Package-Version: 20161204.1738
;; Version: 0.0.1

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This file defines a standalone configuration loading system similar
;; to spacemacs' layers, but hopefully more modular.

;; Example usage:
;; (rig
;;  :name ""
;;  :mail ""
;;  :font '(:family "drift")
;;  :theme 'dracula
;;  :modules '(better-defaults
;; 	       evil
;; 	       ivy
;; 	       hydra
;; 	       lisp
;; 	       company
;; 	       jvm))


;; TODO:
;;  + tests
;;  + documentation
;;  + add a system for documenting modules and mixins
;;  + think of a namespacing scheme for functions defined by rig
;;    (with or without splitting the core into multiple files)
;;  + needs a defmodule macro
;;  + auto install packages
;;  + activate modules based on installed packages
;;  + packages/platforms/oses(distro-specific)/system-packages should
;;    be able to be depended on just like an emacs package in the above
;;    item
;;  + allow loading .org files or directories as modules

;;; Code:


(require 'f)
(require 's)
(require 'dash)
(require 'benchmark)

(defvar rig--loaded-modules nil)
(defvar rig-module-directory "~/.emacs.d/modules")
(defvar rig--module-options nil)

(add-to-list 'load-path rig-module-directory)

(defun rig-load-module (module &optional options)
  (interactive
   (list (intern (completing-read "Load module: "
				  (thread-last (f-glob "*" rig-module-directory)
				    (--filter (f-directory-p it))
				    (--map (f-filename it)))))))
  (rig--set-module-options module options)
  (--when-let (rig--locate-module module)
    (message "[rig] loaded module %s in %.2fs"
	     module
	     (benchmark-elapse
	       (load (expand-file-name it) nil t t))))
  (rig--load-mixins-for-module module))

(defun rig--set-module-options (module options)
  (push (cons module options) rig--module-options))

(defun rig--get-module-options (module)
  (cdr (assoc module rig--module-options)))

(defun rig--load-mixin (module mixin)
  (load (expand-file-name (rig--locate-mixin module mixin)) nil t t))

;; FIXME: this function has a terrible name
(defun rig--load-mixins-for-module (module)
  (mapcar
   (lambda (mixin)
     (when (member mixin rig--loaded-modules)
       (rig--load-mixin module mixin)))
   (rig--get-mixin-modules module)))
;; This file defines a standalone configuration loading system similar to
;; spacemacs' layers, but hopefully more modular.
;; This file defines a standalone configuration loading system similar to
;; spacemacs' layers, but hopefully more modular.

(defun rig--locate-module (module)
  (f-join rig-module-directory (format "%s/module.el" module)))

(defun rig--locate-mixin (module mixin)
  (f-join rig-module-directory (format "%s/mixin-%s.el" module mixin)))

(defun rig--get-mixin-modules (module)
  (--map
   (->> it

	(f-filename)
	(s-match "^mixin-\\(.*\\).el$")
	(nth 1)
	(intern))
   (f-glob "mixin-*.el" (f-join rig-module-directory (symbol-name module)))))

(defun rig--module-spec-name (module-spec)
  (cond
   ((listp module-spec) (car module-spec))
   ((symbolp module-spec) module-spec)))

(defun rig--module-spec-options (module-spec)
  (cond
   ((listp module-spec) (cdr module-spec))
   ((symbolp module-spec) nil)))

(cl-defmacro rig (&key name mail font theme modules)
  `(progn
     ;; set the user's personal details
     (setq user-full-name ,name)
     (setq user-mail-address ,mail)
     ;; set theme and font
     (let ((f ,font)
	   (th ,theme))
       (when f
	 (apply #'set-face-attribute 'default nil f))
       (when th
	 (load-theme th t)))
     ;; set the list of modules the user has chosen to load. we do
     ;; this all at once because if we didn't a mixin wouldn't get
     ;; loaded if it's target module comes after it's containing
     ;; module. 
     (setq rig--loaded-modules (--map (rig--module-spec-name it) ,modules))
     ;; load the modules
     ;; TODO: ensure that mixins are loaded after their target
     (rig--load-modules ,modules)))

(defun rig--load-modules (module-specs)
  (--each
      module-specs
    (rig-load-module (rig--module-spec-name it)
		     (rig--module-spec-options it))))

(defun rig-create-or-edit-module (name)
  (interactive (list
		(ivy-read "module: "
			  (-map #'f-filename
				(f-glob "*" rig-module-directory)))))
  (find-file (f-join rig-module-directory (format "%s/module.el" name)))
  ;; TODO: if we find an invocation of the `rig' macro in the user's
  ;; init file, add a newly created module to it
  )

;; (progn
;;   (defvar rig--modules nil)

;;   (cl-defmacro rig-defmodule (name)
;;     ))

(provide 'rig)
;;; rig.el ends here
