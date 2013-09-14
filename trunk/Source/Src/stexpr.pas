{*********************************************************}
{* SysTools: StExpr.pas 3.03                             *}
{* Copyright (c) TurboPower Software Co 1996, 2001       *}
{* All rights reserved.                                  *}
{*********************************************************}
{* SysTools: Expression evaluator component              *}
{*********************************************************}

{$I StDefine.inc}

{$IFDEF WIN16}
  {$C MOVEABLE,DEMANDLOAD,DISCARDABLE}
{$ENDIF}

unit StExpr;

interface

uses
  {$IFDEF MSWINDOWS}
  Windows,
  {$ENDIF}
  {$IFDEF WIN16}
  WinTypes, WinProcs,
  {$ENDIF}
  Classes, Controls, Messages, StdCtrls, SysUtils,
  {$IFDEF UseMathUnit} Math, {$ENDIF}
  StBase, StConst, StMath,Variants;

type
  {TStFloat = Double;}  {TStFloat is defined in StBase}
  {.Z+}
  PStFloat = ^Variant;
  {.Z-}

type
  {user-defined functions with up to 3 parameters}
  TStFunction0Param =
    function : Variant;
  TStFunction1Param =
    function(Value1 : Variant) : Variant;
  TStFunction2Param =
    function(Value1, Value2 : Variant) : Variant;
  TStFunction3Param =
    function(Value1, Value2, Value3 : Variant) : Variant;
  TStFunction4Param =
    function(Value1, Value2, Value3, Value4 : Variant) : Variant;

  {user-defined methods with up to 3 parameters}
  TStMethod0Param =
    function : Variant
    of object;

  TStMethod1Param =
    function(Value1 : Variant) : Variant
    of object;

  TStMethod2Param =
    function(Value1, Value2 : Variant) : Variant
    of object;

  TStMethod3Param =
    function(Value1, Value2, Value3 : Variant) : Variant
    of object;
  TStMethod4Param =
    function(Value1, Value2, Value3, Value4 : Variant) : Variant
    of object;

  TStGetIdentValueEvent =
//[NXHop sua]      procedure(Sender : TObject; const Identifier : string; var Value : TStFloat)
   procedure(Sender : TObject; const Identifier : string; var Value : Variant)
   of object;

  {.Z+}
  {tokens}
  TStToken = (
    ssStart, ssInIdent, ssInNum, ssInSign, ssInExp, ssEol, ssNum, ssIdent,
    ssLPar, ssRPar, ssComma, ssPlus, ssMinus, ssTimes, ssDiv, ssEqual, ssPower);

const
  StExprOperators : array[ssLPar..ssPower] of Char = '(),+-*/=^';
  {.Z-}

type
  TStExpression = class(TStComponent)
  {.Z+}
  protected {private}
    {property variables}
    FAllowEqual      : Boolean;
    FLastError       : Integer;
    FErrorPos        : Integer;
    FExpression      : string;

    {event variables}
    FOnAddIdentifier : TNotifyEvent;
    FOnGetIdentValue : TStGetIdentValueEvent;

    {internal variables}
    eBusyFlag        : Boolean;
    eCurChar         : Char;
    eExprPos         : Integer;
    eIdentList       : TList;
    eStack           : TList;
    eToken           : TStToken;
    eTokenStr        : string;
    lhs, rhs         : Variant; 

    {property methods}
    function GetAsInteger : Integer;
    function GetAsString : string;

    {ident list routines}
    function FindIdent(Name : string) : Integer;

    {stack routines}
    procedure StackClear;
    function StackCount : Integer;
//[NXHop sua]      procedure StackPush(const Value : TStFloat);
    procedure StackPush(const Value : Variant);
    function StackPeek : Variant;
//[NXHop sua]      function StackPop : TStFloat;
    function StackPop : Variant;
    function StackEmpty : Boolean;

    procedure DoOnAddIdentifier;
    procedure GetBase;
      {-base: unsigned_num | (expression) | sign factor | func_call }
    procedure GetExpression;
      {-expression: term | expression+term | expression-term implemented as loop}
    procedure GetFactor;
      {-factor: base | base^factor}
    procedure GetFunction;
      {-func_call: identifier | identifier(params)}
    procedure GetParams(N : Integer);
      {-params: expression | params,expression}
    procedure GetTerm;
      {-term: factor | term*factor | term/factor implemented as loop}
    procedure GetToken;
      {-return the next token string in eTokenStr and type in eToken}
    function PopOperand : Variant;
      {-remove top operand value from stack}
    procedure RaiseExprError(Code : LongInt; Column : Integer);
      {-generate an expression exception}

  public
    constructor Create(AOwner : TComponent);
      override;
    destructor Destroy;
      override;
  {.Z-}

    function AnalyzeExpression : Variant;
    procedure AddConstant(const Name : string; Value : Variant);
    procedure AddFunction0Param(const Name : string; FunctionAddr : TStFunction0Param);
    procedure AddFunction1Param(const Name : string; FunctionAddr : TStFunction1Param);
    procedure AddFunction2Param(const Name : string; FunctionAddr : TStFunction2Param);
    procedure AddFunction3Param(const Name : string; FunctionAddr : TStFunction3Param);
    procedure AddFunction4Param(const Name : string;
          FunctionAddr : TStFunction4Param);
    procedure AddInternalFunctions;
    procedure AddMethod0Param(const Name : string; MethodAddr : TStMethod0Param);
    procedure AddMethod1Param(const Name : string; MethodAddr : TStMethod1Param);
    procedure AddMethod2Param(const Name : string; MethodAddr : TStMethod2Param);
    procedure AddMethod3Param(const Name : string; MethodAddr : TStMethod3Param);
    procedure AddMethod4Param(const Name : string;
          MethodAddr : TStMethod4Param);
    procedure AddVariable(const Name : string; VariableAddr : PStFloat);
    procedure ClearIdentifiers;
    procedure GetIdentList(S : TStrings);
    procedure RemoveIdentifier(const Name : string);
    function GetFloat : TstFloat;
    {public properties}
    property AsInteger : Integer
      read GetAsInteger;
    property AsFloat : TstFloat
      read GetFloat;
    property AsString : string
      read GetAsString;
    property ErrorPosition : Integer
      read FErrorPos;
    property Expression : string
      read FExpression write FExpression;
    property LastError : Integer
      read FLastError;

  published
    property AllowEqual : Boolean
      read FAllowEqual write FAllowEqual default True;

    property OnAddIdentifier : TNotifyEvent
      read FOnAddIdentifier write FOnAddIdentifier;
    property OnGetIdentValue : TStGetIdentValueEvent                   
      read FOnGetIdentValue write FOnGetIdentValue;
  end;


