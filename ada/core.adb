with Ada.Characters.Latin_1;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with Envs;
with Evaluation;
with Reader;
with Smart_Pointers;
with Types;

package body Core is

   use Types;

   -- primitive functions on Smart_Pointer,
   function "+" is new Arith_Op ("+", "+");
   function "-" is new Arith_Op ("-", "-");
   function "*" is new Arith_Op ("*", "*");
   function "/" is new Arith_Op ("/", "/");

   function "<" is new Rel_Op ("<", "<");
   function "<=" is new Rel_Op ("<=", "<=");
   function ">" is new Rel_Op (">", ">");
   function ">=" is new Rel_Op (">=", ">=");


   procedure Add_Defs (Defs : List_Mal_Type; Env : Envs.Env_Handle) is
      D, L : List_Mal_Type;
   begin
      if Evaluation.Debug then
         Ada.Text_IO.Put_Line ("Add_Defs " & To_String (Defs));
      end if;
      D := Defs;
      while not Is_Null (D) loop
         L := Deref_List (Cdr (D)).all;
         Envs.Set
           (Env,
            Deref_Atom (Car (D)).Get_Atom,
            Evaluation.Eval (Car (L), Env));
         D := Deref_List (Cdr(L)).all;
      end loop;
   end Add_Defs;


   function Eval_As_Boolean (MH : Types.Mal_Handle) return Boolean is
      use Types;
      Res : Boolean;
   begin
      case Deref (MH).Sym_Type is
         when Bool => 
            Res := Deref_Bool (MH).Get_Bool;
         when Atom =>
            return not (Deref_Atom (MH).Get_Atom = "nil");
