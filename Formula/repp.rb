class Repp < Formula
  desc "Prepare text for 'deep' parsing using DELPH-IN grammars"
  homepage "http://moin.delph-in.net/ReppTop"
  url "http://sweaglesw.org/linguistics/repp-0.2.2.tar.gz"
  sha256 "1b805ac7bc3a338f61e41f3cc651e9711e64f3ac86da606c262cee014055b721"

  bottle do
    rebuild 1
    sha256 cellar: :any, big_sur: "f9acf24f7ea741a826a576dbe9ab6d809e9e76018a08e1e3ed3ccb53667ae13b"
  end

  depends_on "automake" => :build
  depends_on "boost" => :build
  depends_on "gcc" => :build

  fails_with :clang

  def install
    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make"
    system "make", "install"
    bin.install "repp/repp", "repp/.libs"
  end

  test do
    (testpath/"test.rpp").write <<~EOS
      : +
      !^(.+)$								 \\1#{" "}
      !([^ ])(n't) 						\\1 \\2#{" "}
    EOS
    assert_equal "do n't", shell_output("echo \"don't\" | #{bin}/repp test.rpp").strip
  end
end