type
  TStExprErrorEvent =
    procedure(Sender : TObject; ErrorNumber : LongInt; const ErrorStr : string)
    of object;

type
  TStExpressionEdit = class(TEdit)
  {.Z+}
  protected {private}
    {property variables}
    FAutoEval : Boolean;
    FExpr     : TStExpression;
    FOnError  : TStExprErrorEvent;

    {property methods}
    function GetOnAddIdentifier : TNotifyEvent;
    function GetOnGetIdentValue : TStGetIdentValueEvent;
    procedure SetOnAddIdentifier(Value : TNotifyEvent);
    procedure SetOnGetIdentValue(Value : TStGetIdentValueEvent);

    {VCL control methods}
    procedure CMExit(var Msg : TMessage);
      message CM_EXIT;
    procedure DoEvaluate;
  {.Z-}

  protected
    procedure KeyPress(var Key: Char);
      override;

  public
    constructor Create(AOwner : TComponent);
      override;
    destructor Destroy;
      override;

    function Evaluate : Variant;

    property Expr : TStExpression
      read FExpr;

  published
    property AutoEval : Boolean
      read FAutoEval write FAutoEval;

    property OnAddIdentifier : TNotifyEvent
      read GetOnAddIdentifier write SetOnAddIdentifier;
    property OnError : TStExprErrorEvent
      read FOnError write FOnError;
    property OnGetIdentValue : TStGetIdentValueEvent                   
      read GetOnGetIdentValue write SetOnGetIdentValue;
  end;

function AnalyzeExpr(const Expr : string) : Double;
  {-Compute the arithmetic expression Expr and return the result}

{!!.03 -- added }
procedure TpVal(const S : string; var V : Extended; var Code : Integer);
{
Evaluate string as a floating point number, emulates Borlandish Pascal's
Val() intrinsic
}


implementation

{$IFDEF TRIALRUN}
uses
  {$IFDEF MSWINDOWS}
  Registry,
  {$ENDIF}
  {$IFDEF WIN16}
  Ver,
  {$ENDIF}
  Forms,
  IniFiles,
  ShellAPI,
  StTrial, Variants;
{$I TRIAL00.INC} {FIX}
{$I TRIAL01.INC} {CAB}
{$I TRIAL02.INC} {CC}
{$I TRIAL03.INC} {VC}
{$I TRIAL04.INC} {TCC}
{$I TRIAL05.INC} {TVC}
{$I TRIAL06.INC} {TCCVC}
{$ENDIF}

const
  Alpha = ['A'..'Z', 'a'..'z', '_'];
  Numeric = ['0'..'9', '.'];
  AlphaNumeric = Alpha + ['0'..'9'];

type
  PStIdentRec = ^TStIdentRec;
  {a double-variant record - wow - confusing maybe, but it saves space}
  TStIdentRec = record
    Name     : string;
    Kind     : (ikConstant, ikVariable, ikFunction, ikMethod);
    case Byte of
      0 : (Value : TStFloat);
      1 : (VarAddr : PStFloat);
      2 : (PCount : Integer;
           case Byte of
             0 : (Func0Addr : TStFunction0Param);
             1 : (Func1Addr : TStFunction1Param);
             2 : (Func2Addr : TStFunction2Param);
             3 : (Func3Addr : TStFunction3Param);
             4 : (Func4Addr : TStFunction4Param);
             {
             4 : (Meth0Addr : TStMethod0Param);
             5 : (Meth1Addr : TStMethod1Param);
             6 : (Meth2Addr : TStMethod2Param);
             7 : (Meth3Addr : TStMethod3Param);
             }
             5 : (Meth0Addr : TStMethod0Param);
             6 : (Meth1Addr : TStMethod1Param);
             7 : (Meth2Addr : TStMethod2Param);
             8 : (Meth3Addr : TStMethod3Param);
             9 : (Meth4Addr : TStMethod4Param);


          )
  end;


{routine for backward compatibility}

function AnalyzeExpr(const Expr : string) : Double;
begin
  with TStExpression.Create(nil) do
    try
      Expression := Expr;
      Result := AnalyzeExpression;
    finally
      Free;
    end;
end;


{*** function definitions ***}

function _Abs(Value : Variant) : TStFloat; far;
begin
  Result := Abs(Extended(Value));
end;

function _ArcTan(Value : Variant) : TStFloat; far;
begin
  Result := ArcTan(Extended(Value));
end;

function _Cos(Value : Variant) : TStFloat; far;
begin
  Result := Cos(Extended(Value));
end;

function _Exp(Value : Variant) : TStFloat; far;
begin
  Result := Exp(Extended(Value));
end;

function _Frac(Value : Variant) : TStFloat; far;
begin
  Result := Frac(Extended(Value));
end;

function _Int(Value : Variant) : TStFloat; far;
begin
  Result := Int(Extended(Value));
end;

function _Trunc(Value : Variant) : TStFloat; far;
begin
  Result := Trunc(Extended(Value));
end;

function _Ln(Value : Variant) : TStFloat; far;
begin
  Result := Ln(Extended(Value));