--         when List =>
--            declare
--               L : List_Mal_Type;
--            begin
--               L := Deref_List (MH).all;
--               Res := not Is_Null (L);
--            end;
         when others => -- Everything else
            Res := True;
      end case;
      return Res;
   end Eval_As_Boolean;


   function Is_List (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      First_Param, Evaled_List : Mal_Handle;
      Rest_List : Types.List_Mal_Type;
   begin
      Rest_List := Deref_List (Rest_Handle).all;
      First_Param := Car (Rest_List);
      return New_Bool_Mal_Type
        (Deref (First_Param).Sym_Type = List and then
         Deref_List (First_Param).Get_List_Type = List_List);
   end Is_List;


   function Is_Empty (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      First_Param, Evaled_List : Mal_Handle;
      List : List_Mal_Type;
      Rest_List : Types.List_Mal_Type;
   begin
      Rest_List := Deref_List (Rest_Handle).all;
      First_Param := Car (Rest_List);
      List := Deref_List (First_Param).all;
      return New_Bool_Mal_Type (Is_Null (List));
   end Is_Empty;


   function Eval_As_List (MH : Types.Mal_Handle) return List_Mal_Type is
   begin
      case Deref (MH).Sym_Type is
         when List =>  return Deref_List (MH).all;
         when Atom =>
            if Deref_Atom (MH).Get_Atom = "nil" then
               return Null_List (List_List);
            end if;
         when others => null;
      end case;
      raise Evaluation.Evaluation_Error with "Expecting a List";
      return Null_List (List_List);
   end Eval_As_List;


   function Count (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      First_Param, Evaled_List : Mal_Handle;
      List : List_Mal_Type;
      Rest_List : Types.List_Mal_Type;
   begin
      Rest_List := Deref_List (Rest_Handle).all;
      First_Param := Car (Rest_List);
      List := Eval_As_List (First_Param);
      return New_Int_Mal_Type (Length (List));
   end Count;


   function New_List (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      Rest_List : Types.List_Mal_Type;
   begin
      Rest_List := Deref_List (Rest_Handle).all;
      return New_List_Mal_Type (The_List => Rest_List);
   end New_List;


   -- Take a list with two parameters and produce a single result
   -- using the Op access-to-function parameter.
   function Reduce2
     (Op : Binary_Func_Access; LH : Mal_Handle; Env : Envs.Env_Handle)
   return Mal_Handle is
      Left, Right : Mal_Handle;
      L, Rest_List : List_Mal_Type;
   begin
      L := Deref_List (LH).all;
      Left := Car (L);
      Rest_List := Deref_List (Cdr (L)).all;
      Right := Car (Rest_List);
      return Op (Left, Right);
   end Reduce2;


   function Plus (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
   begin
       return Reduce2 ("+"'Access, Rest_Handle, Env);
   end Plus;


   function Minus (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
   begin
       return Reduce2 ("-"'Access, Rest_Handle, Env);
   end Minus;


   function Mult (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
   begin
       return Reduce2 ("*"'Access, Rest_Handle, Env);
   end Mult;


   function Divide (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
   begin
       return Reduce2 ("/"'Access, Rest_Handle, Env);
   end Divide;


   function LT (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
   begin
       return Reduce2 ("<"'Access, Rest_Handle, Env);
   end LT;


   function LTE (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
   begin
       return Reduce2 ("<="'Access, Rest_Handle, Env);
   end LTE;


   function GT (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
   begin
       return Reduce2 (">"'Access, Rest_Handle, Env);
   end GT;


   function GTE (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
   begin
       return Reduce2 (">="'Access, Rest_Handle, Env);
   end GTE;


   function EQ (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
   begin
       return Reduce2 (Types."="'Access, Rest_Handle, Env);
   end EQ;


   function Pr_Str (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      use Ada.Strings.Unbounded;
      Res : Unbounded_String;
   begin
      return New_String_Mal_Type ('"' & Deref_List (Rest_Handle).Pr_Str & '"');
   end Pr_Str;


   function Prn (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      use Ada.Strings.Unbounded;
   begin
      Ada.Text_IO.Put_Line (Deref_List (Rest_Handle).Pr_Str);
      return New_Atom_Mal_Type ("nil");
   end Prn;


   function Println (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      use Ada.Strings.Unbounded;
      Res : String := Deref_List (Rest_Handle).Pr_Str (False);
   begin
      Ada.Text_IO.Put_Line (Res);
      return New_Atom_Mal_Type ("nil");
   end Println;


   function Str (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      use Ada.Strings.Unbounded;
      Res : String := Deref_List (Rest_Handle).Cat_Str (False);
   begin
      return New_String_Mal_Type ('"' & Res & '"');
   end Str;


   function Read_String (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      Rest_List : Types.List_Mal_Type;
      First_Param : Mal_Handle;
   begin
      Rest_List := Deref_List (Rest_Handle).all;
      First_Param := Car (Rest_List);
      declare
         Str_Param : String := Deref_String (First_Param).Get_String;
         Unquoted_Str : String(1 .. Str_Param'Length-2) :=
           Str_Param (Str_Param'First+1 .. Str_Param'Last-1);
         -- i.e. strip out the double-qoutes surrounding the string.
      begin
         return Reader.Read_Str (Unquoted_Str);
      end;
   end Read_String;


   function Slurp (Rest_Handle : Mal_Handle; Env : Envs.Env_Handle)
   return Types.Mal_Handle is
      Rest_List : Types.List_Mal_Type;
      First_Param : Mal_Handle;
   begin
      Rest_List := Deref_List (Rest_Handle).all;
      First_Param := Car (Rest_List);
      declare
         Str_Param : String := Deref_String (First_Param).Get_String;
         Unquoted_Str : String(1 .. Str_Param'Length-2) :=
           Str_Param (Str_Param'First+1 .. Str_Param'Last-1);
         -- i.e. strip out the double-qoutes surrounding the string.
         use Ada.Text_IO;
         Fn : Ada.Text_IO.File_Type;
         Line_Str : String (1..Reader.Max_Line_Len);
         File_Str : String (1..Reader.Max_Line_Len);
         Last : Natural;
         I : Natural := 0;
      begin
         Ada.Text_IO.Open (Fn, In_File, Unquoted_Str);
         while not End_Of_File (Fn) loop
            Get_Line (Fn, Line_Str, Last);
            if Last > 0 then
               File_Str (I+1 .. I+Last) := Line_Str (1 .. Last);
               I := I + Last;
               File_Str (I+1) := Ada.Characters.Latin_1.LF;
               I := I + 1;
            end if;
         end loop;
         Ada.Text_IO.Close (Fn);
         return New_String_Mal_Type ('"' & File_Str (1..I) & '"');
      end;
   end Slurp;


   procedure Init is
     use Envs;
   begin

      Envs.New_Env;

      Set (Get_Current, "true", Types.New_Bool_Mal_Type (True));
      Set (Get_Current, "false", Types.New_Bool_Mal_Type (False));
      Set (Get_Current, "nil", Types.New_Atom_Mal_Type ("nil"));

      Set (Get_Current,
           "list?",
           New_Func_Mal_Type ("list?", Is_List'access));

      Set (Get_Current,
           "empty?",
           New_Func_Mal_Type ("empty?", Is_Empty'access));

      Set (Get_Current,
           "count",
           New_Func_Mal_Type ("count", Count'access));

      Set (Get_Current,
           "list",
           New_Func_Mal_Type ("list", New_List'access));

      Set (Get_Current,
           "pr-str",
           New_Func_Mal_Type ("pr-str", Pr_Str'access));

      Set (Get_Current,
           "str",
           New_Func_Mal_Type ("str", Str'access));

      Set (Get_Current,
           "prn",
           New_Func_Mal_Type ("prn", Prn'access));

      Set (Get_Current,
           "println",
           New_Func_Mal_Type ("println", Println'access));

      Set (Get_Current,
           "eval",
           New_Func_Mal_Type ("eval", Evaluation.Eval'access));

      Set (Get_Current,
           "read-string",
           New_Func_Mal_Type ("read-string", Read_String'access));

      Set (Get_Current,
           "slurp",
           New_Func_Mal_Type ("slurp", Slurp'access));

      Set (Get_Current,
           "+",
           New_Func_Mal_Type ("+", Plus'access));

      Set (Get_Current,
           "-",
           New_Func_Mal_Type ("-", Minus'access));

      Set (Get_Current,
           "*",
           New_Func_Mal_Type ("*", Mult'access));

      Set (Get_Current,
           "/",
           New_Func_Mal_Type ("/", Divide'access));

      Set (Get_Current,
           "<",
           New_Func_Mal_Type ("<", LT'access));

      Set (Get_Current,
           "<=",
           New_Func_Mal_Type ("<=", LTE'access));

      Set (Get_Current,
           ">",
           New_Func_Mal_Type (">", GT'access));

      Set (Get_Current,
           ">=",
           New_Func_Mal_Type (">=", GTE'access));

      Set (Get_Current,
           "=",
           New_Func_Mal_Type ("=", EQ'access));

   end Init;


end Core;
