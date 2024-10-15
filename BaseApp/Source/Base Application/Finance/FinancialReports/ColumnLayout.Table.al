namespace Microsoft.Finance.FinancialReports;

using Microsoft.CostAccounting.Setup;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;

table 334 "Column Layout"
{
    Caption = 'Column Layout';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Column Layout Name"; Code[10])
        {
            Caption = 'Column Layout Name';
            TableRelation = "Column Layout Name";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Column No."; Code[10])
        {
            Caption = 'Column No.';
        }
        field(4; "Column Header"; Text[30])
        {
            Caption = 'Column Header';
        }
        field(5; "Column Type"; Enum "Column Layout Type")
        {
            Caption = 'Column Type';
            InitValue = "Net Change";
        }
        field(6; "Ledger Entry Type"; Enum "Column Layout Entry Type")
        {
            Caption = 'Ledger Entry Type';
        }
        field(7; "Amount Type"; Enum "Account Schedule Amount Type")
        {
            Caption = 'Amount Type';
        }
        field(8; Formula; Code[80])
        {
            Caption = 'Formula';

            trigger OnValidate()
            var
                TempAccSchedLine: Record "Acc. Schedule Line" temporary;
            begin
                TempAccSchedLine.CheckFormula(Formula);
            end;
        }
        field(9; "Comparison Date Formula"; DateFormula)
        {
            Caption = 'Comparison Date Formula';

            trigger OnValidate()
            begin
                if Format("Comparison Date Formula") <> '' then
                    Validate("Comparison Period Formula", '');
            end;
        }
        field(10; "Show Opposite Sign"; Boolean)
        {
            Caption = 'Show Opposite Sign';
        }
        field(11; Show; Enum "Column Layout Show")
        {
            Caption = 'Show';
            InitValue = Always;
        }
        field(12; "Rounding Factor"; Enum "Analysis Rounding Factor")
        {
            Caption = 'Rounding Factor';
        }
        field(13; "Show Indented Lines"; Option)
        {
            Caption = 'Show Indented Lines';
            OptionCaption = 'All,Indented Only,Non-Indented Only';
            OptionMembers = All,"Indented Only","Non-Indented Only";
        }
        field(14; "Comparison Period Formula"; Code[20])
        {
            Caption = 'Comparison Period Formula';

            trigger OnValidate()
            var
                Steps: Integer;
                RangeFromInt: Integer;
                RangeToInt: Integer;
                Type: Option " ",Period,"Fiscal year","Fiscal Halfyear","Fiscal Quarter";
                RangeFromType: Option Int,CP,LP;
                RangeToType: Option Int,CP,LP;
            begin
                "Comparison Period Formula LCID" := GlobalLanguage;
                ParsePeriodFormula(
                  "Comparison Period Formula",
                  Steps, Type, RangeFromType, RangeToType, RangeFromInt, RangeToInt);
                if "Comparison Period Formula" <> '' then
                    Clear("Comparison Date Formula");
            end;
        }
        field(15; "Business Unit Totaling"; Text[80])
        {
            Caption = 'Business Unit Totaling';
            TableRelation = "Business Unit";
            ValidateTableRelation = false;
        }
        field(16; "Dimension 1 Totaling"; Text[80])
        {
            AccessByPermission = TableData Dimension = R;
            CaptionClass = GetCaptionClass(5);
            Caption = 'Dimension 1 Totaling';
        }
        field(17; "Dimension 2 Totaling"; Text[80])
        {
            AccessByPermission = TableData Dimension = R;
            CaptionClass = GetCaptionClass(6);
            Caption = 'Dimension 2 Totaling';
        }
        field(18; "Dimension 3 Totaling"; Text[80])
        {
            AccessByPermission = TableData "Dimension Combination" = R;
            CaptionClass = GetCaptionClass(7);
            Caption = 'Dimension 3 Totaling';
        }
        field(19; "Dimension 4 Totaling"; Text[80])
        {
            AccessByPermission = TableData "Dimension Combination" = R;
            CaptionClass = GetCaptionClass(8);
            Caption = 'Dimension 4 Totaling';
        }
        field(20; "Cost Center Totaling"; Text[80])
        {
            Caption = 'Cost Center Totaling';
        }
        field(21; "Cost Object Totaling"; Text[80])
        {
            Caption = 'Cost Object Totaling';
        }
        field(30; "Comparison Period Formula LCID"; Integer)
        {
            Caption = 'Comparison Period Formula LCID';
        }
        field(35; "Budget Name"; Code[10])
        {
            Caption = 'Budget Name';
            TableRelation = "G/L Budget Name";
        }
        field(40; "Hide Currency Symbol"; Boolean)
        {
            Caption = 'Hide Currency Symbol';

            trigger OnValidate()
            begin
                if "Hide Currency Symbol" then
                    TestField("Column Type", "Column Layout Type"::Formula);
            end;
        }
    }

    keys
    {
        key(Key1; "Column Layout Name", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        ColumnLayoutName: Record "Column Layout Name";
        AnalysisView: Record "Analysis View";
        GLSetup: Record "General Ledger Setup";
        HasGLSetup: Boolean;

        PeriodFormulaErr: Label '%1 is not a valid Period Formula.', Comment = '%1 - value of Comparison Period Formula field';
#pragma warning disable AA0074
        Text002: Label 'P', Comment = 'Period';
        Text003: Label 'FY', Comment = 'Fiscal year';
        Text004: Label 'CP', Comment = 'Current Period';
        Text005: Label 'LP', Comment = 'Last period';
        Text006: Label '1,6,,Dimension 1 Filter';
        Text007: Label '1,6,,Dimension 2 Filter';
        Text008: Label '1,6,,Dimension 3 Filter';
        Text009: Label '1,6,,Dimension 4 Filter';
        Text010: Label ',, Totaling';
        Text011: Label '1,5,,Dimension 1 Totaling';
        Text012: Label '1,5,,Dimension 2 Totaling';
        Text013: Label '1,5,,Dimension 3 Totaling';
        Text014: Label '1,5,,Dimension 4 Totaling';
#pragma warning disable AA0470
        Text015: Label 'The %1 refers to %2 %3, which does not exist. The field %4 on table %5 has now been deleted.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure ParsePeriodFormula(FormulaExpression: Code[20]; var Steps: Integer; var Type: Option " ",Period,"Fiscal Year"; var RangeFromType: Option Int,CP,LP; var RangeToType: Option Int,CP,LP; var RangeFromInt: Integer; var RangeToInt: Integer)
    var
        OldLanguageID: Integer;
        FormulaParsed: Boolean;
    begin
        if "Comparison Period Formula LCID" = 0 then
            "Comparison Period Formula LCID" := GlobalLanguage;

        OldLanguageID := GlobalLanguage;
        GlobalLanguage("Comparison Period Formula LCID");
        FormulaParsed := TryParsePeriodFormula(FormulaExpression, Steps, Type, RangeFromType, RangeToType, RangeFromInt, RangeToInt);
        GlobalLanguage(OldLanguageID);

        if not FormulaParsed then
            Error(GetLastErrorText);
    end;

    [TryFunction]
    local procedure TryParsePeriodFormula(FormulaExpression: Code[20]; var Steps: Integer; var Type: Option " ",Period,"Fiscal Year"; var RangeFromType: Option Int,CP,LP; var RangeToType: Option Int,CP,LP; var RangeFromInt: Integer; var RangeToInt: Integer)
    var
        OriginalFormula: Code[20];
    begin
        // <PeriodFormula> ::= <signed integer> <formula> | blank
        // <signed integer> ::= <sign> <positive integer> | blank
        // <sign> ::= + | - | blank
        // <positive integer> ::= <digit 1-9> <digits>
        // <digit 1-9> ::= 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
        // <digits> ::= 0 <digits> | <digit 1-9> <digits> | blank
        // <formula> ::= P | FY <range> | FH <range> | FQ <range>
        // <range> ::= blank | [<range2>]
        // <range2> ::= <index> .. <index> | <index>
        // <index> ::= <positive integer> | CP | LP

        OriginalFormula := FormulaExpression;
        FormulaExpression := DelChr(FormulaExpression);

        if not ParseFormula(FormulaExpression, Steps, Type) then
            Error(PeriodFormulaErr, OriginalFormula);

        if Type = Type::"Fiscal Year" then
            if not ParseRange(FormulaExpression, RangeFromType, RangeFromInt, RangeToType, RangeToInt) then
                Error(PeriodFormulaErr, OriginalFormula);

        if FormulaExpression <> '' then
            Error(PeriodFormulaErr, OriginalFormula);
    end;

    local procedure ParseFormula(var FormulaExpression: Code[20]; var Steps: Integer; var Type: Option " ",Period,"Fiscal Year"): Boolean
    begin
        Steps := 0;
        Type := Type::" ";

        if FormulaExpression = '' then
            exit(true);

        if not ParseSignedInteger(FormulaExpression, Steps) then
            exit(false);

        if FormulaExpression = '' then
            exit(false);

        if not ParseType(FormulaExpression, Type) then
            exit(false);

        exit(true);
    end;

    local procedure ParseSignedInteger(var FormulaExpression: Code[20]; var Int: Integer): Boolean
    begin
        Int := 0;

        case CopyStr(FormulaExpression, 1, 1) of
            '-':
                begin
                    FormulaExpression := CopyStr(FormulaExpression, 2);
                    if not ParseInt(FormulaExpression, Int, false) then
                        exit(false);
                    Int := -Int;
                end;
            '+':
                begin
                    FormulaExpression := CopyStr(FormulaExpression, 2);
                    if not ParseInt(FormulaExpression, Int, false) then
                        exit(false);
                end;
            else
                if not ParseInt(FormulaExpression, Int, true) then
                    exit(false);
        end;
        exit(true);
    end;

    local procedure ParseInt(var FormulaExpression: Code[20]; var Int: Integer; AllowNotInt: Boolean): Boolean
    var
        IntegerStr: Code[20];
    begin
        if CopyStr(FormulaExpression, 1, 1) in ['1' .. '9'] then
            repeat
                IntegerStr := IntegerStr + CopyStr(FormulaExpression, 1, 1);
                FormulaExpression := CopyStr(FormulaExpression, 2);
                if FormulaExpression = '' then
                    exit(false);
            until not (CopyStr(FormulaExpression, 1, 1) in ['0' .. '9'])
        else
            exit(AllowNotInt);
        Evaluate(Int, IntegerStr);
        exit(true);
    end;

    local procedure ParseType(var FormulaExpression: Code[20]; var Type: Option " ",Period,"Fiscal Year"): Boolean
    begin
        case ReadToken(FormulaExpression) of
            Text002:
                Type := Type::Period;
            Text003:
                Type := Type::"Fiscal Year";
            else
                exit(false);
        end;
        exit(true);
    end;

    local procedure ParseRange(var FormulaExpression: Code[20]; var FromType: Option Int,CP,LP; var FromInt: Integer; var ToType: Option Int,CP,LP; var ToInt: Integer): Boolean
    begin
        FromType := FromType::CP;
        ToType := ToType::CP;

        if FormulaExpression = '' then
            exit(true);

        if not ParseToken(FormulaExpression, '[') then
            exit(false);

        if not ParseIndex(FormulaExpression, FromType, FromInt) then
            exit(false);
        if FormulaExpression = '' then
            exit(false);

        if CopyStr(FormulaExpression, 1, 1) = '.' then begin
            if not ParseToken(FormulaExpression, '..') then
                exit(false);
            if not ParseIndex(FormulaExpression, ToType, ToInt) then
                exit(false);
        end else begin
            ToType := FromType;
            ToInt := FromInt;
        end;

        if not ParseToken(FormulaExpression, ']') then
            exit(false);

        exit(true);
    end;

    local procedure ParseIndex(var FormulaExpression: Code[20]; var IndexType: Option Int,CP,LP; var Index: Integer): Boolean
    begin
        if FormulaExpression = '' then
            exit(false);

        if ParseInt(FormulaExpression, Index, false) then
            IndexType := IndexType::Int
        else
            case ReadToken(FormulaExpression) of
                Text004:
                    IndexType := IndexType::CP;
                Text005:
                    IndexType := IndexType::LP;
                else
                    exit(false);
            end;

        exit(true);
    end;

    local procedure ParseToken(var FormulaExpression: Code[20]; Token: Code[20]): Boolean
    begin
        if CopyStr(FormulaExpression, 1, StrLen(Token)) <> Token then
            exit(false);
        FormulaExpression := CopyStr(FormulaExpression, StrLen(Token) + 1);
        exit(true)
    end;

    local procedure ReadToken(var FormulaExpression: Code[20]): Code[20]
    var
        Token: Code[20];
        p: Integer;
    begin
        Token := '';
        for p := 1 to StrLen(FormulaExpression) do begin
            if CopyStr(FormulaExpression, p, 1) in ['[', ']', '.'] then begin
                FormulaExpression := CopyStr(FormulaExpression, StrLen(Token) + 1);
                exit(Token);
            end;
            Token := Token + CopyStr(FormulaExpression, p, 1);
        end;

        FormulaExpression := '';
        exit(Token);
    end;

    procedure LookUpDimFilter(DimNo: Integer; var Text: Text[250]) Result: Boolean
    var
        DimVal: Record "Dimension Value";
        CostAccSetup: Record "Cost Accounting Setup";
        DimValList: Page "Dimension Value List";
        IsHandled: Boolean;
    begin
        GetColLayoutSetup();

        IsHandled := false;
        OnBeforeLookUpDimFilter(Rec, DimNo, Text, ColumnLayoutName, Result, IsHandled, AnalysisView);
        if IsHandled then
            exit(Result);

        if CostAccSetup.Get() then;
        case DimNo of
            1:
                DimVal.SetRange("Dimension Code", AnalysisView."Dimension 1 Code");
            2:
                DimVal.SetRange("Dimension Code", AnalysisView."Dimension 2 Code");
            3:
                DimVal.SetRange("Dimension Code", AnalysisView."Dimension 3 Code");
            4:
                DimVal.SetRange("Dimension Code", AnalysisView."Dimension 4 Code");
            5:
                DimVal.SetRange("Dimension Code", CostAccSetup."Cost Center Dimension");
            6:
                DimVal.SetRange("Dimension Code", CostAccSetup."Cost Object Dimension");
        end;
        DimValList.LookupMode(true);
        DimValList.SetTableView(DimVal);
        if DimValList.RunModal() = ACTION::LookupOK then begin
            DimValList.GetRecord(DimVal);
            Text := DimValList.GetSelectionFilter();
            exit(true);
        end;
        exit(false)
    end;

    procedure GetCaptionClass(AnalysisViewDimType: Integer) Result: Text[250]
    var
        IsHandled: Boolean;
    begin
        GetColLayoutSetup();

        IsHandled := false;
        OnBeforeGetCaptionClass(Rec, ColumnLayoutName, AnalysisViewDimType, Result, IsHandled);
        if IsHandled then
            exit(Result);

        case AnalysisViewDimType of
            1:
                begin
                    if AnalysisView."Dimension 1 Code" <> '' then
                        exit('1,6,' + AnalysisView."Dimension 1 Code");

                    exit(Text006);
                end;
            2:
                begin
                    if AnalysisView."Dimension 2 Code" <> '' then
                        exit('1,6,' + AnalysisView."Dimension 2 Code");

                    exit(Text007);
                end;
            3:
                begin
                    if AnalysisView."Dimension 3 Code" <> '' then
                        exit('1,6,' + AnalysisView."Dimension 3 Code");

                    exit(Text008);
                end;
            4:
                begin
                    if AnalysisView."Dimension 4 Code" <> '' then
                        exit('1,6,' + AnalysisView."Dimension 4 Code");

                    exit(Text009);
                end;
            5:
                begin
                    if AnalysisView."Dimension 1 Code" <> '' then
                        exit('1,5,' + AnalysisView."Dimension 1 Code" + Text010);

                    exit(Text011);
                end;
            6:
                begin
                    if AnalysisView."Dimension 2 Code" <> '' then
                        exit('1,5,' + AnalysisView."Dimension 2 Code" + Text010);

                    exit(Text012);
                end;
            7:
                begin
                    if AnalysisView."Dimension 3 Code" <> '' then
                        exit('1,5,' + AnalysisView."Dimension 3 Code" + Text010);

                    exit(Text013);
                end;
            8:
                begin
                    if AnalysisView."Dimension 4 Code" <> '' then
                        exit('1,5,' + AnalysisView."Dimension 4 Code" + Text010);

                    exit(Text014);
                end;
        end;
    end;

    local procedure GetColLayoutSetup()
    begin
        if "Column Layout Name" <> ColumnLayoutName.Name then
            ColumnLayoutName.Get("Column Layout Name");
        if ColumnLayoutName."Analysis View Name" <> '' then
            if ColumnLayoutName."Analysis View Name" <> AnalysisView.Code then
                if not AnalysisView.Get(ColumnLayoutName."Analysis View Name") then begin
                    Message(
                      Text015,
                      ColumnLayoutName.TableCaption(), AnalysisView.TableCaption(), ColumnLayoutName."Analysis View Name",
                      ColumnLayoutName.FieldCaption("Analysis View Name"), ColumnLayoutName.TableCaption());
                    ColumnLayoutName."Analysis View Name" := '';
                    ColumnLayoutName.Modify();
                end;

        if ColumnLayoutName."Analysis View Name" = '' then begin
            if not HasGLSetup then begin
                GLSetup.Get();
                HasGLSetup := true;
            end;
            Clear(AnalysisView);
            AnalysisView."Dimension 1 Code" := GLSetup."Global Dimension 1 Code";
            AnalysisView."Dimension 2 Code" := GLSetup."Global Dimension 2 Code";
        end;
    end;

    procedure GetPeriodName(): Code[10]
    begin
        exit(Text002);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCaptionClass(var ColumnLayout: Record "Column Layout"; ColumnLayoutName: Record "Column Layout Name"; AnalysisViewDimType: Integer; var Result: Text[250]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookUpDimFilter(var ColumnLayout: Record "Column Layout"; DimNo: Integer; var Text: Text[250]; ColumnLayoutName: Record "Column Layout Name"; var Result: Boolean; var IsHandled: Boolean; var AnalysisView: Record "Analysis View")
    begin
    end;
}

