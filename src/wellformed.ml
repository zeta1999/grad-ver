open Core
open Ast_types
open Ast
open Utility

(****************************************************************************************************************************)
(* utilities *)

(* exceptions *)
(* TODO: move these to their respective relevant places in the code? *)

(* malformed *)
exception Malformed of string
exception Invalid_field_reference_base of expression * id
(* undefined/undeclared *)
exception Class_undefined     of id
exception Class_mismatch      of class_ * class_
exception Field_undeclared    of class_ * id
exception Predicate_undefined of class_ * id
exception Method_undefined    of class_ * id
exception Variable_undeclared of id
(* type mismatch *)
exception Type_mismatch of type_ * type_
(* arguments length mismatch *)
exception Method_call_arguments_length_mismatch  of method_   * statement_method_call
exception Fold_arguments_length_mismatch         of predicate * statement_fold
exception Unfold_arguments_length_mismatch       of predicate * statement_unfold
exception Unfolding_in_arguments_length_mismatch of predicate * formula_concrete_unfolding_in

(* useful functions *)
(* move these to a utilities or separate Ast module? *)

(* equality *)

let eqId : id -> id -> bool = (=)

let eqType : type_  -> type_  -> bool =
  fun typ typ' ->
  match (typ, typ') with
  | Int      , Int       -> true
  | Bool     , Bool      -> true
  | Class id , Class id' -> eqId id id'
  | Top      , Top       -> true
  | _ -> false

let eqClass : class_ -> class_ -> bool = fun cls cls' -> eqId cls.id cls'.id

let getVariableId : variable -> id =
  fun var ->
  match var with
  | Result  -> "result"
  | Id id   -> id
  | Old id  -> id
  | This    -> "this"

let getValueId : value -> id =
  fun vlu ->
  match vlu with
  | Object id -> id
  | _ -> raise @@ Malformed ("expected Objectid value, found other kind of value")

(****************************************************************************************************************************)
(* check *)

let check : bool -> exn -> unit =
  fun b e -> if b then () else raise e

let checkSome : 'a option -> exn -> unit =
  fun opt e -> match opt with Some a -> () | None -> raise e

let getSome : 'a option -> exn -> 'a =
  fun opt e -> match opt with Some a -> a | None -> raise e

let checkFold : ('a -> unit) -> 'a Core.List.t -> unit =
  fun test -> List.fold ~init:() ~f:(fun () x -> test x)

(****************************************************************************************************************************)
(* type *)

let string_of_type_ : type_ -> string =
  function
  | Int       -> "Int"
  | Bool      -> "Bool"
  | Class cls -> "Class " ^ cls
  | Top       -> "Top"

let checkTypeMatch : type_ -> type_ -> unit =
  fun typ typ' ->
  (* DEBUG *)
  (* Printf.printf "checkTypeMatch (%s) (%s) => %s\n"
    (string_of_type_ typ)
    (string_of_type_ typ')
    (string_of_bool @@ eqType typ typ'); *)
  check (eqType typ typ') @@
  Type_mismatch (typ, typ')

let checkClassMatch : class_ -> class_ -> unit =
  fun cls cls' ->
  check (eqClass cls cls') @@
  Class_mismatch (cls, cls')

(****************************************************************************************************************************)
(* context *)

module Context = struct
  type 'a t = (string, 'a) Core.String.Table.t_

  let create : unit -> 'a t = String.Table.create

  let find : 'a t -> id -> 'a option  = fun ctx id   -> Hashtbl.find ctx id
  let set  : 'a t -> id -> 'a -> unit = fun ctx id v -> Hashtbl.set  ctx id v

  let findExcept : 'a t -> id -> exn -> 'a =
    fun ctx id e -> getSome (find ctx id) e
end

(*****************************************************************)
(* context of class definitions *)

let class_context : class_ Context.t = Context.create ();;

let setClass : id -> class_ -> unit = Context.set class_context
let getClass : id -> class_ = fun id ->
  Context.findExcept class_context id @@
    Class_undefined id

let getField : id -> id -> class_field =
  fun clsid fldid ->
  let cls = getClass clsid in
  getSome (List.find cls.fields ~f:(fun fld -> eqId fld.id fldid)) @@
    Field_undeclared (cls, fldid)

let getFieldType : id -> id -> type_ =
  fun clsid fldid -> (getField clsid fldid).type_

let getPredicate : id -> id -> predicate =
  fun clsid predid ->
  let cls = getClass clsid in
  getSome (List.find cls.predicates ~f:(fun pred -> eqId pred.id predid)) @@
    Predicate_undefined (cls, predid)

let getPredicateArguments : id -> id -> argument list =
  fun clsid predid -> (getPredicate clsid predid).arguments
let getPredicateFormula : id -> id -> formula =
  fun clsid predid -> (getPredicate clsid predid).formula

let getMethod : id -> id -> method_ =
  fun clsid methid ->
  let cls = getClass clsid in
  getSome (List.find cls.methods ~f:(fun meth -> eqId meth.id methid)) @@
    Method_undefined (cls, methid)

(*****************************************************************)
(* context of variable declarations *)

let variable_context : type_ Context.t = Context.create ();;

let setVariableType : id -> type_ -> unit = Context.set variable_context
let getVariableType : id -> type_ = fun id -> Context.findExcept variable_context id @@ Variable_undeclared id

(****************************************************************************************************************************)
(* types *)

let rec getExpressionType : expression -> type_ =
  fun e ->
  match e with
  | Variable x ->
    begin
      match x with
      | Result -> getVariableType "result"
      | Id id  -> getVariableType id
      | Old id -> getVariableType id
      | This   -> getVariableType "this"
    end
  | Value v ->
    begin
      match v with
      | Int _     -> Int
      | Bool _    -> Bool
      | Object id -> Class id
      | Null      -> unimplemented () (* TODO: what should this be? *)
    end
  | Operation oper ->
    begin
      let ltyp  = getExpressionType oper.left in
      let rtyp = getExpressionType oper.right in
      match oper.operator with
      | Add | Sub | Mul | Div ->
        if (eqType ltyp rtyp) && (eqType ltyp Int)
        then Int
        else raise @@ Type_mismatch (ltyp, rtyp)
      | And | Or ->
        if (eqType ltyp rtyp) && (eqType ltyp Bool)
        then Bool
        else raise @@ Type_mismatch (ltyp, rtyp)
    end
  | Comparison bico ->
    begin
      let ltyp = getExpressionType bico.left in
      let rtyp = getExpressionType bico.right in
      if eqType ltyp rtyp
      then Top
      else raise @@ Malformed "type mismatch in binary comparison"
    end
  | Field_reference fldref ->
    begin
      let baseType = getExpressionType fldref.base in
      match baseType with
      | Class cls -> getFieldType cls fldref.field
      | _ -> raise @@ Malformed "attempted to reference field of non-object"
    end

(****************************************************************************************************************************)
(* check expression *)

let rec checkExpression : expression -> unit =
  fun expr ->
  match expr with
  | Variable var ->
    begin
      match var with
      | Old id -> ignore @@ getVariableType id (* variable is declared *)
      | _ -> ()
    end
  | Value vlu ->
    begin
      match vlu with
      | Object id -> ignore @@ getVariableType id (* variable is declared *)
      | _ -> ()
    end
  | Binary_operation oper ->
    ignore @@ getExpressionType expr (* type checks *)
  | Binary_comparison bico ->
    ignore @@ getExpressionType expr (* type checks *)
  | Field_reference fldref ->
    (* TODO: support nested field references *)
    (* let rec checkFieldreference : expression -> id -> unit =
      fun base fldid ->
      begin
        match base with
        | Variable var ->
          let vartyp =
            begin
              match var with
              | Id id -> getVariableType id
              | This  -> unimplemented ()
              | _ -> raise @@ Invalid_field_reference_base (base, fldid)
            end in
          begin
            match vartyp with
            | Class varcls -> ignore @@ getFieldType varcls.classid fldid
            | _ -> raise @@ Invalid_field_reference_base (base, fldid)
          end
        | Value vlu ->
          begin
            match vlu with
            | Objectid id -> unimplemented ()
            | _ -> raise @@ Invalid_field_reference_base (base, fldid)
          end
        | Fieldreference fldref ->
        | _ -> raise @@ Invalid_field_reference_base (base, fldid)
       end in *)
    begin
      match fldref.base with
      | Variable var -> ignore @@ getVariableType (getVariableId var)
      | Value vlu    -> unimplemented ()
      | _ -> raise @@ Invalid_field_reference_base (fldref.base, fldref.field)
    end

(****************************************************************************************************************************)
(* check formula *)

let rec checkConreteFormula : formula_concrete -> unit =
  fun phi ->
  match phi with
  | Expression expr ->
    unimplemented ()
  | Predicate_check predchk ->
    (* TODO: predicate is used without base, but all predicates are defined in classes... *)
    unimplemented ()
  | Access_check accchk ->
    begin
      match getExpressionType accchk.base with
      | Class cls -> ignore @@ getField accchk.field cls
      | _ -> raise @@ Malformed "attempted to access field of non-object"
    end
  | Operation op
  | Formula_operation
  | Logical_and logand ->
    (* TODO: messes up syntax highlighter... *)
    (* checkConreteFormula logand.andleft;
       checkConreteFormula logand.andright *)
    unimplemented ()
  | Logicalseparate logsep ->
    checkConreteFormula logsep.separateleft;
    checkConreteFormula logsep.separateright
  | Ifthenelse ite ->
    checkExpression     ite.condition;
    checkConreteFormula ite.thenformula;
    checkConreteFormula ite.elseformula
  | Unfoldingin unfolin ->
    (* TODO: predicate is used without base, but all predicates are defined in classes... *)
    let pred = getPredicate (unimplemented ()) unfolin.predicateid in
    (* given argument count matches expected *)
    check (List.length pred.arguments = List.length unfolin.arguments) @@
      Unfolding_in_arguments_length_mismatch (pred, unfolin);
    (* given arguments have correct types *)
    checkFold (fun ((arg,expr):argument*expression) -> checkTypeMatch arg.type_ (getExpressionType expr)) @@
      List.zip_exn pred.arguments unfolin.arguments;
    (* body formula *)
    checkConreteFormula unfolin.formula

and checkImpreciseFormula : formula_imprecise -> unit =
  fun phi ->
  unimplemented ()

and checkFormula : formula -> unit =
  fun phi ->
  match phi with
  | Imprecise phi_impr -> checkImpreciseFormula phi_impr
  | Concrete  phi_conc -> checkConreteFormula   phi_conc

let checkContract : contract -> unit =
  fun ctrt ->
  checkFormula ctrt.requires;
  checkFormula ctrt.ensures

(****************************************************************************************************************************)
(* statements *)

let rec checkStatement : statement -> unit =
  fun stmt ->
  match stmt with
  | Skip ->
    ()
  | Sequence seq ->
    checkStatement seq.prev;
    checkStatement seq.next
  | Declaration decl ->
    setVariableType decl.id decl.type_
  | Assignment asmt ->
    let typ, typ' = getExpressionType asmt.value, getVariableType asmt.id in
    checkTypeMatch typ typ'
  | Ifthenelse ite ->
    checkExpression ite.ifcondition;
    checkStatement  ite.thenbody;
    checkStatement  ite.elsebody
  | Whileloop wl ->
    checkFormula    wl.invariant;
    checkExpression wl.whilecondition;
    checkStatement  wl.whilebody
  | Fieldassignment fasmt ->
    let basetyp = getVariableType fasmt.baseid in
    begin
      match basetyp with
      | Class cls ->
        let fldtyp = getFieldType fasmt.baseid fasmt.fieldid in
        let srctyp = getVariableType fasmt.sourceid in
        checkTypeMatch fldtyp srctyp
      | _ -> raise @@ Malformed "attempted to reference field of non-object"
    end
  | Newobject newobj ->
    let vartyp = getVariableType newobj.id in
    let cls    = getClass newobj.classid in
    begin
      match vartyp with
      | Class typcls' ->
        let cls' = getClass typcls'.classid in
        checkClassMatch cls cls'
      | _ -> raise @@ Malformed "type mismatch in creating new object instance"
    end
  | Methodcall methcall ->
    let meth   = getMethod methcall.baseid methcall.methodid in
    let vartyp = getVariableType methcall.targetid in
    (* target variable type matches return type  *)
    checkTypeMatch meth.type_ vartyp;
    (* given argument count matches expected *)
    check (List.length meth.arguments = List.length methcall.arguments) @@
      Method_call_arguments_length_mismatch (meth, methcall);
    (* given arguments have correct types *)
    checkFold (fun ((arg,id):argument*id) -> checkTypeMatch arg.type_ (getVariableType id)) @@
      List.zip_exn meth.arguments methcall.arguments;
  | Assertion asrt ->
    checkFormula asrt.formula
  | Release rls ->
    checkFormula rls.formula
  | Hold hld ->
    checkFormula   hld.formula;
    checkStatement hld.holdbody
  | Fold fol ->
    (* TODO: predicate is used without base, but all predicates are defined in classes... *)
    let pred = getPredicate (unimplemented ()) fol.predicateid in
    (* given argument count matches expected *)
    check (List.length pred.arguments = List.length fol.arguments) @@
      Fold_arguments_length_mismatch (pred, fol);
    (* given arguments have correct types *)
    checkFold (fun ((arg,expr):argument*expression) -> checkTypeMatch arg.type_ (getExpressionType expr)) @@
      List.zip_exn pred.arguments fol.arguments
  | Unfold unfol ->
    (* TODO: predicate is used without base, but all predicates are defined in classes... *)
    let pred = getPredicate (unimplemented ()) unfol.predicateid in
    (* given argument count matches expected *)
    check (List.length pred.arguments = List.length unfol.arguments) @@
      Unfold_arguments_length_mismatch (pred, unfol);
    (* given arguments have correct types *)
    checkFold (fun ((arg,expr):argument*expression) -> checkTypeMatch arg.type_ (getExpressionType expr)) @@
      List.zip_exn pred.arguments unfol.arguments

(****************************************************************************************************************************)
(* check class *)

let rec checkPredicate : predicate -> unit =
  fun pred ->
  checkFormula pred.formula

let checkMethod : method_ -> unit =
  fun meth ->
  checkContract meth.dynamic;
  checkContract meth.static;
  checkStatement meth.methodbody

let rec checkClass : class_ -> unit =
  fun cls ->
  setClass cls.id cls;
  checkFold checkPredicate cls.predicates;
  checkFold checkMethod cls.methods

(****************************************************************************************************************************)
(* program *)

let checkProgram : program -> unit =
  fun prgm ->
  checkFold checkClass prgm.classes;
  checkStatement prgm.statement
