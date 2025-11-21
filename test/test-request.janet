(import spork/test)
(import ../src/request)

# Start test suite
(test/start-suite)

# Note: parse-http-response function was removed as joyframework/http
# now handles response parsing automatically.

# Test: handle-http-error returns correct error types
# Note: handle-http-error prints to stderr, so we only check return values

(def error-401-result (request/handle-http-error 401 "{}"))
(test/assert
  (nil? error-401-result)
  "401 error should return nil (no retry)")

(def error-403-result (request/handle-http-error 403 "{}"))
(test/assert
  (nil? error-403-result)
  "403 error should return nil (no retry)")

(def error-429-result (request/handle-http-error 429 "{}"))
(test/assert
  (nil? error-429-result)
  "429 error should return nil (no retry)")

(def error-500-result (request/handle-http-error 500 "{}"))
(test/assert
  (= error-500-result :retry)
  "500 error should return :retry")

(def error-502-result (request/handle-http-error 502 "{}"))
(test/assert
  (= error-502-result :retry)
  "502 error should return :retry")

(def error-503-result (request/handle-http-error 503 "{}"))
(test/assert
  (= error-503-result :retry)
  "503 error should return :retry")

(def error-404-result (request/handle-http-error 404 "not found"))
(test/assert
  (nil? error-404-result)
  "404 error should return nil (no retry)")

# End test suite
(test/end-suite)
