;;; autodisass-java-bytecode --- Automatically disassemble Java bytecode

;; Copyright (C) 2014, George Balatsouras
;;
;; Author: George Balatsouras <gbalats(at)gmail(dot)com>
;; Maintainer: George Balatsouras <gbalats(at)gmail(dot)com>
;; Created: 22 Jun 2014
;; Keywords: convenience, data, files
;;
;; This file is NOT part of Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2 of
;; the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be
;; useful, but WITHOUT ANY WARRANTY; without even the implied
;; warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
;; PURPOSE.  See the GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public
;; License along with this program; if not, write to the Free
;; Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
;; MA 02111-1307 USA
;;
;; To use, save `autodisass-java-bytecode.el' to a directory in your
;; load-path and add the following to your `.emacs'.
;;
;; (require 'autodisass-java-bytecode)


;;; Commentary:

;; This package enables automatic disassembly of Java bytecode.
;;
;; It was inspired by a blog post of Christopher Wellons:
;;    http://nullprogram.com/blog/2012/08/01/

;;
;; Disassembly can happen in two cases:
;; (a) when opening a Java .class file
;; (b) when disassembling a .class file inside a jar
;;
;; When `javap-mode' is available, it is automatically selected for the
;; current Java bytecode-containing buffer.
;;
;; In any case, `javap' must be installed in the system for this
;; extension to have any effect, since that is the tool that actually
;; performs the disassembly.

;;; Code:


(defconst autodisass-java-bytecode-version "0.1")

(defgroup autodisass-java-bytecode nil
  "Automatic disassembly of Java bytecode."
  :tag    "Java Bytecode Disassembly"
  :prefix "ad-java-bytecode-"
  :group  'autodisass)


(defconst ad-java-bytecode-regexp "\\.class$"
  "Regular expressions that matches Java bytecode files.")


(defcustom ad-java-bytecode-disassembler "javap"
  "Return the name of the disassembler command.
If the command is not on your path, you may specify a fully
qualified path to it.  The command should accept the input file
name as its last argument and print the disassembled file on the
output stream."
  :tag "Disassembler command"
  :group 'autodisass-java-bytecode
  :type 'string)


(defcustom ad-java-bytecode-parameters
  '("-private" "-verbose")
  "Extra parameters for the disassembler process."
  :tag "Command line options"
  :group 'autodisass-java-bytecode
  :type '(repeat string))


(defun ad-java-bytecode-disassemble-p (file)
  "Return t if automatic disassembly should be performed for FILE."
  (and (string-match ad-java-bytecode-regexp file)
       (executable-find ad-java-bytecode-disassembler)
       (y-or-n-p (format "Disassemble %s using %s? " file
                         ad-java-bytecode-disassembler))))


(defun ad-java-bytecode-class-name (class-file)
  "Return the corresponding CLASS-NAME of a CLASS-FILE."
  (replace-regexp-in-string
   "/" "." (file-name-sans-extension class-file)))


(defun ad-java-bytecode-buffer (class-file &optional jar-file)
  "Disassembles a Java CLASS-FILE inside the current buffer, using `javap'.
The JAR-FILE argument is non-nil if the disassembly is happening
inside a jar archive, during auto-extraction."
  (let ((class-name  (ad-java-bytecode-class-name class-file))
        (class-path  (or jar-file (file-name-directory class-file))))
    (message "Disassembling %s" class-file)
    ;; erase previous contents
    (erase-buffer)
    ;; disassemble .class file
    (apply 'call-process ad-java-bytecode-disassembler nil t nil
           (append ad-java-bytecode-parameters
                   (list "-classpath" class-path
                         (if jar-file class-name class-file))))
    ;; set some properties
    (setq buffer-read-only t)           ; mark as modified
    (set-buffer-modified-p nil)         ; mark as read-only
    (goto-char (point-min))             ; jump to top
    (when (fboundp 'javap-mode)         ; switch to `javap-mode'
      (javap-mode))
    (message "Disassembled %s" class-file)))


;; Add hook fora automatically disassembling .class files
(add-hook 'find-file-hook
          (lambda () (let ((class-file (buffer-file-name)))
                       (when (ad-java-bytecode-disassemble-p class-file)
                         (ad-java-bytecode-buffer class-file)))))

;; Add hook for automatically disassembling .class files inside jars
(add-hook 'archive-extract-hooks
          (lambda ()
            (let* ((components (split-string (buffer-file-name) ":"))
                   (jar-file   (car components))
                   (class-file (cadr components)))
              (when (ad-java-bytecode-disassemble-p class-file)
                (ad-java-bytecode-buffer class-file jar-file)))))


(provide 'autodisass-java-bytecode)

;;; autodisass-java-bytecode ends here
