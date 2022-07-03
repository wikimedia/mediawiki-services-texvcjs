/** PEGjs lexer/parser */
{
  var ast = require('./ast');
  var tu = require('./texutil');
  var assert = require('assert');

  var lst2arr = function(l) {
    var arr = [];
    while (l !== null) {
      arr.push(l.head);
      l = l.tail;
    }
    return arr;
  };
}
// first rule is the start production.
start
  = _ t:tex_expr
    { assert.ok(t instanceof ast.LList); return t.toArray(); }

// the PEG grammar doesn't automatically ignore whitespace when tokenizing.
// so we add `_` productions in appropriate places to eat whitespace.
// Lexer rules (which are capitalized) are expected to always eat
// *trailing* whitespace.  Leading whitespace is taken care of in the `start`
// rule above.
_
  = [ \t\n\r]*

/////////////////////////////////////////////////////////////
// PARSER
//----------------------------------------------------------

tex_expr
  = e:expr EOF
    { return e; }
  / e1:ne_expr name:FUN_INFIX e2:ne_expr EOF
    { return ast.LList(ast.Tex.INFIX(name, e1.toArray(), e2.toArray())); }
  / e1:ne_expr f:FUN_INFIXh e2:ne_expr EOF
    { return ast.LList(ast.Tex.INFIXh(f[0], f[1], e1.toArray(), e2.toArray()));}

expr
  = ne_expr
  / ""
    { return ast.LList.EMPTY; }

ne_expr
  = h:lit_aq t:expr
    { return ast.LList(h, t); }
  / h:litsq_aq t:expr
    { return ast.LList(h, t); }
  / d:DECLh e:expr
    { return ast.LList(ast.Tex.DECLh(d[0], d[1], e.toArray())); }
litsq_aq
  = litsq_fq
  / litsq_dq
  / litsq_uq
  / litsq_zq
litsq_fq
  = l1:litsq_dq SUP l2:lit
    { return ast.Tex.FQ(l1[0], l1[1], l2); }
  / l1:litsq_uq SUB l2:lit
    { return ast.Tex.FQ(l1[0], l2, l1[1]); }
litsq_uq
  = base:litsq_zq SUP upi:lit
    { return ast.Tex.UQ(base, upi); }
litsq_dq
  = base:litsq_zq SUB downi:lit
    { return ast.Tex.DQ(base, downi); }
litsq_zq
  = SQ_CLOSE
    { return ast.Tex.LITERAL(ast.RenderT.TEX_ONLY( "]")); }
expr_nosqc
  = l:lit_aq e:expr_nosqc
    { return ast.LList(l, e); }
  / "" /* */
    { return ast.LList.EMPTY; }
lit_aq
  = lit_fq
  / lit_dq
  / lit_uq
  / lit_dqn
  / lit_uqn
  / lit

lit_fq
  = l1:lit_dq SUP l2:lit
    { return ast.Tex.FQ(l1[0], l1[1], l2); }
  / l1:lit_uq SUB l2:lit
    { return ast.Tex.FQ(l1[0], l2, l1[1]); }
  / l1:lit_dqn SUP l2:lit
    { return ast.Tex.FQN(l1[0], l2); }

lit_uq
  = base:lit SUP upi:lit
    { return ast.Tex.UQ(base, upi); }
lit_dq
  = base:lit SUB downi:lit
    { return ast.Tex.DQ(base, downi); }
lit_uqn
  = SUP l:lit
    { return ast.Tex.UQN(l); }
lit_dqn
  = SUB l:lit
    { return ast.Tex.DQN(l); }


left
  = LEFT d:DELIMITER
    { return d; }
  / LEFT SQ_CLOSE
    { return ast.RenderT.TEX_ONLY( "]"); }
right
  = RIGHT d:DELIMITER
    { return d; }
  / RIGHT SQ_CLOSE
    { return ast.RenderT.TEX_ONLY( "]"); }
