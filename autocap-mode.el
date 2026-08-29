;;; autocap-mode.el --- Insert capital letters -*- lexical-binding: t; -*-

;; Copyright (C) 2026  Jeff Spaulding

;; Author: Jeff Spaulding <sarnet@gmail.com>
;; Keywords: text

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This minor mode automatically capitalizes letters as they're inserted into
;; the buffer.

;; Caps-lock, as it works on American keyboards anyway, capitalizes letters
;; during input.  This includes any keyboard commands you send, which is
;; usually not the user's intention and can have catastrophic consequences.

;; The motivating use case is working with old code such as fixed-format
;; FORTRAN or old Lisp systems, but it can also be used for writing angry
;; letters.

;; By default, strings and comments are not capitalized.  You can modify this
;; by changing the value of `autocap-mode-excluded-faces'.

;; You must have font-lock-mode active in the buffer to use this, as it
;; bases the decision on whether or not to capitalize a letter on its
;; :face property.

;; Note that I'm American and only speak English, so corner cases from other
;; languages might cause strange behavior.

;;; Code:

(require 'font-lock)

(define-minor-mode autocap-mode
  "Minor mode to capitalize letters as they're being typed.

Capitalization is controlled by the current font-lock-face, so font-lock-mode
is required for this mode to function.  By default, strings and comments
are not automatically capitalized.  Use `autocap-mode-excluded-faces' to
adjust this.

If ARG is NIL or omitted, toggle autocap-mode.  If ARG is negative, disable
autocap-mode.  Otherwise, enable autocap-mode."
  :global nil
  :init-value nil
  :lighter " ACAP"
  :group 'text
  (unless (advice-member-p #'autocap-mode--sic-advice 'self-insert-command)
    (advice-add 'self-insert-command :around #'autocap-mode--sic-advice))
  (when (and autocap-mode (not font-lock-mode))
    (message "autocap-mode only works when font-lock-mode is enabled.")))

(defcustom autocap-mode-excluded-faces
  '(font-lock-comment-face font-lock-string-face)
  "If we are currently in one of these faces, do not autocapitalize."
  :group 'text
  :type '(repeat face)
  :local t)

(defun autocap-mode--point ()
  "Return point, or if at the end of a buffer return point -1."
  (let ((p (point)))
    (if (and (= p (buffer-end 1))
             (> p 1))
        (1- p)
      p)))

(defun autocap-mode--sic-advice (fun N &optional C)
  "Advising function for `self-insert-command' that capitalizes as you type.

N and C hold their meaning under `self-insert-command', but C is capitalized
if the conditions are met.  FUN is `self-insert-command' itself."
  (when (and autocap-mode
             font-lock-mode
             C
             (not (memq (get-text-property (autocap-mode--point) 'face)
                        autocap-mode-excluded-faces)))
    (setq C (upcase C)))
  (apply fun (list N C)))

(provide 'autocap-mode)
;;; autocap-mode.el ends here
