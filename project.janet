(declare-project
  :name "tsl-janet"
  :description "A CLI tool for text translation using Groq API with Janet language"
  :author "tsl-janet contributors"
  :license "MIT"
  :url "https://github.com/yourusername/tsl-janet"
  :repo "git+https://github.com/yourusername/tsl-janet.git"
  :dependencies ["https://github.com/janet-lang/spork.git"])

(declare-executable
  :name "tsl"
  :entry "src/main.janet"
  :install-path "build")

# Declare the main translation CLI as an executable
(declare-binscript
  :main "src/main.janet"
  :is-janet true)