lit
  = r:LITERAL                   { return ast.Tex.LITERAL(r); }
  // quasi-literal; this is from Texutil.find(...) but the result is not
  // guaranteed to be Tex.LITERAL(RenderT...)
  / f:generic_func &{ return tu.nullary_macro_aliase[f]; } _ // from Texutil.find(...)
   {
     var ast = peg$parse(tu.nullary_macro_aliase[f]);
     assert.ok(ast.name === 'ARRAY' && ast.length === 1);
     return ast[0];
   }
  / f:generic_func &{ return tu.deprecated_nullary_macro_aliase[f]; } _ // from Texutil.find(...)
   {
     var ast = peg$parse(tu.deprecated_nullary_macro_aliase[f]);
     assert.ok(ast.name === 'ARRAY' && ast.length === 1);
     if (options.oldtexvc){
       return ast[0];
     } else {
          throw new peg$SyntaxError("Deprecation: Alias no longer supported.", [], text(), location());
     }
   }
  / r:DELIMITER                 { return ast.Tex.LITERAL(r); }
  / b:BIG r:DELIMITER           { return ast.Tex.BIG(b, r); }
  / b:BIG SQ_CLOSE              { return ast.Tex.BIG(b, ast.RenderT.TEX_ONLY( "]")); }
  / l:left e:expr r:right       { return ast.Tex.LR(l, r, e.toArray()); }
  / name:FUN_AR1opt e:expr_nosqc SQ_CLOSE l:lit /* must be before FUN_AR1 */
    { return ast.Tex.FUN2sq(name, ast.Tex.CURLY(e.toArray()), l); }
  / name:FUN_AR1 l:lit          { return ast.Tex.FUN1(name, l); }
  / name:FUN_AR1nb l:lit        { return ast.Tex.FUN1nb(name, l); }
  / name:FUN_MHCHEM l:chem_lit  { return ast.Tex.MHCHEM(name, l); }
  / name:FUN_AR2 l1:lit l2:lit  { return ast.Tex.FUN2(name, l1, l2); }
  / name:FUN_AR2nb l1:lit l2:lit { return ast.Tex.FUN2nb(name, l1, l2); }
  / BOX
  / CURLY_OPEN e:expr CURLY_CLOSE
    { return ast.Tex.CURLY(e.toArray()); }
  / CURLY_OPEN e1:ne_expr name:FUN_INFIX e2:ne_expr CURLY_CLOSE
    { return ast.Tex.INFIX(name, e1.toArray(), e2.toArray()); }
  / CURLY_OPEN e1:ne_expr f:FUN_INFIXh e2:ne_expr CURLY_CLOSE
    { return ast.Tex.INFIXh(f[0], f[1], e1.toArray(), e2.toArray()); }
  / BEGIN_MATRIX   m:(array/matrix) END_MATRIX
    { return ast.Tex.MATRIX("matrix", lst2arr(m)); }
  / BEGIN_PMATRIX  m:(array/matrix) END_PMATRIX
    { return ast.Tex.MATRIX("pmatrix", lst2arr(m)); }
  / BEGIN_BMATRIX  m:(array/matrix) END_BMATRIX
    { return ast.Tex.MATRIX("bmatrix", lst2arr(m)); }
  / BEGIN_BBMATRIX m:(array/matrix) END_BBMATRIX
    { return ast.Tex.MATRIX("Bmatrix", lst2arr(m)); }
  / BEGIN_VMATRIX  m:(array/matrix) END_VMATRIX
    { return ast.Tex.MATRIX("vmatrix", lst2arr(m)); }
  / BEGIN_VVMATRIX m:(array/matrix) END_VVMATRIX
    { return ast.Tex.MATRIX("Vmatrix", lst2arr(m)); }
  / BEGIN_ARRAY    opt_pos m:array END_ARRAY
    { return ast.Tex.MATRIX("array", lst2arr(m)); }
  / BEGIN_ALIGN    opt_pos m:matrix END_ALIGN
    { return ast.Tex.MATRIX("aligned", lst2arr(m)); }
  / BEGIN_ALIGNED  opt_pos m:matrix END_ALIGNED // parse what we emit
    { return ast.Tex.MATRIX("aligned", lst2arr(m)); }
  / BEGIN_ALIGNAT  m:alignat END_ALIGNAT
    { return ast.Tex.MATRIX("alignedat", lst2arr(m)); }
  / BEGIN_ALIGNEDAT m:alignat END_ALIGNEDAT // parse what we emit
    { return ast.Tex.MATRIX("alignedat", lst2arr(m)); }
  / BEGIN_SMALLMATRIX m:(array/matrix) END_SMALLMATRIX
    { return ast.Tex.MATRIX("smallmatrix", lst2arr(m)); }
  / BEGIN_CASES    m:matrix END_CASES
    { return ast.Tex.MATRIX("cases", lst2arr(m)); }
  / "\\begin{" alpha+ "}" /* better error messages for unknown environments */
    { throw new peg$SyntaxError("Illegal TeX function", [], text(), location()); }
  / f:generic_func &{ return !tu.all_functions[f]; }
    { throw new peg$SyntaxError("Illegal TeX function", [], f, location()); }


