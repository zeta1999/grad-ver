(** ast.proto Types *)



(** {2 Types} *)

type id = {
  string : string;
}

type type_class = {
  classid : id;
}

type type_ =
  | Int
  | Class of type_class
  | Top

type class_field = {
  type_ : type_;
  id : id;
}

type argument = {
  type_ : type_;
  id : id;
}

type variable_old = {
  id : id;
}

type variable =
  | Result
  | Id of id
  | Old of variable_old
  | This

type value_int = {
  value : int32;
}

type value =
  | Int of value_int
  | Objectid of id
  | Null
  | True
  | False

type binary_operator =
  | Add 
  | Sub 
  | Mul 
  | Div 

type binary_comparer =
  | Neq 
  | Eq 
  | Lt 
  | Gt 
  | Le 
  | Ge 

type expression =
  | Variable of variable
  | Value of value
  | Binaryoperation of expression_binary_operation
  | Binarycomparison of expression_binary_comparison
  | Fieldreference of expression_field_reference

and expression_binary_operation = {
  binaryoperator : binary_operator;
  binaryoperationleft : expression;
  binaryoperationright : expression;
}

and expression_binary_comparison = {
  binarycomparer : binary_comparer;
  binarycomparisonleft : expression;
  binarycomparisonright : expression;
}

and expression_field_reference = {
  base : expression;
  fieldid : id;
}

type formula_concrete_predicate_check = {
  predicateid : id;
  arguments : expression list;
}

type formula_concrete_access_check = {
  base : expression;
  fieldid : id;
}

type formula_concrete =
  | Expression of expression
  | Predicatecheck of formula_concrete_predicate_check
  | Accesscheck of formula_concrete_access_check
  | Logicaland of formula_concrete_logical_and
  | Logicalseparate of formula_concrete_logical_separate
  | Ifthenelse of formula_concrete_if_then_else
  | Unfoldingin of formula_concrete_unfolding_in

and formula_concrete_logical_and = {
  andleft : formula_concrete;
  andright : formula_concrete;
}

and formula_concrete_logical_separate = {
  separateleft : formula_concrete;
  separateright : formula_concrete;
}

and formula_concrete_if_then_else = {
  condition : expression;
  thenformula : formula_concrete;
  elseformula : formula_concrete;
}

and formula_concrete_unfolding_in = {
  predicateid : id;
  arguments : expression list;
  formula : formula_concrete;
}

type formula_imprecise = {
  concrete : formula_concrete;
}

type formula =
  | Concrete of formula_concrete
  | Imprecise of formula_imprecise

type predicate = {
  id : id;
  arguments : argument list;
  formula : formula;
}

type contract = {
  requires : formula;
  ensures : formula;
}

type statement_declaration = {
  type_ : type_;
  id : id;
}

type statement_assignment = {
  id : id;
  value : expression;
}

type statement_field_assignment = {
  baseid : id;
  fieldid : id;
  sourceid : id;
}

type statement_new_object = {
  id : id;
  classid : id;
}

type statement_method_call = {
  targetid : id;
  baseid : id;
  methodid : id;
  arguments : id list;
}

type statement_assertion = {
  formula : formula;
}

type statement_release = {
  formula : formula;
}

type statement_fold = {
  predicateid : id;
  arguments : expression list;
}

type statement_unfold = {
  predicateid : id;
  arguments : expression list;
}

type statement =
  | Skip
  | Sequence of statement_sequence
  | Declaration of statement_declaration
  | Assignment of statement_assignment
  | Ifthenelse of statement_if_then_else
  | Whileloop of statement_while_loop
  | Fieldassignment of statement_field_assignment
  | Newobject of statement_new_object
  | Methodcall of statement_method_call
  | Assertion of statement_assertion
  | Release of statement_release
  | Hold of statement_hold
  | Fold of statement_fold
  | Unfold of statement_unfold

and statement_sequence = {
  prev : statement;
  next : statement;
}

and statement_if_then_else = {
  ifcondition : expression;
  thenbody : statement;
  elsebody : statement;
}

and statement_while_loop = {
  whilecondition : expression;
  invariant : formula;
  whilebody : statement;
}

and statement_hold = {
  formula : formula;
  holdbody : statement;
}

