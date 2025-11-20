(import ../src/config)
(import ../src/cli)

(defn test-config-loading []
  (print "Testing config loading...")
  (def conf (config/load-config))
  (assert (= (type conf) :struct) "Config should be a struct")
  (print "Config loaded: " conf))

(defn test-cli-parsing []
  (print "\nTesting CLI parsing...")
  (def conf (config/load-config))
  
  # Test 1: Defaults
  (def args1 @["hello"])
  (def res1 (cli/parse-args args1 conf))
  (assert (= (res1 :text) "hello") "Text should be hello")
  (assert (= (res1 :source) "Korean") "Default source should be Korean")
  
  # Test 2: Overrides
  (def args2 @["--source" "English" "-t" "French" "world"])
  (def res2 (cli/parse-args args2 conf))
  (assert (= (res2 :source) "English") "Source should be English")
  (assert (= (res2 :target) "French") "Target should be French")
  
  (print "CLI parsing tests passed!"))

(defn test-config-exists []
  (print "\nTesting config-exists?...")
  (def exists (config/config-exists?))
  (assert (= (type exists) :boolean) "config-exists? should return boolean")
  (print "Config exists check passed! (exists: " exists ")"))

(defn test-init-flag []
  (print "\nTesting --init flag parsing...")
  (def conf (config/load-config))

  # Test 1: --init flag should be detected
  (def args1 @["--init"])
  (def res1 (cli/parse-args args1 conf))
  (assert (= (res1 :init) true) "--init flag should be detected")

  # Test 2: No --init flag
  (def args2 @["hello"])
  (def res2 (cli/parse-args args2 conf))
  (assert (= (res2 :init) false) "--init should be false by default")

  (print "Init flag tests passed!"))

(defn test-save-config []
  (print "\nTesting save-config function...")
  # Just verify the function exists and is callable
  # We won't actually save to avoid side effects in tests
  (assert (function? config/save-config) "save-config should be a function")
  (print "Save-config function exists!"))

(defn main [&]
  (test-config-loading)
  (test-cli-parsing)
  (test-config-exists)
  (test-init-flag)
  (test-save-config))