// "array" requires mandatory column specification
array
  = cs:column_spec m:matrix
    { m.head[0].unshift(cs); return m; }

// "alignat" requires mandatory # of columns
alignat
  = as:alignat_spec m:matrix
    { m.head[0].unshift(as); return m; }

// "matrix" does not require column specification
matrix
  = l:line_start tail:( NEXT_ROW m:matrix { return m; } )?
    { return { head: lst2arr(l), tail: tail }; }
line_start
  = f:HLINE l:line_start
    { l.head.unshift(ast.Tex.LITERAL(ast.RenderT.TEX_ONLY(f + " "))); return l;}
  / line
line
  = e:expr tail:( NEXT_CELL l:line { return l; } )?
    { return { head: e.toArray(), tail: tail }; }

column_spec
  = CURLY_OPEN cs:(one_col+ { return text(); }) CURLY_CLOSE
    { return ast.Tex.CURLY([ast.Tex.LITERAL(ast.RenderT.TEX_ONLY(cs))]); }

one_col
  = [lrc] _
  / "p" CURLY_OPEN boxchars+ CURLY_CLOSE
  / "*" CURLY_OPEN [0-9]+ _ CURLY_CLOSE
     ( one_col
     / CURLY_OPEN one_col+ CURLY_CLOSE
     )
  / "||" _
  / "|" _
  / "@" _ CURLY_OPEN boxchars+ CURLY_CLOSE

alignat_spec
  = CURLY_OPEN num:([0-9]+ { return text(); }) _ CURLY_CLOSE
    { return ast.Tex.CURLY([ast.Tex.LITERAL(ast.RenderT.TEX_ONLY(num))]); }

opt_pos
  = "[" _ [tcb] _ "]" _
  / "" /* empty */

/////////////////////////////////////////////////////////////
// MHCHEM grammar rules
//----------------------------------------------------------


chem_lit
  = CURLY_OPEN e:chem_sentence CURLY_CLOSE               { return ast.Tex.CURLY(e.toArray()); }

chem_sentence =
    _ p:chem_phrase " " s:chem_sentence                  { return ast.LList(p,ast.LList(ast.Tex.LITERAL(ast.RenderT.TEX_ONLY(" ")),s)); } /
    _ p:chem_phrase _                                    { return ast.LList(p,ast.LList.EMPTY); }

chem_phrase =
    m:"(^)"                                              { return ast.Tex.LITERAL(ast.RenderT.TEX_ONLY(m)); } /
    m:chem_word n:CHEM_SINGLE_MACRO                      { return ast.Tex.CHEM_WORD(m, ast.Tex.LITERAL(ast.RenderT.TEX_ONLY(n))); }/
    m:chem_word                                          { return m; } /
    m:CHEM_SINGLE_MACRO                                  { return ast.Tex.LITERAL(ast.RenderT.TEX_ONLY(m)); } /
    m:"^"                                                { return ast.Tex.LITERAL(ast.RenderT.TEX_ONLY(m)); }

chem_word =
    m:chem_char n:chem_word_nt                           { return ast.Tex.CHEM_WORD(m, n); } /
    m:CHEM_SINGLE_MACRO n:chem_char_nl o:chem_word_nt    { return ast.Tex.CHEM_WORD(ast.Tex.CHEM_WORD(ast.Tex.LITERAL(ast.RenderT.TEX_ONLY(m)), n), o); }

