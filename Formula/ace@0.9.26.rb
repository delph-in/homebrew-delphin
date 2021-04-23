class AceAT0926 < Formula
  desc "Efficient processor for DELPH-IN HPSG grammars"
  homepage "http://sweaglesw.org/linguistics/ace/"
  url "http://sweaglesw.org/linguistics/ace/download/ace-0.9.26.tar.gz"
  sha256 "c082e3635f31c9bd8623f40443eb309fe63366e0f5eca292d35f60b668ba638a"

  depends_on "boost" => :build
  depends_on "delph-in/delphin/repp" => :build

  fails_with :clang

  def install
    # Prepare Makefile for macOS
    inreplace "Makefile", "#include MacOSX.config", "include MacOSX.config"
    cd "post" do
      inreplace "Makefile", "#include ../MacOSX.config", "include ../MacOSX.config"
    end

    # Clean up Makefile
    inreplace "Makefile", "-Wl,-soname", "-Wl,-install_name"

    # Clean up MacOSX.config for gcc
    inreplace "MacOSX.config" do |s|
      s.gsub! "CFLAGS+=-fnested-functions", "CFLAGS+="
      s.gsub! "-lstdc++", "-lc++"
      # support nonstandard install locations
      s.gsub! "REPP_LIBS=/usr/local", "REPP_LIBS=#{HOMEBREW_PREFIX}"
      s.gsub! "BOOST_REGEX_LIBS=/usr/local", "BOOST_REGEX_LIBS=#{HOMEBREW_PREFIX}"
    end

    # Small code changes (for gcc?)
    inreplace "type.c", "int		glb_type_count;", "//int		glb_type_count;"

    # Build
    system "make", "ace"
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

    qc = "QC_SIZE(8)
 REC(5)
 PUSH(SYNSEM) PUSH(LOCAL) PUSH(CONT) PUSH(HOOK) PUSH(INDEX) REC(7) POP POP POP
         PUSH(CAT) PUSH(HEAD) REC(0)
                 PUSH(MOD) REC(1) POP
                 PUSH(FORM) REC(3) POP POP
             PUSH(VAL) PUSH(SUBJ) REC(6) POP
                 PUSH(SPR) REC(4) POP
                 PUSH(COMPS) REC(2)
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
    assert_match shell_output("echo \"n1 iv\" | #{bin}/ace -g #{testpath}/grammar.dat").strip,
    "SENT: n1 iv\n[ LTOP: h0 INDEX: event2 RELS: < [ \"_n1_n_rel\"<-1:-1> LBL: handle3 ARG0: ref-ind4 ]  [ \"_iv_v_rel\"<-1:-1> LBL: handle1 ARG0: event2 ARG1: ref-ind5 ] > HCONS: < h0 qeq handle1 > ] ;  (8 subj-head 0.000000 0 2 (3 n1 0.000000 0 1 (\"n1\")) (4 iv 0.000000 1 2 (\"iv\")))".strip
  end
end
