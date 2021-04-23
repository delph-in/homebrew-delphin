class Pydelphin < Formula
  include Language::Python::Virtualenv

  desc "Python libraries for DELPH-IN"
  homepage "https://github.com/delph-in/pydelphin"
  url "https://github.com/delph-in/pydelphin/archive/v1.5.1.tar.gz"
  sha256 "0fda880ecbb2f321ab6227945503d2268623347b224ca3ab061762dea1b43f82"
  revision 2

  depends_on "delph-in/delphin/ace"
  depends_on "python"

  resource "Penman" do
    url "https://files.pythonhosted.org/packages/a2/3d/50a8b1c7d6632fa793b406485d9ed0afa8683442d0aa83462c0ab7b67560/Penman-0.9.1.tar.gz"
    sha256 "ec1b0071948563d59004e11bd5c0e4696b4ceba95bf946367a4ba2b99bcd4f42"
  end

  resource "progress" do
    url "https://files.pythonhosted.org/packages/38/ef/2e887b3d2b248916fc2121889ce68af8a16aaddbe82f9ae6533c24ff0d2b/progress-1.5.tar.gz"
    sha256 "69ecedd1d1bbe71bf6313d88d1e6c4d2957b7f1d4f71312c211257f7dae64372"
  end

  def install
    virtualenv_install_with_resources
    bin.install_symlink libexec/"bin/delphin"
  end

  test do
    resource "tiniest-grammar" do
      url "https://github.com/dantiston/delphin-tiniest-grammar/archive/v1.0.0.tar.gz"
      sha256 "d24542f56fc5dbb63ba761f3bc292c5e01178e9dbefa024bc00ba9a04cbc210b"
    end

    testpath.install resource("tiniest-grammar")
    # Write TSDB info
    (testpath/"sentences.txt").write <<~EOS
      i-wf@i-input@i-author
      1@n1 iv@author
      2@iv n1@author
    EOS

    (testpath/"relations.txt").write <<~EOS
      item:
        i-input :string
        i-wf :integer
        i-author :string

      run:
        run-id :integer :key

      parse:
        parse-id :integer :key
        run-id :integer :key
        i-id :integer :key
    EOS

    # Make the profile
    system bin/"delphin", "mkprof", testpath/"tests", "--delimiter=\"@\"", "--relations", "relations.txt", "--input",
"sentences.txt"
    assert_predicate testpath/"tests"/"item", :exist?

    # Compile the grammar & process profile
    system Formula["delph-in/delphin/ace"].bin/"ace", "-g", "config.tdl", "-G", testpath/"grammar.dat"
    system bin/"delphin", "process", "-g", testpath/"grammar.dat", testpath/"tests"

    assert_predicate testpath/"tests"/"run", :exist?
    assert_predicate testpath/"tests"/"parse", :exist?
  end
end