chem_word_nt = m:chem_word                               { return m; } /
    ""                                                   { return ast.Tex.LITERAL(ast.RenderT.TEX_ONLY("")); }

chem_char =
    m:chem_char_nl                                       { return m;} /
    c:CHEM_LETTER                                        { return ast.Tex.LITERAL(ast.RenderT.TEX_ONLY(c)) }

chem_char_nl =
    m:chem_script                                        { return m;} /
    CURLY_OPEN c:chem_text CURLY_CLOSE                   { return ast.Tex.CURLY([c]); } /
    BEGIN_MATH c:expr END_MATH                           { return ast.Tex.DOLLAR(c.toArray()); }/
    name:CHEM_BOND l:chem_bond                           { return ast.Tex.FUN1(name, l); } /
    m:chem_macro                                         { return m; } /
    c:CHEM_NONLETTER                                     { return ast.Tex.LITERAL(ast.RenderT.TEX_ONLY(c)) }

chem_bond
 = CURLY_OPEN e:CHEM_BOND_TYPE CURLY_CLOSE               { return ast.Tex.CURLY([ast.Tex.LITERAL(ast.RenderT.TEX_ONLY(e))]); }

chem_script =
    a:CHEM_SUPERSUB b:CHEM_SCRIPT_FOLLOW                 { return ast.Tex.CHEM_WORD(ast.Tex.LITERAL(ast.RenderT.TEX_ONLY(a)), ast.Tex.LITERAL(ast.RenderT.TEX_ONLY(b))); } /
    a:CHEM_SUPERSUB b:chem_lit                           { return ast.Tex.CHEM_WORD(ast.Tex.LITERAL(ast.RenderT.TEX_ONLY(a)), b); } /
    a:CHEM_SUPERSUB BEGIN_MATH b:expr END_MATH           { return ast.Tex.CHEM_WORD(ast.Tex.LITERAL(ast.RenderT.TEX_ONLY(a)), ast.Tex.DOLLAR(b.toArray())); }

// TODO \color is a not documented feature of mhchem for MathJax, at the moment named colors are accepted
chem_macro =
    name:CHEM_MACRO_2PU l1:chem_lit "_" l2:chem_lit      { return ast.Tex.CHEM_FUN2u(name, l1, l2); }/ //return ast.Tex.FUN1nb(name, l);
    name:CHEM_MACRO_2PC l1:CHEM_COLOR l2:chem_lit        { return ast.Tex.FUN2(name, l1, l2); } /
    name:CHEM_MACRO_2P l1:chem_lit l2:chem_lit           { return ast.Tex.FUN2(name, l1, l2); } /
    name:CHEM_MACRO_1P l:chem_lit                        { return ast.Tex.FUN1(name, l); }

chem_text = cs:boxchars+                                 { return ast.Tex.LITERAL(ast.RenderT.TEX_ONLY(cs.join(''))); }
CHEM_COLOR = "{" _ name:alpha+ _ "}" _                   { return ast.Tex.LITERAL(ast.RenderT.TEX_ONLY(name.join(''))); }

