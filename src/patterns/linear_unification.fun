functor AbtLinearUnification (P : ABT_PATTERN) : ABT_LINEAR_UNIFICATION =
struct
  open P
  open Abt Pattern

  structure Env =
    SplayDict
      (structure Key =
       struct
         open Abt.Metavariable Abt.Metavariable.Eq
       end)

  structure Ren =
    SplayDict
      (structure Key =
       struct
         open Abt.Symbol Abt.Symbol.Eq
       end)

  type env = abt bview Env.dict
  type ren = Abt.symbol Ren.dict

  exception UnificationFailure

  datatype match = <*> of pattern * abt

  infix $ $# $@ \ <*>
  structure Spine = Operator.Arity.Valence.Spine
  structure Sort = Operator.Arity.Sort

  fun matchOperator (ptheta, theta) =
    (* compare if they are the "same" operator modulo parameters *)
    if Operator.Eq.eq (fn _ => true) (ptheta, theta) then
      let
        (* therefore, the operators should have compatible supports *)
        val us = Operator.support ptheta
        val vs = Operator.support theta
      in
        ListPair.foldlEq (fn ((u, _), (v, _), rho) => Ren.insert rho u v) Ren.empty (us, vs)
      end
    else
      raise UnificationFailure

  fun matchSort (sigma, tau) =
    if Sort.Eq.eq (sigma, tau) then
      ()
    else
      raise UnificationFailure

  fun extendEnv rho (mv, e) =
    Env.insertMerge rho mv e (fn _ => raise UnificationFailure)
  fun concatEnv (rho, rho') =
    Env.union rho rho' (fn _ => raise UnificationFailure)
  fun concatRen (rho, rho') =
    Ren.union rho rho' (fn (u, v, v') => if Symbol.Eq.eq (v, v') then v else raise UnificationFailure)

  fun unify (pat <*> m) : ren * env =
    let
      val (ptheta $@ pargs, Theta) = Pattern.out pat
      val (theta $ es, tau) = Abt.infer m
      fun go [] [] (rho, env) = (rho, env)
        | go (MVAR mv :: pargs) (e :: es) (rho, env) = go pargs es (rho, extendEnv env (mv, e))
        | go (PAT pat :: pargs) ((([], []) \ m) :: es) (rho, env) =
            let
              val (rho', env') = unify (pat <*> m)
            in
              go pargs es (concatRen (rho, rho'), concatEnv (env, env'))
            end
        | go _ _ _ = raise UnificationFailure
      val (rho, env) = go pargs es (Ren.empty, Env.empty)
    in
      (concatRen (matchOperator (ptheta, theta), rho), env)
    end
end
