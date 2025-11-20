(import spork/test)
(import ../src/request)

# Start test suite
(test/start-suite)

# Test: parse-http-response with valid response
(def valid-response "{\n\"status\": \"ok\"\n}\n200")
(def parsed-valid (request/parse-http-response valid-response))

(test/assert
  (not (nil? parsed-valid))
  "parse-http-response should parse valid response")

(test/assert
  (= (get parsed-valid :status-code) 200)
  "Should extract status code 200")

(test/assert
  (= (get parsed-valid :body) "{\n\"status\": \"ok\"\n}")
  "Should extract body correctly")

# Test: parse-http-response with different status codes
(def response-401 "{\"error\": \"unauthorized\"}\n401")
(def parsed-401 (request/parse-http-response response-401))

(test/assert
  (= (get parsed-401 :status-code) 401)
  "Should parse 401 status code")

(def response-429 "{\"error\": \"rate limit\"}\n429")
(def parsed-429 (request/parse-http-response response-429))

(test/assert
  (= (get parsed-429 :status-code) 429)
  "Should parse 429 status code")

(def response-500 "{\"error\": \"server error\"}\n500")
(def parsed-500 (request/parse-http-response response-500))

(test/assert
  (= (get parsed-500 :status-code) 500)
  "Should parse 500 status code")

# Test: parse-http-response with multiline body
(def multiline-response "line1\nline2\nline3\n200")
(def parsed-multiline (request/parse-http-response multiline-response))

(test/assert
  (= (get parsed-multiline :status-code) 200)
  "Should parse multiline response status code")

(test/assert
  (= (get parsed-multiline :body) "line1\nline2\nline3")
  "Should preserve newlines in body")

# Test: parse-http-response with invalid response (too short)
(def invalid-response "200")
(def parsed-invalid (request/parse-http-response invalid-response))

(test/assert
  (nil? parsed-invalid)
  "Should return nil for invalid response format")

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
