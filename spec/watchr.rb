# Run me with:
#   $ watchr watchr.rb

# --------------------------------------------------
# Rules
# --------------------------------------------------
watch('^spec.rb') {|m| rspec(tests) }
watch('^web.rb') {|m| rspec(tests) }
watch('spec/*_spec.rb') {|m| rspec(tests) }
watch('lib/*.rb') {|m| rspec(tests) }

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
  "spec/"
end

def run( cmd )
  # Clear the screen, useful for ConqueTerm which cannot scroll down indefinitely.
  print "\e[2J\e[f"
  puts   "[#{Time.now.strftime '%k:%M:%S'}] #{cmd}"
  system cmd
end
# vim:ft=ruby