end;

function _Pi : TStFloat; far;
begin
  Result := Pi;
end;

function _Round(Value : Variant) : TStFloat; far;
begin
  Result := Round(Extended(Value));
end;

function _Sin(Value : Variant) : TStFloat; far;
begin
  Result := Sin(Extended(Value));
end;

function _Sqr(Value : Variant) : TStFloat; far;
begin
  Result := Sqr(Extended(Value));
end;

function _Sqrt(Value : Variant) : TStFloat; far;
begin
  Result := Sqrt(Extended(Value));
end;

{$IFDEF UseMathUnit}
function _ArcCos(Value : Variant) : TStFloat; far;
begin
  Result := ArcCos(Extended(Value));
end;

function _ArcSin(Value : Variant) : TStFloat; far;
begin
  Result := ArcSin(Extended(Value));
end;

function _ArcTan2(Value1, Value2 : Variant) : TStFloat; far;
begin
  Result := ArcTan2(Extended(Value1), Extended(Value2));
end;

function _Tan(Value : Variant) : TStFloat; far;
begin
  Result := Tan(Extended(Value));
end;

function _Cotan(Value : Variant) : TStFloat; far;
begin
  Result := CoTan(Extended(Value));
end;

function _Hypot(Value1, Value2 : Variant) : TStFloat; far;
begin
  Result := Hypot(Extended(Value1),Extended(Value2));
end;

function _Cosh(Value : Variant) : TStFloat; far;
begin
  Result := Cosh(Extended(Value));
end;

function _Sinh(Value : Variant) : TStFloat; far;
begin
  Result := Sinh(Extended(Value));
end;

function _Tanh(Value : Variant) : TStFloat; far;
begin
  Result := Tanh(Extended(Value));
end;

function _ArcCosh(Value : Variant) : TStFloat; far;
begin
  Result := ArcCosh(Extended(Value));
end;

function _ArcSinh(Value : Variant) : TStFloat; far;
begin
  Result := ArcSinh(Extended(Value));
end;

function _ArcTanh(Value : Variant) : TStFloat; far;
begin
  Result := ArcTanh(Extended(Value));
end;

function _Lnxp1(Value : Variant) : TStFloat; far;
begin
  Result := Lnxp1(Extended(Value));
end;

function _Log10(Value : Variant) : TStFloat; far;
begin
  Result := Log10(Extended(Value));
end;

function _Log2(Value : Variant) : TStFloat; far;
begin
  Result := Log2(Extended(Value));
end;

function _LogN(Value1, Value2 : Variant) : TStFloat; far;
begin
  Result := LogN(Extended(Value1), Extended(Value2));
end;

function _Ceil(Value : Variant) : TStFloat; far;
begin
  Result := Ceil(Extended(Value));
end;

function _Floor(Value : Variant) : TStFloat; far;
begin
  Result := Floor(Extended(Value));
end;
{$ENDIF}


{*** TStExpression ***}

procedure TStExpression.AddConstant(const Name : string; Value : Variant);
var
  IR : PStIdentRec;
begin
  if FindIdent(Name) > -1 then
    RaiseExprError(stscExprDupIdent, 0);

  New(IR);
  IR^.Name := LowerCase(Name);
  IR^.Kind := ikConstant;
  IR^.Value := Value;
  eIdentList.Add(IR);

  DoOnAddIdentifier;
end;

procedure TStExpression.AddFunction0Param(const Name : string;
          FunctionAddr : TStFunction0Param);
var
  IR : PStIdentRec;
begin
  if FindIdent(Name) > -1 then
    RaiseExprError(stscExprDupIdent, 0);

  New(IR);
  IR^.Name := LowerCase(Name);
  IR^.PCount := 0;
  IR^.Kind := ikFunction;
  IR^.Func0Addr := FunctionAddr;
  eIdentList.Add(IR);

  DoOnAddIdentifier;
end;

procedure TStExpression.AddFunction1Param(const Name : string;
          FunctionAddr : TStFunction1Param);
var
  IR : PStIdentRec;
begin
  if FindIdent(Name) > -1 then
    RaiseExprError(stscExprDupIdent, 0);

  New(IR);
  IR^.Name := LowerCase(Name);
  IR^.PCount := 1;
  IR^.Kind := ikFunction;
  IR^.Func1Addr := FunctionAddr;
  eIdentList.Add(IR);

  DoOnAddIdentifier;
end;

procedure TStExpression.AddFunction2Param(const Name : string;
          FunctionAddr : TStFunction2Param);
var
  IR : PStIdentRec;
begin
  if FindIdent(Name) > -1 then
    RaiseExprError(stscExprDupIdent, 0);

  New(IR);
  IR^.Name := LowerCase(Name);
  IR^.PCount := 2;
  IR^.Kind := ikFunction;
  IR^.Func2Addr := FunctionAddr;
  eIdentList.Add(IR);

  DoOnAddIdentifier;
end;

procedure TStExpression.AddFunction3Param(const Name : string;
          FunctionAddr : TStFunction3Param);
var
  IR : PStIdentRec;
begin
  if FindIdent(Name) > -1 then
    RaiseExprError(stscExprDupIdent, 0);

  New(IR);
  IR^.Name := LowerCase(Name);
  IR^.PCount := 3;
  IR^.Kind := ikFunction;
  IR^.Func3Addr := FunctionAddr;
  eIdentList.Add(IR);

  DoOnAddIdentifier;
end;

procedure TStExpression.AddFunction4Param(const Name : string;
          FunctionAddr : TStFunction4Param);
var
  IR : PStIdentRec;
begin
  if FindIdent(Name) > -1 then
    RaiseExprError(stscExprDupIdent, 0);

  New(IR);
  IR^.Name := LowerCase(Name);
  IR^.PCount := 4;
  IR^.Kind := ikFunction;
  IR^.Func4Addr := FunctionAddr;
  eIdentList.Add(IR);

  DoOnAddIdentifier;
