(import subprocess bernhard time sys)

(defclass Command [object]
  (defn --init-- [self service executable args]
    (setv self.service service)
    (setv self.executable executable)
    (setv self.args args))

  (defn run_cmd_retval [self]
    (setv retval 0)
    (try
      (setv result (subprocess.check_output
                     (list* self.executable self.args)
                     :stderr subprocess.STDOUT))

      (except [e subprocess.CalledProcessError]
        (setv retval e.returncode)))

    retval)

  (defn run_cmd [self]
    (setv retval (.run_cmd_retval self))
    (cond [(= retval 0) True]
          [True False]))

  (defn send_state [self] 0))

(defclass RiemannReporter [object]
  (defn --init-- [self host port]
    (setv self.commands [])
    (setv self.riemann (.Client bernhard :host host :port port)))

  (defn add-command [self command]
    (.append self.commands command))

  (defn send-reports [self]
    (for [command self.commands]
      (if (.run_cmd command)
          (setv state "normal")
          (setv state "critical"))

      (.send self.riemann {"host" "localhost" "service" command.service "state" state}))))

(defmacro loop [&rest body]
  `(while 1
     (do ~@body)))

(defmacro periodically [seconds &rest body]
  `(loop
     (do ~@body
         (time.sleep ~seconds))))

(defmacro mainloop [&rest body]
  `(try
     (do ~@body)
     (except [e KeyboardInterrupt]
       (print "Exiting ..."))))

(defn parse-parameters()
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