type method_ = {
  type_ : type_;
  id : id;
  arguments : argument list;
  dynamic : contract;
  static : contract;
  methodbody : statement;
}

type class_ = {
  id : id;
  superid : id;
  fields : class_field list;
  predicates : predicate list;
  methods : method_ list;
}

type program = {
  classes : class_ list;
  statement : statement;
}


(** {2 Default values} *)

val default_id : 
  ?string:string ->
  unit ->
  id
(** [default_id ()] is the default value for type [id] *)

val default_type_class : 
  ?classid:id ->
  unit ->
  type_class
(** [default_type_class ()] is the default value for type [type_class] *)

val default_type_ : unit -> type_
(** [default_type_ ()] is the default value for type [type_] *)

val default_class_field : 
  ?type_:type_ ->
  ?id:id ->
  unit ->
  class_field
(** [default_class_field ()] is the default value for type [class_field] *)

val default_argument : 
  ?type_:type_ ->
  ?id:id ->
  unit ->
  argument
(** [default_argument ()] is the default value for type [argument] *)

val default_variable_old : 
  ?id:id ->
  unit ->
  variable_old
(** [default_variable_old ()] is the default value for type [variable_old] *)

val default_variable : unit -> variable
(** [default_variable ()] is the default value for type [variable] *)

val default_value_int : 
  ?value:int32 ->
  unit ->
  value_int
(** [default_value_int ()] is the default value for type [value_int] *)

val default_value : unit -> value
(** [default_value ()] is the default value for type [value] *)

val default_binary_operator : unit -> binary_operator
(** [default_binary_operator ()] is the default value for type [binary_operator] *)

val default_binary_comparer : unit -> binary_comparer
(** [default_binary_comparer ()] is the default value for type [binary_comparer] *)

val default_expression : unit -> expression
(** [default_expression ()] is the default value for type [expression] *)

val default_expression_binary_operation : 
  ?binaryoperator:binary_operator ->
  ?binaryoperationleft:expression ->
  ?binaryoperationright:expression ->
  unit ->
  expression_binary_operation
(** [default_expression_binary_operation ()] is the default value for type [expression_binary_operation] *)

val default_expression_binary_comparison : 
  ?binarycomparer:binary_comparer ->
  ?binarycomparisonleft:expression ->
  ?binarycomparisonright:expression ->
  unit ->
  expression_binary_comparison
(** [default_expression_binary_comparison ()] is the default value for type [expression_binary_comparison] *)

val default_expression_field_reference : 
  ?base:expression ->
  ?fieldid:id ->
  unit ->
  expression_field_reference
(** [default_expression_field_reference ()] is the default value for type [expression_field_reference] *)

val default_formula_concrete_predicate_check : 
  ?predicateid:id ->
  ?arguments:expression list ->
  unit ->
  formula_concrete_predicate_check
(** [default_formula_concrete_predicate_check ()] is the default value for type [formula_concrete_predicate_check] *)

val default_formula_concrete_access_check : 
  ?base:expression ->
  ?fieldid:id ->
  unit ->
  formula_concrete_access_check
(** [default_formula_concrete_access_check ()] is the default value for type [formula_concrete_access_check] *)

val default_formula_concrete : unit -> formula_concrete
(** [default_formula_concrete ()] is the default value for type [formula_concrete] *)

val default_formula_concrete_logical_and : 
  ?andleft:formula_concrete ->
  ?andright:formula_concrete ->
  unit ->
  formula_concrete_logical_and
(** [default_formula_concrete_logical_and ()] is the default value for type [formula_concrete_logical_and] *)

val default_formula_concrete_logical_separate : 
  ?separateleft:formula_concrete ->
  ?separateright:formula_concrete ->
  unit ->
  formula_concrete_logical_separate
(** [default_formula_concrete_logical_separate ()] is the default value for type [formula_concrete_logical_separate] *)

val default_formula_concrete_if_then_else : 
  ?condition:expression ->
  ?thenformula:formula_concrete ->
  ?elseformula:formula_concrete ->
  unit ->
  formula_concrete_if_then_else
(** [default_formula_concrete_if_then_else ()] is the default value for type [formula_concrete_if_then_else] *)

val default_formula_concrete_unfolding_in : 
  ?predicateid:id ->
  ?arguments:expression list ->
  ?formula:formula_concrete ->
  unit ->
  formula_concrete_unfolding_in