end;

procedure TStExpression.AddInternalFunctions;
begin
  eBusyFlag := True;
  try
    {add function name and parameter count to list}
{
    AddFunction1Param('abs',     _Abs);
    AddFunction1Param('arctan',  _ArcTan);
    AddFunction1Param('cos',     _Cos);
    AddFunction1Param('exp',     _Exp);
    AddFunction1Param('frac',    _Frac);
    AddFunction1Param('int',     _Int);
    AddFunction1Param('trunc',   _Trunc);
    AddFunction1Param('ln',      _Ln);
    AddFunction0Param('pi',      _Pi);
    AddFunction1Param('round',   _Round);
    AddFunction1Param('sin',     _Sin);
    AddFunction1Param('sqr',     _Sqr);
    AddFunction1Param('sqrt',    _Sqrt);
    {$IFDEF UseMathUnit}
{    AddFunction1Param('arccos',  _ArcCos);
    AddFunction1Param('arcsin',  _ArcSin);
    AddFunction2Param('arctan2', _ArcTan2);
    AddFunction1Param('tan',     _Tan);
    AddFunction1Param('cotan',   _Cotan);
    AddFunction2Param('hypot',   _Hypot);
    AddFunction1Param('cosh',    _Cosh);
    AddFunction1Param('sinh',    _Sinh);
    AddFunction1Param('tanh',    _Tanh);
    AddFunction1Param('arccosh', _ArcCosh);
    AddFunction1Param('arcsinh', _ArcSinh);
    AddFunction1Param('arctanh', _ArcTanh);
    AddFunction1Param('lnxp1',   _Lnxp1);
    AddFunction1Param('log10',   _Log10);
    AddFunction1Param('log2',    _Log2);
    AddFunction2Param('logn',    _LogN);
    AddFunction1Param('ceil',    _Ceil);
    AddFunction1Param('floor',   _Floor);
    {$ENDIF}
  finally
    eBusyFlag := False;
  end;
end;

procedure TStExpression.AddMethod0Param(const Name : string;
          MethodAddr : TStMethod0Param);
var
  IR : PStIdentRec;
begin
  if FindIdent(Name) > -1 then
    RaiseExprError(stscExprDupIdent, 0);

  New(IR);
  IR^.Name := LowerCase(Name);
  IR^.PCount := 0;
  IR^.Kind := ikMethod;
  IR^.Meth0Addr := MethodAddr;
  eIdentList.Add(IR);

  DoOnAddIdentifier;
end;

procedure TStExpression.AddMethod1Param(const Name : string;
          MethodAddr : TStMethod1Param);
var
  IR : PStIdentRec;
begin
  if FindIdent(Name) > -1 then
    RaiseExprError(stscExprDupIdent, 0);

  New(IR);
  IR^.Name := LowerCase(Name);
  IR^.PCount := 1;
  IR^.Kind := ikMethod;
  IR^.Meth1Addr := MethodAddr;
  eIdentList.Add(IR);

  DoOnAddIdentifier;
end;

procedure TStExpression.AddMethod2Param(const Name : string;
          MethodAddr : TStMethod2Param);
var
  IR : PStIdentRec;
begin
  if FindIdent(Name) > -1 then
    RaiseExprError(stscExprDupIdent, 0);

  New(IR);
  IR^.Name := LowerCase(Name);
  IR^.PCount := 2;
  IR^.Kind := ikMethod;
  IR^.Meth2Addr := MethodAddr;
  eIdentList.Add(IR);

  DoOnAddIdentifier;
end;

procedure TStExpression.AddMethod3Param(const Name : string;
          MethodAddr : TStMethod3Param);
var
  IR : PStIdentRec;
begin
  if FindIdent(Name) > -1 then
    RaiseExprError(stscExprDupIdent, 0);

  New(IR);
  IR^.Name := LowerCase(Name);
  IR^.PCount := 3;
  IR^.Kind := ikMethod;
  IR^.Meth3Addr := MethodAddr;
  eIdentList.Add(IR);

  DoOnAddIdentifier;
end;

procedure TStExpression.AddMethod4Param(const Name : string;
          MethodAddr : TStMethod4Param);
var
  IR : PStIdentRec;
begin
  if FindIdent(Name) > -1 then
    RaiseExprError(stscExprDupIdent, 0);

  New(IR);
  IR^.Name := LowerCase(Name);
  IR^.PCount := 4;
  IR^.Kind := ikMethod;
  IR^.Meth4Addr := MethodAddr;
  eIdentList.Add(IR);

  DoOnAddIdentifier;
end;

procedure TStExpression.AddVariable(const Name : string; VariableAddr : PStFloat);
var
  IR : PStIdentRec;
begin
  if FindIdent(Name) > -1 then
    RaiseExprError(stscExprDupIdent, 0);

  New(IR);
  IR^.Name := LowerCase(Name);
  IR^.Kind := ikVariable;
  IR^.VarAddr := VariableAddr;
  eIdentList.Add(IR);

  DoOnAddIdentifier;
end;

function TStExpression.AnalyzeExpression : Variant;
begin
  {$IFDEF TRIALRUN} TCCVC; {$ENDIF}
  FLastError := 0;

  {error if nothing to do}
  if (Length(FExpression) = 0) then
    RaiseExprError(stscExprEmpty, 0);

  {clear operand stack}
  StackClear;

  {get the first character from the string}
  eExprPos := 1;
  eCurChar := FExpression[1];

  {get the first Token and start parsing}
  GetToken;
  GetExpression;

  {make sure expression is fully evaluated}
  if (eToken <> ssEol) or (StackCount <> 1) then
    RaiseExprError(stscExprBadExp, FErrorPos);

  Result := StackPop;
end;

procedure TStExpression.ClearIdentifiers;
var
  I : Integer;
begin
  for I := 0 to eIdentList.Count-1 do
    Dispose(PStIdentRec(eIdentList[I]));
  eIdentList.Clear;
end;

constructor TStExpression.Create(AOwner : TComponent);
begin
  {$IFDEF TRIALRUN} TCCVC; {$ENDIF}
  inherited Create(AOwner);

  eStack := TList.Create;
  eIdentList := TList.Create;

  FAllowEqual := True;

  AddInternalFunctions;
end;

destructor TStExpression.Destroy;
begin
  StackClear;
  eStack.Free;
  eStack := nil;

  ClearIdentifiers;
  eIdentList.Free;
  eIdentList := nil;

  inherited Destroy;
end;

procedure TStExpression.DoOnAddIdentifier;
begin
  if eBusyFlag then
    Exit;
  if Assigned(FOnAddIdentifier) then
    FOnAddIdentifier(Self);
end;

function TStExpression.FindIdent(Name : string) : Integer;
var
  I : Integer;
begin
  Result := -1;
  for I := 0 to eIdentList.Count-1 do begin
    if Name = PStIdentRec(eIdentList[I])^.Name then begin
      Result := I;
      Break;
    end;
  end;
end;

function TStExpression.GetAsInteger : Integer;
begin
  {$IFDEF TRIALRUN} TCCVC; {$ENDIF}
  Result := Round(AnalyzeExpression);
end;

function TStExpression.GetAsString : string;
begin
  Result := VarToStrDef(AnalyzeExpression,'');
end;

{!!.03 -- Added }
procedure TpVal(const S : string; var V : Extended; var Code : Integer);
{
Evaluate string as a floating point number, emulates Borlandish Pascal's
Val() intrinsic

Recognizes strings of the form:
[-/+](d*[.][d*]|[d*].d*)[(e|E)[-/+](d*)]

Parameters:
  S : string to convert
  V : Resultant Extended value
  Code: position in string where an error occured or
   --  0 if no error
   --  Length(S) + 1 if otherwise valid string terminates prematurely (e.g. "10.2e-")

  if Code <> 0 on return then the value of V is undefined
}

type
  { recognizer machine states }
  TNumConvertState = (ncStart, ncSign, ncWhole, ncDecimal, ncStartDecimal,
    ncFraction, ncE, ncExpSign, ncExponent, ncEndSpaces, ncBadChar);
const
  { valid stop states for machine }
  StopStates: set of TNumConvertState = [ncWhole, ncDecimal, ncFraction,
    ncExponent, ncEndSpaces];

var
  i        : Integer;        { general purpose counter }
  P        : PChar;          { current position in evaluated string }
  NegVal   : Boolean;        { is entire value negative? }
  NegExp   : Boolean;        { is exponent negative? }
  Exponent : LongInt;        { accumulator for exponent }
  Mantissa : Extended;       { mantissa }
  FracMul  : Extended;       { decimal place holder }
  State : TNumConvertState;  { current state of recognizer machine }


begin
{initializations}
  V := 0.0;
  Code := 0;

  State := ncStart;

  NegVal := False;
  NegExp := False;

  Mantissa := 0.0;
  FracMul  := 0.1;
  Exponent := 0;

{
Evaluate the string
When the loop completes (assuming no error)
  -- WholeVal will contain the absolute value of the mantissa
  -- Exponent will contain the absolute value of the exponent
  -- NegVal will be set True if the mantissa is negative
  -- NegExp will be set True if the exponent is negative

If an error occurs P will be pointing at the character that caused the problem,
or one past the end of the string if it terminates prematurely
}

  { keep going until run out of string or halt if unrecognized or out-of-place
    character detected }

{$IFDEF MSWINDOWS}
  P := PChar(S);
{$ENDIF}
{$IFDEF WIN16}
  GetMem(P, Length(S));
  StrPCopy(P, S);
{$ENDIF}
  for i := 1 to Length(S) do begin
(*****)
  case State of
    ncStart : begin
      if P^ = DecimalSeparator then begin
        State := ncStartDecimal;   { decimal point detected in mantissa }
      end else

      case P^ of
        ' ': begin
          {ignore}
        end;

        '+': begin
          State := ncSign;
        end;

        '-': begin
          NegVal := True;
          State := ncSign;
        end;

        'e', 'E': begin
          Mantissa := 0;
          State := ncE;     { exponent detected }
        end;

        '0'..'9': begin
          State := ncWhole;    { start of whole portion of mantissa }
          Mantissa := (Mantissa * 10) + (Ord(P^) - Ord('0'));
        end;

        else
          State := ncBadChar;
      end;

    end;

    ncSign : begin
      if P^ = DecimalSeparator then begin
        State := ncDecimal;   { decimal point detected in mantissa }
      end else

      case P^ of
        '0'..'9': begin
          State := ncWhole;    { start of whole portion of mantissa }
          Mantissa := (Mantissa * 10) + (Ord(P^) - Ord('0'));
        end;

        'e', 'E': begin
          Mantissa := 0;
          State := ncE;     { exponent detected }
        end;

        else
          State := ncBadChar;
      end;
    end;

    ncWhole : begin
      if P^ = DecimalSeparator then begin
        State := ncDecimal;   { decimal point detected in mantissa }
      end else

      case P^ of
        '0'..'9': begin
          Mantissa := (Mantissa * 10) + (Ord(P^) - Ord('0'));
        end;

        '.': begin
        end;

        'e', 'E': begin
          State := ncE;     { exponent detected }
        end;

        ' ': begin
          State := ncEndSpaces;
        end;

        else
          State := ncBadChar;
      end;
    end;

    ncDecimal : begin
      case P^ of
        '0'..'9': begin
          State := ncFraction; { start of fractional portion of mantissa }
          Mantissa := Mantissa + (FracMul * (Ord(P^) - Ord('0')));
          FracMul := FracMul * 0.1;
        end;

        'e', 'E': begin
          State := ncE;     { exponent detected }
        end;

        ' ': begin
          State := ncEndSpaces;
        end;

        else
          State := ncBadChar;
      end;

    end;

    ncStartDecimal : begin
      case P^ of
        '0'..'9': begin
          State := ncFraction; { start of fractional portion of mantissa }
          Mantissa := Mantissa + (FracMul * (Ord(P^) - Ord('0')));
          FracMul := FracMul * 0.1;
        end;

        ' ': begin
          State := ncEndSpaces;
        end;

        else
          State := ncBadChar;
      end;
    end;

    ncFraction : begin
      case P^ of
        '0'..'9': begin
          Mantissa := Mantissa + (FracMul * (Ord(P^) - Ord('0')));
          FracMul := FracMul * 0.1;
        end;

        'e', 'E': begin
          State := ncE;     { exponent detected }
        end;

        ' ': begin
          State := ncEndSpaces;
        end;

        else
          State := ncBadChar;
      end;
    end;

    ncE : begin
      case P^ of
        '0'..'9': begin
          State := ncExponent;  { start of exponent }
          Exponent := Exponent * 10 + (Ord(P^) - Ord('0'));
        end;

        '+': begin
          State := ncExpSign;
        end;

        '-': begin
          NegExp := True;   { exponent is negative }
          State := ncExpSign;
        end;

        else
          State := ncBadChar;
      end;
    end;

    ncExpSign : begin
      case P^ of
        '0'..'9': begin
          State := ncExponent;  { start of exponent }
          Exponent := Exponent * 10 + (Ord(P^) - Ord('0'));
        end;

        else
          State := ncBadChar;
      end;
    end;

    ncExponent : begin
      case P^ of
        '0'..'9': begin
          Exponent := Exponent * 10 + (Ord(P^) - Ord('0'));
        end;

        ' ': begin
          State := ncEndSpaces;
        end;

        else
          State := ncBadChar;
      end;
    end;

    ncEndSpaces : begin
      case P^ of
        ' ': begin
          {ignore}
        end;
        else
          State := ncBadChar;
      end;
    end;
  end;

(*****)
    Inc(P);
    if State = ncBadChar then begin
      Code := i;
      Break;
    end;
  end;
{
Final calculations
}
  if not (State in StopStates) then begin
      Code := i;  { point to error }
  end else begin
    { negate if needed }
    if NegVal then
      Mantissa := -Mantissa;


    { apply exponent if any }
    if Exponent <> 0 then begin
      if NegExp then
        for i := 1 to Exponent do
          Mantissa := Mantissa * 0.1
      else
        for i := 1 to Exponent do
          Mantissa := Mantissa * 10.0;
    end;

    V := Mantissa;
  end;
end;


procedure TStExpression.GetBase;
var
  SaveSign : TStToken;
  Code     : Integer;
  NumVal   : TStFloat;
begin
  case eToken of
    ssNum :
      begin
        {evaluate real number string}
        if (eTokenStr[1] = '.') then
          {allow leading '.'. Delphi 1 may need this help}
          eTokenStr := '0' + eTokenStr;
        {Val(eTokenStr, NumVal, Code);}                                  {!!.03}
        TpVal(eTokenStr, NumVal, Code);                                  {!!.03}
        if Code <> 0 then
          RaiseExprError(stscExprBadNum, FErrorPos);
        {put on operand stack}
        StackPush(NumVal);
        GetToken;
      end;
    ssIdent :
      {function call}
      GetFunction;
    ssLPar :
      begin
        {nested expression}
        GetToken;
        GetExpression;
        if (eToken <> ssRPar) then
          RaiseExprError(stscExprBadExp, FErrorPos);
        GetToken;
      end;
    ssPlus, ssMinus :
      begin
        {unary sign}
        SaveSign := eToken;
        GetToken;
        GetFactor;
        if (SaveSign = ssMinus) then
          {update operand stack}
          StackPush(-PopOperand);
      end;
  else
    RaiseExprError(stscExprOpndExp, FErrorPos);
  end;
end;

procedure TStExpression.GetExpression;
var
  SaveOp : TStToken;
begin
  GetTerm;
  while (True) do begin
    case eToken of
      ssPlus, ssMinus :
        begin
          SaveOp := eToken;
          GetToken;
          GetTerm;
          rhs := PopOperand;
          lhs := PopOperand;
          try
            case SaveOp of
              ssPlus  : StackPush(lhs+rhs);
              ssMinus : StackPush(lhs-rhs);
            end;
          except
            {note operand stack overflow not possible here}
            RaiseExprError(stscExprNumeric, FErrorPos);
          end;
        end;
    else
      Break;
    end;
  end;
end;

procedure TStExpression.GetFactor;
begin
  GetBase;
  if (eToken = ssPower) then begin
    GetToken;
    GetFactor;
    rhs := PopOperand;
    lhs := PopOperand;
    try
      StackPush(Power(lhs, rhs));
    except
      {note operand stack overflow not possible here}
      RaiseExprError(stscExprNumeric, FErrorPos);
    end;
  end;
end;

procedure TStExpression.GetFunction;
var
  I          : Integer;
//[NXHop sua]    P1, P2, P3 : TStFloat;
  P1, P2, P3,P4 : Variant;
  Ident      : PStIdentRec;
  St         : string;
begin
  St := eTokenStr;
  GetToken;

  {is this a request to add a constant? (=)}
  if FAllowEqual and (eTokenStr = '=') then begin
    GetToken;
    GetExpression;
    {leave result on the stack to be returned as the expression result}
    AddConstant(St, StackPeek);
    Exit;
  end;

  I := FindIdent(St);
  if I > -1 then begin
    Ident := eIdentList[I];
    case Ident^.Kind of
      ikConstant : StackPush(Ident^.Value);
      ikVariable : StackPush(PStFloat(Ident^.VarAddr)^);
      ikFunction :
        begin
          {place parameters on stack, if any}
          GetParams(Ident^.PCount);
          try
            case Ident^.PCount of
              0 : StackPush(TStFunction0Param(Ident^.Func0Addr));
              1 : begin
                    P1 := PopOperand;
                    StackPush(TStFunction1Param(Ident^.Func1Addr)(P1));
                  end;
              2 : begin
                    P2 := PopOperand;
                    P1 := PopOperand;
                    StackPush(TStFunction2Param(Ident^.Func2Addr)(P1, P2));
                  end;
              3 : begin
                    P3 := PopOperand;
                    P2 := PopOperand;
                    P1 := PopOperand;
                    StackPush(TStFunction3Param(Ident^.Func3Addr)(P1, P2, P3));
                  end;
              // THEM
              4 : begin
                    P4 := PopOperand;
                    P3 := PopOperand;
                    P2 := PopOperand;
                    P1 := PopOperand;
                    StackPush(TStFunction4Param(Ident^.Func4Addr)(P1, P2, P3,P4));
                  end;
            else
              RaiseExprError(stscExprNumeric, FErrorPos);
            end;
          except
            {note operand stack overflow or underflow not possible here}
            {translate RTL numeric errors into STEXPR error}
            RaiseExprError(stscExprNumeric, FErrorPos);
          end;
        end;
      ikMethod   :
        begin
          {place parameters on stack, if any}
          GetParams(Ident^.PCount);
          try
            case Ident^.PCount of
              0 : StackPush(TStMethod0Param(Ident^.Meth0Addr));
              1 : begin
                    P1 := PopOperand;
                    StackPush(TStMethod1Param(Ident^.Meth1Addr)(P1));
                  end;
              2 : begin
                    P2 := PopOperand;
                    P1 := PopOperand;
                    StackPush(TStMethod2Param(Ident^.Meth2Addr)(P1, P2));
                  end;
              3 : begin
                    P3 := PopOperand;
                    P2 := PopOperand;
                    P1 := PopOperand;
                    StackPush(TStMethod3Param(Ident^.Meth3Addr)(P1, P2, P3));
                  end;
              4 : begin
                    P4 := PopOperand;
                    P3 := PopOperand;
                    P2 := PopOperand;
                    P1 := PopOperand;
                    StackPush(TStMethod4Param(Ident^.Meth4Addr)(P1, P2, P3,p4));
                  end;
            else
              RaiseExprError(stscExprNumeric, FErrorPos);
            end;
          except
            {note operand stack overflow or underflow not possible here}
            {translate RTL numeric errors into STEXPR error}
            RaiseExprError(stscExprNumeric, FErrorPos);
          end;
        end;
    end;
  end
  else
    begin
    if Assigned(FOnGetIdentValue) then begin
      P1 := 0;
      FOnGetIdentValue(Self, St, P1);
      StackPush(P1);
    end
    else
  //[NXHop sua]
      StackPush(St);
  // RaiseExprError(stscExprUnkFunc, FErrorPos);
  end;
end;

procedure TStExpression.GetIdentList(S : TStrings);
var
  I    : Integer;
begin
  if Assigned(S) then begin
    S.Clear;
    for I := 0 to eIdentList.Count-1 do
      S.Add(PStIdentRec(eIdentList[I])^.Name);
  end;
end;

procedure TStExpression.GetParams(N : Integer);
begin
  if (N > 0) then begin
    if (eToken <> ssLPar) then
      RaiseExprError(stscExprLParExp, FErrorPos);
    while (N > 0) do begin
      GetToken;
      {evaluate parameter value and leave on stack}
      GetExpression;
      Dec(N);
      if (N > 0) then
        if (eToken <> ssComma) then
          RaiseExprError(stscExprCommExp, FErrorPos);
    end;
    if (eToken <> ssRPar) then
      RaiseExprError(stscExprRParExp, FErrorPos);
    GetToken;
  end;
end;

procedure TStExpression.GetTerm;
var
  SaveOp : TStToken;
begin
  GetFactor;
  while (True) do begin
    case eToken of
      ssTimes, ssDiv :
        begin
          SaveOp := eToken;
          GetToken;
          GetFactor;
          rhs := PopOperand;
          lhs := PopOperand;
          try
            case SaveOp of
              ssTimes :
                StackPush(lhs*rhs);
              ssDiv :
                StackPush(lhs/rhs);
            end;
          except
            {note operand stack overflow not possible here}
            RaiseExprError(stscExprNumeric, FErrorPos);
          end;
        end;
    else
      break;
    end;
  end;
end;

procedure TStExpression.GetToken;
var
  Done : Boolean;
  TT   : TStToken;
begin
  eToken := ssStart;
  eTokenStr := '';
  Done := False;

  while (not Done) do begin
    case eToken of
      ssStart :
        begin
          {save potential error column at start of eTokenStr}
          FErrorPos := eExprPos;
          if (eCurChar = ' ') or (eCurChar = ^I) then
            {skip leading whitespace}
          else if (eCurChar = #0) then begin
            {end of string}
            eToken := ssEol;
            Done := true;
          end else if (eCurChar in Alpha) then begin
            {start of identifier}
            eTokenStr := eTokenStr + LowerCase(eCurChar);
            eToken := ssInIdent;
          end else if (eCurChar in Numeric) then begin
            {start of value}
            eTokenStr := eTokenStr + eCurChar;
            eToken := ssInNum;
          end else begin
            {presumably a single character operator}
            eTokenStr := eTokenStr + eCurChar;
            {make sure it matches a known operator}
            for TT := ssLPar to ssPower do
              if (eCurChar = StExprOperators[TT]) then begin
                Done := True;
                eToken := TT;
                Break;
              end;
            if (not Done) then begin
              {error: unknown character}
              RaiseExprError(stscExprBadChar, FErrorPos);
            end;
            {move to next character}
            Inc(eExprPos);
            if (eExprPos > Length(FExpression)) then
              eCurChar := #0
            else
              eCurChar := FExpression[eExprPos];
          end;
        end;
      ssInIdent :
        if (eCurChar in AlphaNumeric) then
          {continuing in identifier}
          eTokenStr := eTokenStr + LowerCase(eCurChar)
        else begin
          {end of identifier}
          eToken := ssIdent;
          Done := True;
        end;
      ssInNum :
        if (eCurChar in Numeric) then
          {continuing in number}
          eTokenStr := eTokenStr + eCurChar
        else if (LowerCase(eCurChar) = 'e') then begin
          {start of exponent}
          eTokenStr := eTokenStr + LowerCase(eCurChar);
          eToken := ssInSign;
        end else begin
          {end of number}
          eToken := ssNum;
          Done := True;
        end;
      ssInSign :
        if (eCurChar in ['-', '+']) or (eCurChar in Numeric) then begin
          {have exponent sign or start of number}
          eTokenStr := eTokenStr + eCurChar;
          eToken := ssInExp;
        end else begin
          {error: started exponent but didn't finish}
          RaiseExprError(stscExprBadNum, FErrorPos);
        end;
      ssInExp :
        if (eCurChar in Numeric) then
          {continuing in number}
          eTokenStr := eTokenStr + eCurChar
        else begin
          {end of number}
          eToken := ssNum;
          Done := True;
        end;
    end;

    {get next character}
    if (not Done) then begin
      Inc(eExprPos);
      if (eExprPos > Length(FExpression)) then
        eCurChar := #0
      else
        eCurChar := FExpression[eExprPos];
    end;

  end;
end;

function TStExpression.PopOperand : Variant;
begin
  if StackEmpty then
    RaiseExprError(stscExprBadExp, FErrorPos);
  Result := StackPop;
end;

procedure TStExpression.RaiseExprError(Code : LongInt; Column : Integer);
var
  E : EStExprError;
begin
  {clear operand stack}
  StackClear;
  FLastError := Code;
  E := EStExprError.CreateResTPCol(Code, Column, 0);
  E.ErrorCode := Code;
  raise E;
end;

function TStExpression.GetFloat : TstFloat;
begin
  Result:=StrToFloatDef(AsString,0);
end;
procedure TStExpression.RemoveIdentifier(const Name : string);
var
  I : Integer;
  S : string;
begin
  S := LowerCase(Name);
  I := FindIdent(S);
  if I > -1 then begin
    Dispose(PStIdentRec(eIdentList[I]));
    eIdentList.Delete(I);
  end;
end;

procedure TStExpression.StackClear;
var
  I : Integer;
begin
  for I := 0 to eStack.Count-1 do
    Dispose(PStFloat(eStack[I]));
  eStack.Clear;
end;

function TStExpression.StackCount : Integer;
begin
  Result := eStack.Count;
end;

function TStExpression.StackEmpty : Boolean;
begin
  Result := eStack.Count = 0;
end;

function TStExpression.StackPeek : Variant;
begin
  Result := PStFloat(eStack[eStack.Count-1])^;
end;

//[NXHop sua]   Function TStExpression.StackPop : TStFloat;
Function TStExpression.StackPop : Variant;
var
  PF : PStFloat;
begin
  PF := PStFloat(eStack[eStack.Count-1]);
  Result := PF^;
  Dispose(PF);
  eStack.Delete(eStack.Count-1);
end;

//[NXHop sua]   procedure TStExpression.StackPush(const Value : TStFloat);
procedure TStExpression.StackPush(const Value : Variant);
var
  PF : PStFloat;
begin
  New(PF);
  PF^ := Value;
  try
    eStack.Add(PF);
  except
    Dispose(PF);
    raise;
  end;
end;


{*** TStExpressionEdit ***}

procedure TStExpressionEdit.CMExit(var Msg : TMessage);
begin
  inherited;

  if FAutoEval then begin
    try
      DoEvaluate;
    except
      SetFocus;
      raise;
    end;
  end;
end;

constructor TStExpressionEdit.Create(AOwner : TComponent);
begin
  inherited Create(AOwner);

  FExpr := TStExpression.Create(Self);
end;

destructor TStExpressionEdit.Destroy;
begin
  FExpr.Free;

  inherited Destroy;
end;

procedure TStExpressionEdit.DoEvaluate;
var
  V : TStFloat;
begin
  if Text > '' then begin
    V := Evaluate;
    if FExpr.FLastError = 0 then
      Text := FloatToStr(V)
    else
      SelStart := FExpr.FErrorPos;
  end else
    Text := '0';
end;

function TStExpressionEdit.Evaluate : Variant;
begin
  Result := 0;
  FExpr.Expression := Text;
  try
    Result := FExpr.AnalyzeExpression;
  except
    on E : EStExprError do begin
      SelStart := FExpr.FErrorPos;
      if Assigned(FOnError) then
        FOnError(Self, E.ErrorCode, E.Message)
      else
        raise;
    end else
      raise;
  end;
end;

function TStExpressionEdit.GetOnAddIdentifier : TNotifyEvent;
begin
  Result := FExpr.OnAddIdentifier;
end;

function TStExpressionEdit.GetOnGetIdentValue : TStGetIdentValueEvent;
begin
  Result := FExpr.OnGetIdentValue;
end;

procedure TStExpressionEdit.KeyPress(var Key : Char);
begin
  if Key = #13 then begin
    DoEvaluate;
    Key := #0;
    SelStart := Length(Text);
  end;

  inherited KeyPress(Key);
end;

procedure TStExpressionEdit.SetOnAddIdentifier(Value : TNotifyEvent);
begin
  FExpr.OnAddIdentifier := Value;
end;

procedure TStExpressionEdit.SetOnGetIdentValue(Value : TStGetIdentValueEvent);
begin
  FExpr.OngetIdentValue := Value;
end;


end.