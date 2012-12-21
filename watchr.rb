# Run me with:
#   $ watchr watchr.rb

# --------------------------------------------------
# Rules
# --------------------------------------------------
watch('^spec.rb') {|m| rspec(tests) }
watch('^web.rb') {|m| rspec(tests) }

# --------------------------------------------------
# Signal Handling
# --------------------------------------------------
Signal.trap('QUIT') { rspec(tests) } # Ctrl-\
Signal.trap('INT' ) { abort("\n") } # Ctrl-C

# --------------------------------------------------
# Helpers
# --------------------------------------------------
def rspec(*paths)
  run "rspec -fd #{paths.flatten.join(' ')}"
end

def tests
  "spec.rb"
end

def run( cmd )
  puts   "[#{Time.now.strftime '%k:%M:%S'}] #{cmd}"
  system cmd
end
# vim:ft=ruby
