# gem_bin_path.rb

Facter.add("gem_bin_path") do
  setcode do
    Facter::Util::Resolution.exec('ruby -r rubygems -e "puts Gem.path.collect{ |value| value + \'/bin\'}.join(\':\')"').chomp
  end
end