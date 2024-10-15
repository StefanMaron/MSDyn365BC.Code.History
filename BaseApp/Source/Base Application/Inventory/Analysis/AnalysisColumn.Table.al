namespace Microsoft.Inventory.Analysis;

using Microsoft.Foundation.Enums;

table 7118 "Analysis Column"
{
    Caption = 'Analysis Column';
    DrillDownPageID = "Analysis Columns";
    LookupPageID = "Analysis Columns";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Analysis Area"; Enum "Analysis Area Type")
        {
            Caption = 'Analysis Area';
        }
        field(2; "Analysis Column Template"; Code[10])
        {
            Caption = 'Analysis Column Template';
            TableRelation = "Analysis Column Template".Name where("Analysis Area" = field("Analysis Area"));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Column No."; Code[10])
        {
            Caption = 'Column No.';
        }
        field(5; "Column Header"; Text[50])
        {
            Caption = 'Column Header';
        }
        field(6; "Column Type"; Enum "Analysis Column Type")
        {
            Caption = 'Column Type';
            InitValue = "Net Change";
        }
        field(7; "Ledger Entry Type"; Option)
        {
            Caption = 'Ledger Entry Type';
            OptionCaption = 'Item Entries,Item Budget Entries';
            OptionMembers = "Item Entries","Item Budget Entries";
        }
        field(8; Formula; Code[80])
        {
            Caption = 'Formula';

            trigger OnValidate()
            begin
                TempAnalysisLine.CheckFormula(Formula);
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
        field(11; Show; Option)
        {
            Caption = 'Show';
            InitValue = Always;
            OptionCaption = 'Always,Never,When Positive,When Negative';
            OptionMembers = Always,Never,"When Positive","When Negative";
        }
        field(12; "Rounding Factor"; Enum "Analysis Rounding Factor")
        {
            Caption = 'Rounding Factor';
        }
        field(13; "Comparison Period Formula"; Code[20])
        {
            Caption = 'Comparison Period Formula';

            trigger OnValidate()
            var
                Steps: Integer;
                Type: Option " ",Period,"Fiscal year","Fiscal Halfyear","Fiscal Quarter";
                RangeFromType: Option Int,CP,LP;
                RangeToType: Option Int,CP,LP;
                RangeFromInt: Integer;
                RangeToInt: Integer;
            begin
                "Comparison Period Formula LCID" := GlobalLanguage;
                ParsePeriodFormula(
                  "Comparison Period Formula",
                  Steps, Type, RangeFromType, RangeToType, RangeFromInt, RangeToInt);
                if "Comparison Period Formula" <> '' then
                    Clear("Comparison Date Formula");
            end;
        }
        field(14; "Analysis Type Code"; Code[10])
        {
            Caption = 'Analysis Type Code';
            TableRelation = "Analysis Type";

            trigger OnValidate()
            var
                ItemAnalysisType: Record "Analysis Type";
            begin
                if "Analysis Type Code" <> '' then begin
                    ItemAnalysisType.Get("Analysis Type Code");
                    if "Column Header" = '' then
                        "Column Header" := ItemAnalysisType.Name;
                    "Item Ledger Entry Type Filter" := ItemAnalysisType."Item Ledger Entry Type Filter";
                    "Value Entry Type Filter" := ItemAnalysisType."Value Entry Type Filter";
                    "Value Type" := ItemAnalysisType."Value Type";
                end;
            end;
        }
        field(15; "Item Ledger Entry Type Filter"; Text[250])
        {
            Caption = 'Item Ledger Entry Type Filter';

            trigger OnValidate()
            begin
                AnalysisRepMgmt.ValidateFilter(
                  "Item Ledger Entry Type Filter", DATABASE::"Analysis Column",
                  FieldNo("Item Ledger Entry Type Filter"), true);
            end;
        }
        field(16; "Value Entry Type Filter"; Text[250])
        {
            Caption = 'Value Entry Type Filter';

            trigger OnValidate()
            begin
                AnalysisRepMgmt.ValidateFilter(
                  "Value Entry Type Filter", DATABASE::"Analysis Column",
                  FieldNo("Value Entry Type Filter"), true);
            end;
        }
        field(17; "Value Type"; Enum "Analysis Value Type")
        {
            Caption = 'Value Type';
        }
        field(18; Invoiced; Boolean)
        {
            Caption = 'Invoiced';
        }
        field(30; "Comparison Period Formula LCID"; Integer)
        {
            Caption = 'Comparison Period Formula LCID';
        }
    }

    keys
    {
        key(Key1; "Analysis Area", "Analysis Column Template", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        TempAnalysisLine: Record "Analysis Line" temporary;
        AnalysisRepMgmt: Codeunit "Analysis Report Management";

#pragma warning disable AA0074
        Text002: Label 'P', Comment = 'Period';
        Text003: Label 'FY', Comment = 'Fiscal year';
        Text004: Label 'CP', Comment = 'Current Period';
        Text005: Label 'LP', Comment = 'Last period';
#pragma warning restore AA0074
        PeriodFormulaErr: Label '%1 is not a valid Period Formula.', Comment = '%1 - value of Comparison Period Formula field';

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
}

