cask "maclui" do
  version "0.9"
  sha256 :no_check

  url "http://sweaglesw.org/linguistics/maclui/maclui.app.tar.gz"
  name "MacLui"
  desc "Linguistic User Interface for visualizing DELPH-IN grammars via ACE or the LKB"
  homepage "http://sweaglesw.org/linguistics/maclui/README.txt"

  # shim script (https://github.com/Homebrew/homebrew-cask/issues/18809)
  shimscript = "#{staged_path}/yzlui"
  app "MacLui.app"
  binary shimscript, target: "yzlui"

  preflight do
    File.open(shimscript, "w") do |f|
      f.puts "#!/bin/bash"
      f.puts "exec #{appdir}/maclui.app/Contents/MacOS/maclui -p"
      FileUtils.chmod "+x", f
    end
  end

  zap trash: [
    shimscript,
  ]
end
