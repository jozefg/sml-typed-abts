structure Example =
struct
  structure M = Symbol ()
  structure V = Symbol ()
  structure I = Symbol ()

  structure O =
  struct
    structure Sort =
    struct
      datatype t = EXP | VAL | NAT

      structure Eq =
      struct
        type t = t
        val eq : t * t -> bool = op=
      end

      structure Show =
      struct
        type t = t
        fun toString EXP = "exp"
          | toString VAL = "val"
          | toString NAT = "nat"
      end
    end


    structure Arity = Arity (structure Sort = Sort and Spine = ListSpine)

    datatype 'i t =
        LAM | AP | NUM | LIT of int | RET
      | DCL | GET of 'i | SET of 'i

    fun eq f (LAM, LAM) = true
      | eq f (AP, AP) = true
      | eq f (NUM, NUM) = true
      | eq f (LIT m, LIT n) = m = n
      | eq f (RET, RET) = true
      | eq f (DCL, DCL) = true
      | eq f (GET i, GET j) = f (i, j)
      | eq f (SET i, SET j) = f (i, j)
      | eq _ _ = false

    fun toString f LAM = "lam"
      | toString f AP = "ap"
      | toString f NUM = "num"
      | toString f (LIT n) = Int.toString n
      | toString f RET = "ret"
      | toString f DCL = "dcl"
      | toString f (GET i) = "get[" ^ f i ^ "]"
      | toString f (SET i) = "set[" ^ f i ^ "]"

    local
      open Sort
      fun replicate i x = List.tabulate (i, fn _ => x)
      fun mkValence p q s = ((p, q), s)
    in
      fun arity LAM = ([mkValence [] [EXP] EXP], EXP)
        | arity RET = ([mkValence [] [] VAL], EXP)
        | arity AP = ([mkValence [] [] EXP, mkValence [] [] EXP], EXP)
        | arity NUM = ([mkValence [] [] NAT], VAL)
        | arity (LIT _) = ([], NAT)
        | arity DCL = ([mkValence [] [] EXP, mkValence [EXP] [] EXP], EXP)
        | arity (GET i) = ([], EXP)
        | arity (SET i) = ([mkValence [] [] EXP], EXP)

      fun support (GET i) = [(i, EXP)]
        | support (SET i) = [(i, EXP)]
        | support _ = []
    end

    structure Presheaf =
    struct
      type 'i t = 'i t
      fun map f LAM = LAM
        | map f AP = AP
        | map f NUM = NUM
        | map f (LIT n) = LIT n
        | map f RET = RET
        | map f DCL = DCL
        | map f (GET i) = GET (f i)
        | map f (SET i) = SET (f i)
    end
  end

  structure OParser : PARSE_OPERATOR =
  struct
    structure Operator = O
    open O
    open ParserCombinators CharParser

    infixr 4 << >>
    infixr 3 &&
    infix 2 -- ##
    infix 2 wth suchthat return guard when
    infixr 1 || <|> ??

    structure LangDef :> LANGUAGE_DEF =
    struct
      type scanner = char CharParser.charParser
      val commentStart = NONE
      val commentEnd = NONE
      val commentLine = NONE
      val nestedComments = true

      val identLetter =
        CharParser.letter
          || CharParser.oneOf (String.explode "_'ΑαΒβΓγΔδΕεΖζΗηΘθΙιΚκΛλΜμΝνΞξΟοΠπΡρΣσΤτΥυΦφΧχΨψΩω")
          || digit
      val identStart = identLetter
      val opStart = fail "Operators not supported" : scanner
      val opLetter = opStart
      val reservedNames = []
      val reservedOpNames = []
      val caseSensitive = true
    end

    structure TP = TokenParser (LangDef)
    open TP

    val parseInt =
      repeat1 digit wth valOf o Int.fromString o String.implode

    val parse : string O.t CharParser.charParser =
      string "lam" return LAM
        || string "ap" return AP
        || string "num" return NUM
        || parseInt wth LIT
        || string "ret" return RET
        || string "dcl" return DCL
        || string "get" >> squares identifier wth GET
        || string "set" >> squares identifier wth SET
  end

  structure Ast = Ast (structure Operator = O and Metavariable = M)
  structure AstParser = ParseAst (structure Ast = Ast and ParseOperator = OParser and Metavariable = M)

  structure MC = Metacontext (structure Metavariable = M structure Valence = O.Arity.Valence.Eq)

  structure Abt = AbtUtil(Abt (structure Operator = O and Metavariable = M and Metacontext = MC and Variable = V and Symbol = I))
  structure AstToAbt = AstToAbt (structure Abt = Abt and Ast = Ast)

  structure ShowAbt = DebugShowAbt (Abt)
  open O O.Sort Abt

  fun loop () =
    let
      val input = (print "> "; TextIO.inputLine TextIO.stdIn)
    in
      case input of
           NONE => ()
         | SOME str =>
             (let
               val parseResult = CharParser.parseString (AstParser.parse M.named) str
               val ast as (Ast.$ (theta, es)) =
                 case parseResult of
                      Sum.INR ast => ast
                    | Sum.INL err => raise Fail err
               val (_, tau) = O.arity theta
               val abt = AstToAbt.convert MC.empty (ast, tau)
             in
               print (ShowAbt.toString abt ^ "\n\n")
             end
             handle err => print ("Error: " ^ exnMessage err ^ "\n\n"));
             loop ()
    end

  val _ =
    (print "\n\nType an expression at the prompt\n\n";
     loop ())
end
