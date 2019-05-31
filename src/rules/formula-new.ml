(* Contains all the logic for access predicates, etc.
 *
 * TODO: Refactoring -- The organization of this stuff is just generally a mess
 *
 *   Simiilarly, the only reason we don't have the Idf.satisfiable function in
 *   this file is that we need it to rely on both Formula and SAT.
 *
 * Formulas are values of type 'a t, where the 'a can be `precise' or
 * `imprecise'. This done at the type level so we can ensure that we don't
 * call static WLP on a gradual formula (etc). This does lead to complications
 * elsewhere (such as needing to write gradualWLP in continuation passing
 * style), as well as generally more complex code.
*)

open Core
open Functools

module A = Ast

module LM = List.Assoc

exception Unsat
exception Malformed

(* -------------------------------------------------------------------------------------------------------------------------*)
(* Id *)

(* -------------------------------------------------------------------------------------------------------------------------*)
(* P (Program) *)

(* -------------------------------------------------------------------------------------------------------------------------*)
(* cls *)

(* -------------------------------------------------------------------------------------------------------------------------*)
(* predicate *)

(* -------------------------------------------------------------------------------------------------------------------------*)
(* T (type) *)

(* -------------------------------------------------------------------------------------------------------------------------*)
(* method *)

(* -------------------------------------------------------------------------------------------------------------------------*)
(* contract *)

(* -------------------------------------------------------------------------------------------------------------------------*)
(* circle-plus (binary operation) *)

(* type binary_operation = A.binary_operation = *)
type expop = A.expop =
  | Add
  | Sub
  | Mul
  | Div
  [@@deriving sexp, compare]

(* -------------------------------------------------------------------------------------------------------------------------*)
(* circle-dot (binary comparison) *)

type binary_comparison = A.binary_comparison =
  | Neq
  | Eq
  | Lt
  | Gt
  | Le
  | Ge

(* -------------------------------------------------------------------------------------------------------------------------*)
(* s (statement) *)

(* -------------------------------------------------------------------------------------------------------------------------*)
(* e (expression) *)

(* -------------------------------------------------------------------------------------------------------------------------*)
(* x (variable) *)

(* -------------------------------------------------------------------------------------------------------------------------*)
(* v (value) *)

(* -------------------------------------------------------------------------------------------------------------------------*)
(* n (number) *)

(* -------------------------------------------------------------------------------------------------------------------------*)
(* formula *)

(* -------------------------------------------------------------------------------------------------------------------------*)
(* tphi (imprecise formula) *)

(* -------------------------------------------------------------------------------------------------------------------------*)
(* phi (concrete formula) *)
