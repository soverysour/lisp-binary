(defun determine-load-order (components &optional load-order)
  "Given the COMPONENTS (which is just the :components section of the ASDF
def above), determine the order in which to load things so that dependencies
are always satisfied."
  (cond ((null components)
	 (reverse load-order))
	(t
	 (destructuring-bind (&key file depends-on) (car components)
	   (if (every (lambda (dep)
			(member dep load-order :test #'string=))
		      depends-on)
	       (determine-load-order (cdr components)
				     (cons file load-order))
	       (determine-load-order (append (cdr components)
					     (list (car components)))
				     load-order))))))

(defun load-system-def (pathname)
  (with-open-file (in pathname)
    (read in)))

(defun components (system-def)
  (getf system-def :components))

(defun dirname (pathname)
  (let ((directory (pathname-directory pathname))
	(name (pathname-name pathname)))
    (unless name
      (setf directory (butlast directory)))
  (let ((dirname (make-pathname :host (pathname-host pathname)
				:device (pathname-device pathname)
				:directory directory)))
    (if (equalp dirname #P"")
	pathname
	dirname))))

(defun fake-asdf-load (asd-pathname)
  "Load a system from a .asd file without ASDF."
  (let ((system-def (load-system-def asd-pathname)))
    (ql:quickload (getf system-def :depends-on))
    (let ((*default-pathname-defaults* (dirname asd-pathname)))
      (loop for file in (determine-load-order (components system-def))
	 do (load file)))))
