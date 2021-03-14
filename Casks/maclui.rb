cask "maclui" do
  version "0.1"
  sha256 "63cf8fe47e7ac771b42bc56d3de8430617dae8713101b787418afc9ead9518a5"

  url "http://sweaglesw.org/linguistics/maclui/maclui.app.tar.gz"
  name "MacLui"
  desc "Linguistic User Interface for visualizing and interacting with DELPH-IN HPSG parse trees, MRS, and AVMs via ACE or the LKB"
  homepage "http://sweaglesw.org/linguistics/maclui/README.txt"

  app "MacLui.app"

  # shim script (https://github.com/Homebrew/homebrew-cask/issues/18809)
  shimscript = "#{staged_path}/yzlui"
  binary shimscript, target: "yzlui"

  preflight do
    print shimscript
    File.open(shimscript, 'w') do |f|
      f.puts '#!/bin/bash'
      f.puts "exec #{appdir}/maclui.app/Contents/MacOS/maclui -p"
      FileUtils.chmod '+x', f
    end
  end

  auto_updates false

  zap trash: [
    shimscript,
  ]
end