/////////////////////////////////////////////////////////////
// LEXER
//----------------------------------------------------------
//space =           [ \t\n\r]
alpha =           [a-zA-Z]
literal_id =      [a-zA-Z]
literal_mn =      [0-9]
literal_uf_lt =   [,:;?!\']
delimiter_uf_lt = [().]
literal_uf_op =   [-+*=]
delimiter_uf_op = [\/|]
boxchars // match only valid UTF-16 sequences
 = [-0-9a-zA-Z+*,=():\/;?.!\'` \[\]\x80-\ud7ff\ue000-\uffff]
 / l:[\ud800-\udbff] h:[\udc00-\udfff] { return text(); }
//aboxchars = [-0-9a-zA-Z+*,=():\/;?.!\'` ]

BOX
 = b:generic_func &{ return tu.box_functions[b]; } _ "{" cs:boxchars+ "}" _
   { return ast.Tex.BOX(b, cs.join('')); }

// returns a RenderT
LITERAL
 = c:( literal_id / literal_mn / literal_uf_lt / "-" / literal_uf_op ) _
   { return ast.RenderT.TEX_ONLY(c); }
 / f:generic_func &{ return tu.latex_function_names[f]; } _
   c:( "(" / "[" / "\\{" / "" { return " ";}) _
   { return ast.RenderT.TEX_ONLY(f + c); }
 / f:generic_func &{ return tu.mediawiki_function_names[f]; } _
   c:( "(" / "[" / "\\{" / "" { return " ";}) _
   { return ast.RenderT.TEX_ONLY("\\operatorname {" + f.slice(1) + "}" + c); }
 / f:generic_func &{ return tu.nullary_macro[f]; } _ // from Texutil.find(...)
   { return ast.RenderT.TEX_ONLY(f + " "); }
 / f:generic_func &{ return options.usemathrm && tu.nullary_macro_in_mbox[f]; } _ // from Texutil.find(...)
   { return ast.RenderT.TEX_ONLY("\\mathrm {" + f + "} "); }
 / mathrm:generic_func &{ return options.usemathrm && mathrm === "\\mathrm"; } _
   "{" f:generic_func &{ return options.usemathrm && tu.nullary_macro_in_mbox[f]; } _ "}" _
   /* make sure we can parse what we emit */
   { return options.usemathrm && ast.RenderT.TEX_ONLY("\\mathrm {" + f + "} "); }
 / f:generic_func &{ return tu.nullary_macro_in_mbox[f]; } _ // from Texutil.find(...)
   { return ast.RenderT.TEX_ONLY("\\mbox{" + f + "} "); }
 / mbox:generic_func &{ return mbox === "\\mbox"; } _
   "{" f:generic_func &{ return tu.nullary_macro_in_mbox[f]; } _ "}" _
 /* make sure we can parse what we emit */
  { return ast.RenderT.TEX_ONLY("\\mbox{" + f + "} "); }
 / f:(COLOR / DEFINECOLOR)
   { return ast.RenderT.TEX_ONLY(f); }
 / "\\" c:[, ;!_#%$&] _
   { return ast.RenderT.TEX_ONLY("\\" + c); }
 / c:[><~] _
   { return ast.RenderT.TEX_ONLY(c); }
 / c:[%$] _
   { if(options.oldtexvc) {
    return ast.RenderT.TEX_ONLY("\\" + c); /* escape dangerous chars */
    } else {
     throw new peg$SyntaxError("Deprecation: % and $ need to be escaped.", [], text(), location());
    }}

// returns a RenderT
DELIMITER
 = c:( delimiter_uf_lt / delimiter_uf_op / "[" ) _
   { return ast.RenderT.TEX_ONLY(c); }
 / "\\" c:[{}|] _
   { return ast.RenderT.TEX_ONLY("\\" + c); }
 / f:generic_func &{ return tu.other_delimiters1[f]; } _ // from Texutil.find()
   { return ast.RenderT.TEX_ONLY(f + " "); }
 / f:generic_func &{ return tu.other_delimiters2[f]; } _ // from Texutil.find()
   { var p = peg$parse(tu.other_delimiters2[f]);
     assert.ok(p.name === 'ARRAY' && p.length === 1);
     assert.ok(p[0].constructor === ast.Tex.LITERAL);
     assert.ok(p[0][0].constructor === ast.RenderT.TEX_ONLY);
     return p[0][0];
   }

FUN_AR1nb
 = f:generic_func &{ return tu.fun_ar1nb[f]; } _ { return f; }

FUN_AR1opt
 = f:generic_func &{ return tu.fun_ar1opt[f]; } _ "[" _ { return f; }

NEXT_CELL
 = "&" _

NEXT_ROW
 = "\\\\" _

BEGIN
 = "\\begin" _
END
 = "\\end" _

BEGIN_MATRIX
 = BEGIN "{matrix}" _
END_MATRIX
 = END "{matrix}" _
BEGIN_PMATRIX
 = BEGIN "{pmatrix}" _
END_PMATRIX
 = END "{pmatrix}" _
BEGIN_BMATRIX
 = BEGIN "{bmatrix}" _
END_BMATRIX
 = END "{bmatrix}" _
BEGIN_BBMATRIX
 = BEGIN "{Bmatrix}" _
END_BBMATRIX
 = END "{Bmatrix}" _
BEGIN_VMATRIX
 = BEGIN "{vmatrix}" _
END_VMATRIX
 = END "{vmatrix}" _
BEGIN_VVMATRIX
 = BEGIN "{Vmatrix}" _
END_VVMATRIX
 = END "{Vmatrix}" _
BEGIN_ARRAY
 = BEGIN "{array}" _
END_ARRAY
 = END "{array}" _
BEGIN_ALIGN
 = BEGIN "{align}" _
END_ALIGN
 = END "{align}" _
BEGIN_ALIGNED
 = BEGIN "{aligned}" _
END_ALIGNED
 = END "{aligned}" _
BEGIN_ALIGNAT
 = BEGIN "{alignat}" _
END_ALIGNAT
 = END "{alignat}" _
BEGIN_ALIGNEDAT
 = BEGIN "{alignedat}" _
END_ALIGNEDAT
 = END "{alignedat}" _
BEGIN_SMALLMATRIX
 = BEGIN "{smallmatrix}" _
END_SMALLMATRIX
 = END "{smallmatrix}" _
BEGIN_CASES
 = BEGIN "{cases}" _
END_CASES
 = END "{cases}" _

SQ_CLOSE
 =  "]" _
CURLY_OPEN
 = "{" _
CURLY_CLOSE
 = "}" _
SUP
 = "^" _
SUB
 = "_" _

// This is from Texutil.find in texvc
generic_func
 = "\\" alpha+ { return text(); }

BIG
 = f:generic_func &{ return tu.big_literals[f]; } _
   { return f; }

FUN_AR1
 = f:generic_func &{ return tu.fun_ar1[f]; } _
   { return f; }
 / f:generic_func &{ return options.oldmhchem && tu.fun_mhchem[f]} _
   { return f; }
 / f:generic_func &{ return tu.other_fun_ar1[f]; } _
   { if (options.oldtexvc) {
        return tu.other_fun_ar1[f];
     } else {
        throw new peg$SyntaxError("Deprecation: \\Bbb and \\bold are not allowed in math mode.", [], text(), location());
       }}

FUN_MHCHEM
 = f:generic_func &{ return tu.fun_mhchem[f]; } _
   { return f; }

FUN_AR2
 = f:generic_func &{ return tu.fun_ar2[f]; } _
   { return f; }

FUN_INFIX
 = f:generic_func &{ return tu.fun_infix[f]; } _
   { return f; }

DECLh
 = f:generic_func &{ return tu.declh_function[f]; } _
   { return ast.Tex.DECLh(f, ast.FontForce.RM(), []); /*see bug 54818*/ }

FUN_AR2nb
 = f:generic_func &{ return tu.fun_ar2nb[f]; } _
   { return f; }

LEFT
 = f:generic_func &{ return tu.left_function[f]; } _

RIGHT
 = f:generic_func &{ return tu.right_function[f]; } _

HLINE
 = f:generic_func &{ return tu.hline_function[f]; } _
   { return f; }

COLOR
 = f:generic_func &{ return tu.color_function[f]; } _ cs:COLOR_SPEC
   { return f + " " + cs; }

DEFINECOLOR
 = f:generic_func &{ return tu.definecolor_function[f]; } _
   "{" _ name:alpha+ _ "}" _ "{" _
     a:( "named"i _ "}" _ cs:COLOR_SPEC_NAMED { return "{named}" + cs; }
       / "gray"i  _ "}" _ cs:COLOR_SPEC_GRAY  { return "{gray}" + cs; }
       / "rgb"    _ "}" _ cs:COLOR_SPEC_rgb   { return "{rgb}" + cs; }
       // Note that we actually convert RGB format to rgb format here.
       / "RGB"    _ "}" _ cs:COLOR_SPEC_RGB   { return "{rgb}" + cs; }
       / "cmyk"i  _ "}" _ cs:COLOR_SPEC_CMYK  { return "{cmyk}" + cs; } )
   { return f + " {" + name.join('') + "}" + a; }

COLOR_SPEC
 = COLOR_SPEC_NAMED
 / "[" _ "named"i _ "]" _ cs:COLOR_SPEC_NAMED
   { return "[named]" + cs; }
 / "[" _ "gray"i _ "]" _ cs:COLOR_SPEC_GRAY
   { return "[gray]" + cs; }
 / "[" _ "rgb"  _ "]" _ cs:COLOR_SPEC_rgb
   { return "[rgb]" + cs; }
 / "[" _ "RGB"  _ "]" _ cs:COLOR_SPEC_RGB
   // Note that we actually convert RGB format to rgb format here.
   { return "[rgb]" + cs; }
 / "[" _ "cmyk"i _ "]" _ cs:COLOR_SPEC_CMYK
   { return "[cmyk]" + cs; }

COLOR_SPEC_NAMED
 = "{" _ name:alpha+ _ "}" _
   { return "{" + name.join('') + "}"; }
COLOR_SPEC_GRAY
 = "{" _ k:CNUM + "}"
   { return "{"+k+"}"; }
COLOR_SPEC_rgb
 = "{" _ r:CNUM "," _ g:CNUM "," _ b:CNUM "}" _
   { return "{"+r+","+g+","+b+"}"; }
COLOR_SPEC_RGB
 = "{" _ r:CNUM255 "," _ g:CNUM255 "," _ b:CNUM255 "}" _
   // Note that we normalize the values to [0,1] here.
   { return "{"+r+","+g+","+b+"}"; }
COLOR_SPEC_CMYK
 = "{" _ c:CNUM "," _ m:CNUM "," _ y:CNUM "," _ k:CNUM "}" _
   { return "{"+c+","+m+","+y+","+k+"}"; }

// An integer in [0, 255] => normalize it to [0,1]
CNUM255
 = n:$( "0" / ([1-9] ([0-9] [0-9]?)? ) ) &{ return parseInt(n, 10) <= 255; } _
   { return n / 255; }

// A floating-point number in [0, 1]
CNUM
 = n:$( "0"? "." [0-9]+ ) _
   { return n; }
 / n:$( [01] "."? ) _
   { return n; }


// MHCHEM LEXER RULES
CHEM_SINGLE_MACRO
 = f:generic_func &{ return tu.mhchem_single_macro[f]; } { return f; }
 / "\\" c:[, ;!_#%$&] { return "\\" + c; }

CHEM_BOND = f:generic_func &{ return tu.mhchem_bond[f]; } _ { return f; }

CHEM_MACRO_1P = f:generic_func &{ return tu.mhchem_macro_1p[f]; } _   { return f; }

CHEM_MACRO_2P = f:generic_func &{ return tu.mhchem_macro_2p[f]; } _   { return f; }

CHEM_MACRO_2PU = f:generic_func &{ return tu.mhchem_macro_2pu[f]; } _ { return f; }

CHEM_MACRO_2PC = f:generic_func &{ return tu.mhchem_macro_2pc[f]; } _ { return f; }

CHEM_SCRIPT_FOLLOW = literal_mn / literal_id / [+-.*']

CHEM_SUPERSUB = "_" / "^"

CHEM_BOND_TYPE = "=" / "#" / "~--" / "~-"  / "~=" / "~" / "-~-" / "...." / "..." / "<-" / "->" / "-" / "1" / "2" / "3"


// As '$' cannot be used (dangerous char in math mode) to switch from chem mode to math mode
// \begin{math} and \end{math} are introduced to do so
BEGIN_MATH = BEGIN "{math}" _

END_MATH = END "{math}" _

CHEM_LETTER = [a-zA-Z]

CHEM_NONLETTER =
    c: "\\{" { return c; } /
    c: "\\}" { return c; } /
    c: "\\\\" { return c; } /
    c:[+-=#().,;/*<>|@&\'\[\]] { return c; } /
    c:literal_mn { return c; } /
    CURLY_OPEN CURLY_CLOSE { return "{}"; }

// Missing lexer tokens!
FUN_INFIXh = impossible
FUN_AR1hl = impossible
FUN_AR1hf = impossible
FUN_AR2h = impossible
impossible = & { return false; }

// End of file
EOF = & { return peg$currPos === input.length; }
