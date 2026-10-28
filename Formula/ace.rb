class Ace < Formula
  desc "Efficient processor for DELPH-IN HPSG grammars"
  homepage "https://sweaglesw.org/linguistics/ace/"

  # The 0.9.34 release tarball (2021) predates trunk fixes for Apple Silicon
  # (e.g. FREEZER_MMAP_BASE moved to 0x7000000000 in r1096), so build a pinned
  # trunk revision instead. SVN is only served over plain HTTP, so this is a
  # checksummed export of r1097 (identical to delph-in/ace commit 31afda8).
  stable do
    url "https://github.com/delph-in/homebrew-delphin/releases/download/ace-0.9.34-r1097/ace-0.9.34-r1097.tar.gz"
    version "0.9.34-r1097"
    sha256 "3a723496ad05a0d85a4237c65b258b69aa5f5343301ec6b526766dcea66249f7"

    # walk_dg() varargs were terminated with int 0 instead of NULL; on Apple
    # arm64 this crashes when loading grammars with transfer/trigger rules.
    # https://github.com/delph-in/ace/pull/1
    patch :DATA
  end

  head do
    url "http://sweaglesw.org/svn/ace/trunk", using: :svn
    depends_on "subversion" => :build
  end

  depends_on "boost" => :build
  depends_on "delph-in/delphin/repp" => :build
  depends_on "gcc" => :build

  # qcparse.c still uses GCC nested functions
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

    # Modern GCC rejects some legacy C (implicit int, implicit declarations);
    # downgrade only those errors back to warnings.
    File.write "MacOSX.config", <<~EOS
      CFLAGS+=-std=gnu17 -Wno-error=implicit-int -Wno-error=implicit-function-declaration -Wno-error=incompatible-pointer-types -I#{buildpath}/compat -DMACOSX_GCC -isystem #{HOMEBREW_PREFIX}/include
      POST_LIBS=-lutil
      REPP_LIBS=#{formula_opt_lib("delph-in/delphin/repp")}/librepp.a
      BOOST_REGEX_LIBS=#{formula_opt_lib("boost")}/libboost_regex.a -lc++
      DELPHIN_CFLAGS=
      DELPHIN_LIBS=
      EXPORT_DYNAMIC_CFLAG=
    EOS
    inreplace "Makefile", "#include MacOSX.config", "include MacOSX.config"

    system "make", "ace", "CC=#{ENV.cc}"
    bin.install "ace"
  end

  test do
    # Load and parse from delphin-tiniest-grammar
    # see github.com/dantiston/delphin-tiniest-grammar
    # Config
    config = "grammar-top               := definition.tdl.
preprocessor              := vanilla.rpp.
quickcheck-code           := qc.tdl.

orth-path                 := STEM.
semantics-path            := SYNSEM LOCAL CONT.
lex-rels-path             := SYNSEM LOCAL CONT RELS.
lex-carg-path             := SYNSEM LKEYS KEYREL CARG.
lex-pred-path             := SYNSEM LKEYS KEYREL PRED.
rule-rels-path            := C-CONT RELS.
label-path                := LABEL-NAME.

parsing-roots             := root.
generation-roots          := root.

semarg-type               := semarg.
handle-type               := h.
list-type                 := list.
cons-type                 := cons.
null-type                 := null.
diff-list-type            := diff-list.

mrs-deleted-roles :=
  IDIOMP LNK CFROM CTO --PSV WLINK PARAMS.
"

    # Grammar Definition
    definition = ":begin :type.
:include \"core\".
:end :type.

:begin :instance :status lex-entry.
:include \"lexicon\".
:end :instance.

:begin :instance :status rule.
:include \"rules\".
:end :instance.

:begin :instance.
:include \"roots\".
:end :instance.
"

    # Core types
    core = "sign := avm &
  [ SYNSEM synsem,
    ARGS list,
    STEM list ].

predsort := *top*.
atom := predsort.
named_rel := predsort.

avm := *top*.

list := avm.

cons := list &
  [ FIRST *top*,
    REST list ].

null := list.

diff-list := avm &
  [ LIST list,
    LAST list ].

string := atom.

