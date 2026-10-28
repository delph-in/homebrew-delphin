class Repp < Formula
  desc "Prepare text for 'deep' parsing using DELPH-IN grammars"
  homepage "https://github.com/delph-in/docs/wiki/ReppTop"
  url "https://sweaglesw.org/linguistics/repp-0.2.2.tar.gz"
  sha256 "1b805ac7bc3a338f61e41f3cc651e9711e64f3ac86da606c262cee014055b721"
  revision 1

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "gcc" => :build
  depends_on "libtool" => :build
  depends_on "boost"

  fails_with :clang

  def install
    # Boost >= 1.8x includes <boost/assert.hpp> from boost/regex/config.hpp
    # even in C builds, which breaks <boost/regex.h>.
    (buildpath/"compat/boost/assert.hpp").write <<~EOS
      #ifdef __cplusplus
      #include_next <boost/assert.hpp>
      #else
      #include <assert.h>
      #define BOOST_ASSERT(x) assert(x)
      #endif
    EOS
    ENV.prepend "CPPFLAGS", "-I#{buildpath}/compat"

    # the bundled 2009 libtool links with -flat_namespace on macOS >= 11
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make"
    system "make", "install"
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