(** [default_formula_concrete_unfolding_in ()] is the default value for type [formula_concrete_unfolding_in] *)

val default_formula_imprecise : 
  ?concrete:formula_concrete ->
  unit ->
  formula_imprecise
(** [default_formula_imprecise ()] is the default value for type [formula_imprecise] *)

val default_formula : unit -> formula
(** [default_formula ()] is the default value for type [formula] *)

val default_predicate : 
  ?id:id ->
  ?arguments:argument list ->
  ?formula:formula ->
  unit ->
  predicate
(** [default_predicate ()] is the default value for type [predicate] *)

val default_contract : 
  ?requires:formula ->
  ?ensures:formula ->
  unit ->
  contract
(** [default_contract ()] is the default value for type [contract] *)

val default_statement_declaration : 
  ?type_:type_ ->
  ?id:id ->
  unit ->
  statement_declaration
(** [default_statement_declaration ()] is the default value for type [statement_declaration] *)

val default_statement_assignment : 
  ?id:id ->
  ?value:expression ->
  unit ->
  statement_assignment
(** [default_statement_assignment ()] is the default value for type [statement_assignment] *)

val default_statement_field_assignment : 
  ?baseid:id ->
  ?fieldid:id ->
  ?sourceid:id ->
  unit ->
  statement_field_assignment
(** [default_statement_field_assignment ()] is the default value for type [statement_field_assignment] *)

val default_statement_new_object : 
  ?id:id ->
  ?classid:id ->
  unit ->
  statement_new_object
(** [default_statement_new_object ()] is the default value for type [statement_new_object] *)

val default_statement_method_call : 
  ?targetid:id ->
  ?baseid:id ->
  ?methodid:id ->
  ?arguments:id list ->
  unit ->
  statement_method_call
(** [default_statement_method_call ()] is the default value for type [statement_method_call] *)

val default_statement_assertion : 
  ?formula:formula ->
  unit ->
  statement_assertion
(** [default_statement_assertion ()] is the default value for type [statement_assertion] *)

val default_statement_release : 
  ?formula:formula ->
  unit ->
  statement_release
(** [default_statement_release ()] is the default value for type [statement_release] *)

val default_statement_fold : 
  ?predicateid:id ->
  ?arguments:expression list ->
  unit ->
  statement_fold
(** [default_statement_fold ()] is the default value for type [statement_fold] *)

val default_statement_unfold : 
  ?predicateid:id ->
  ?arguments:expression list ->
  unit ->
  statement_unfold
(** [default_statement_unfold ()] is the default value for type [statement_unfold] *)

val default_statement : unit -> statement
(** [default_statement ()] is the default value for type [statement] *)

val default_statement_sequence : 
  ?prev:statement ->
  ?next:statement ->
  unit ->
  statement_sequence
(** [default_statement_sequence ()] is the default value for type [statement_sequence] *)

val default_statement_if_then_else : 
  ?ifcondition:expression ->
  ?thenbody:statement ->
  ?elsebody:statement ->
  unit ->
  statement_if_then_else
(** [default_statement_if_then_else ()] is the default value for type [statement_if_then_else] *)

val default_statement_while_loop : 
  ?whilecondition:expression ->
  ?invariant:formula ->
  ?whilebody:statement ->
  unit ->
  statement_while_loop
(** [default_statement_while_loop ()] is the default value for type [statement_while_loop] *)

val default_statement_hold : 
  ?formula:formula ->
  ?holdbody:statement ->
  unit ->
  statement_hold
(** [default_statement_hold ()] is the default value for type [statement_hold] *)

val default_method_ : 
  ?type_:type_ ->
  ?id:id ->
  ?arguments:argument list ->
  ?dynamic:contract ->
  ?static:contract ->
  ?methodbody:statement ->
  unit ->
  method_
(** [default_method_ ()] is the default value for type [method_] *)

val default_class_ : 
  ?id:id ->
  ?superid:id ->
  ?fields:class_field list ->
  ?predicates:predicate list ->
  ?methods:method_ list ->
  unit ->
  class_
(** [default_class_ ()] is the default value for type [class_] *)

val default_program : 
  ?classes:class_ list ->
  ?statement:statement ->
  unit ->
  program
(** [default_program ()] is the default value for type [program] *)