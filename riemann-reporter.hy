(import subprocess bernhard time sys socket)

(defclass Command [object]
  (defn __init__ [self service executable args]
    (setv self.service service)
    (setv self.executable executable)
    (setv self.args args))

  (defn run-cmd [self]
    (setv retval 0)
    (setv result "")
    (try
      (setv result (subprocess.check_output
                     (+ [self.executable] self.args)
                     :stderr subprocess.STDOUT))
      (except [e subprocess.CalledProcessError]
        (setv retval e.returncode)
        (setv result (.decode e.output "utf-8"))))
    #(retval result)))

(defclass RiemannReporter [object]
  (defn __init__ [self host port]
    (setv self.commands [])
    (setv self.riemann (.Client bernhard :host host :port port)))

  (defn add-command [self command]
    (.append self.commands command))

  (defn send-reports [self]
    (for [command self.commands]
      (setv [returncode output] (.run-cmd command))

      (if (= returncode 0)
          (setv state "normal")
          (setv state "critical"))

      (setv MAXLEN 255)

      (try
        (.send self.riemann {"host" (socket.gethostname) "service" command.service "state" state "description" (cut output 0 MAXLEN) })
        (except [e Exception]
          (print e))))))

(defmacro loop [#* body]
  `(while 1
     (do ~@body)))

(defmacro periodically [seconds #* body]
  `(loop
     (do ~@body
         (time.sleep ~seconds))))

(defmacro mainloop [#* body]
  `(try
     (do ~@body)
     (except [e KeyboardInterrupt]
       (print "Exiting ..."))))

(defn parse-parameters []
  (import argparse)
  (setv parser (argparse.ArgumentParser))
  (.add-argument parser "host")
  (.add-argument parser "port")
  (.add-argument parser "--config" :help "Config file" :required True)
  (parser.parse_args))

(defn read-commands-from-config [riemann-reporter config-path]
  (import yaml)
  (with [yaml-file (open config-path :newline "")]
    (setv config (yaml.safe-load yaml-file))
    (for [item config]
      (setv service (get item "name") executable (get item "executable") args (get item "args"))
      (setv command (Command service executable args))
      (.add-command riemann-reporter command))))

(mainloop (setv args (parse-parameters))
          (setv riemann-reporter (RiemannReporter args.host args.port))
          (read-commands-from-config riemann-reporter args.config)

          (periodically 60 (.send-reports riemann-reporter)))