phrase-or-lexrule := sign &
  [ SYNSEM synsem &
    [ LOCAL.CONT.HOOK #hook ],
    C-CONT mrs & [ HOOK #hook] ].

word-or-lexrule := sign &
  [ ARG-ST list ].

phrase := phrase-or-lexrule.
lex-item := word-or-lexrule.

rule := sign &
  [ RULE-NAME string ].
tree-node-label := *top* &
  [ NODE sign ].
label := sign &
  [ LABEL-NAME string ].
meta := sign &
  [ META-PREFIX string,
    META-SUFFIX string ].

synsem := avm &
  [ LOCAL local ].
lex-synsem := synsem &
  [ LKEYS lexkeys ].

local := avm &
  [ CAT cat,
    CONT mrs ].

lexkeys := avm &
  [ KEYREL relation,
    ALTKEYREL relation ].

cat := avm &
  [ HEAD head,
    VAL valence ].

head := avm.
verb-or-noun := head.
verb := verb-or-noun.
noun := verb-or-noun.

valence := avm &
  [ SUBJ list,
    SPR list ].

mrs := avm &
  [ HOOK hook,
    RELS diff-list,
    HCONS diff-list ].

hook := avm &
  [ LTOP handle,
    INDEX individual,
    CLAUSE-KEY event ].

qeq := avm &
  [ HARG handle,
    LARG handle ].

semarg := avm &
  [ INSTLOC string ].

handle := semarg.
individual := semarg.
index := individual.
event-or-ref-index := individual.
ref-ind := index & event-or-ref-index.
event := event-or-ref-index.

relation := avm &
  [ LBL handle,
    WLINK list,
    PRED predsort ].

arg0-relation := relation &
  [ ARG0 individual ].

arg1-relation := arg0-relation &
  [ ARG1 semarg ].

event-relation := arg0-relation &
  [ ARG0 event ].

arg1-ev-relation := arg1-relation & event-relation.

noun-relation := arg0-relation &
  [ ARG0 ref-ind ].

noun-arg1-relation := noun-relation & arg1-relation.

named-relation := noun-relation &
  [ PRED named_rel,
    CARG string ].

quant-relation := arg0-relation &
  [ ARG0 ref-ind,
    RSTR handle,
    BODY handle ].

headed-phrase := phrase &
  [ SYNSEM.LOCAL.CAT.HEAD #head,
    HEAD-DTR.SYNSEM.LOCAL.CAT.HEAD #head ].

binary-phrase := phrase &
  [ SYNSEM.LOCAL.CONT [ RELS [ LIST #first,
                               LAST #last ],
                        HCONS [ LIST #scfirst,
                                LAST #sclast ] ],
    C-CONT [ RELS [ LIST #middle2,
                    LAST #last ],
             HCONS [ LIST #scmiddle2,
                     LAST #sclast ] ],
    ARGS < [ SYNSEM.LOCAL.CONT [ RELS [ LIST #first,
                                        LAST #middle1 ],
                                 HCONS [ LIST #scfirst,
                                         LAST #scmiddle1 ] ] ],
           [ SYNSEM.LOCAL.CONT [ RELS [ LIST #middle1,
                                        LAST #middle2 ],
                                 HCONS [ LIST #scmiddle1,
                                         LAST #scmiddle2 ] ] ] > ].

binary-headed-phrase := headed-phrase & binary-phrase &
  [ NON-HEAD-DTR sign ].

head-final := binary-headed-phrase &
  [ HEAD-DTR #head,
    NON-HEAD-DTR #non-head,
    ARGS < #non-head, #head > ].

head-compositional := headed-phrase &
  [ C-CONT.HOOK #hook,
    HEAD-DTR.SYNSEM.LOCAL.CONT.HOOK #hook ].

norm-lex-item := lex-item &
  [ SYNSEM [ LOCAL.CONT [ HOOK [ LTOP #ltop,
                                 INDEX #index, ],
                          RELS <! #keyrel & relation !>,
                          HCONS <! !> ],
             LKEYS.KEYREL #keyrel & [ LBL #ltop,
                                      ARG0 #index ] ],
    ARG-ST < synsem > ].

subj-head-phrase := head-compositional & binary-headed-phrase & head-final &
  [ SYNSEM [ LOCAL.CAT.VAL [ SUBJ < >,
                             SPR < > ] ],
             HEAD-DTR.SYNSEM.LOCAL.CAT.VAL [ SUBJ < #synsem >,
                                             SPR < > ],
             NON-HEAD-DTR.SYNSEM #synsem &
               [ LOCAL.CAT.VAL [ SUBJ < >,
                                 SPR < > ] ],
             C-CONT [ RELS <! !>, HCONS <! !> ] ].

intransitive-verb-lex := norm-lex-item &
  [ ARG-ST < [ LOCAL [ CAT.HEAD verb,
                       CONT.HOOK.INDEX ref-ind & #ind ] ] >,
    SYNSEM.LKEYS.KEYREL event-relation & [ ARG1 #ind ] ].

noun-lex := norm-lex-item &
  [ SYNSEM [ LOCAL.CAT [ HEAD noun,
                         VAL.SUBJ < > ],
             LKEYS.KEYREL noun-relation ] ].
"

    roots = "root := sign &
  [ SYNSEM.LOCAL.CAT [ VAL.SUBJ < >,
                       HEAD verb ] ].
"

    rules = "subj-head := subj-head-phrase."

    lexicon = "n1 := noun-lex &
  [ STEM < \"n1\" >,
    SYNSEM.LKEYS.KEYREL.PRED \"_n1_n_rel\" ].

iv := intransitive-verb-lex &
  [ STEM < \"iv\" >,
    SYNSEM.LKEYS.KEYREL.PRED \"_iv_v_rel\" ].
"

    # only paths through features the grammar above declares; newer ACE
    # rejects quickcheck paths with unknown features such as MOD or COMPS
    qc = "QC_SIZE(4)
 REC(3)
 PUSH(SYNSEM) PUSH(LOCAL) PUSH(CONT) PUSH(HOOK) PUSH(INDEX) REC(2) POP POP POP
         PUSH(CAT) PUSH(HEAD) REC(0) POP
             PUSH(VAL) PUSH(SUBJ) REC(1) POP
"

    repp = <<~EOS
      : +
      !^(.+)$								 \\1\s
    EOS

    (testpath/"config.tdl").write config
    (testpath/"definition.tdl").write definition
    (testpath/"core.tdl").write core
    (testpath/"roots.tdl").write roots
    (testpath/"rules.tdl").write rules
    (testpath/"lexicon.tdl").write lexicon
    (testpath/"qc.tdl").write qc
    (testpath/"vanilla.rpp").write repp

    system bin/"ace", "-g", "config.tdl", "-G", testpath/"grammar.dat"
    expected = "SENT: n1 iv\n" \
               "[ LTOP: h0 INDEX: event2 RELS: < " \
               "[ \"_n1_n_rel\"<-1:-1> LBL: handle3 ARG0: ref-ind4 ]  " \
               "[ \"_iv_v_rel\"<-1:-1> LBL: handle1 ARG0: event2 ARG1: ref-ind5 ] > " \
               "HCONS: < h0 qeq handle1 > ] ;  " \
               "(8 subj-head 0.000000 0 2 (3 n1 0.000000 0 1 (\"n1\")) (4 iv 0.000000 1 2 (\"iv\")))"
    output = shell_output("echo \"n1 iv\" | #{bin}/ace -g #{testpath}/grammar.dat")
    assert_equal expected, output.lines.first(2).join.strip
  end
end

__END__
diff --git a/transfer.c b/transfer.c
index ec0d30a..0627e5b 100644
--- a/transfer.c
+++ b/transfer.c
@@ -245,7 +245,7 @@ void	process_saved_tcopy(struct transfer_rule	*r, struct tcopy	*c)
 void warn_about_equals(struct transfer_rule	*tr)
 {
 	static int	eqpath[5]={-1};
-	struct dg	*eql = walk_dg(tr->dg, eqpath, "FLAGS", "EQUAL", 0);
+	struct dg	*eql = walk_dg(tr->dg, eqpath, "FLAGS", "EQUAL", NULL);
 	while(eql && dg_hop(eql, 1))
 	{
 		struct dg	*eq = dg_hop(eql, 1);
@@ -263,7 +263,7 @@ struct transfer_rule	*dg_to_transfer_rule(char	*name, struct dg	*dg, struct dg	*
 	struct transfer_rule	*tr = calloc(sizeof(struct transfer_rule), 1);
 	tr->name = strdup(name);
 	static int flagspath[5] = {-1,-1};
-	struct dg	*optdg = walk_dg(dg, flagspath, "FLAGS", "OPTIONAL", 0);
+	struct dg	*optdg = walk_dg(dg, flagspath, "FLAGS", "OPTIONAL", NULL);
 	tr->optional = optdg?(!strcmp(optdg->xtype->name, "+")):0;
 	tr->dg = dg;
 	tr->output_override = output_override;
@@ -458,8 +458,8 @@ int	freeze_transfer_rule_more(struct transfer_rule	*tr)
 	bzero(tr->ss, sizeof(struct dg*)*10);
 	tr->neq = tr->nss = 0;
 	static int	eqpath[5]={-1}, sspath[5]={-1};
-	struct dg	*eql = walk_dg(tr->dg, eqpath, "FLAGS", "EQUAL", 0);
-	struct dg	*ssl = walk_dg(tr->dg, sspath, "FLAGS", "SUBSUME", 0);
+	struct dg	*eql = walk_dg(tr->dg, eqpath, "FLAGS", "EQUAL", NULL);
+	struct dg	*ssl = walk_dg(tr->dg, sspath, "FLAGS", "SUBSUME", NULL);
 	//printf("eql = \n");
 	//print_dg(eql); printf("\n");
 	while(eql && dg_hop(eql, 1))
