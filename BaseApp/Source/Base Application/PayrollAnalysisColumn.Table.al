table 14964 "Payroll Analysis Column"
{
    Caption = 'Payroll Analysis Column';

    fields
    {
        field(1; "Analysis Column Template"; Code[10])
        {
            Caption = 'Analysis Column Template';
            TableRelation = "Payroll Analysis Column Tmpl.";
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
        field(5; "Column Type"; Option)
        {
            Caption = 'Column Type';
            InitValue = "Net Change";
            OptionCaption = 'Formula,Net Change,Balance at Date,Beginning Balance,Year to Date,Rest of Payroll Year,Entire Payroll Year';
            OptionMembers = Formula,"Net Change","Balance at Date","Beginning Balance","Year to Date","Rest of Payroll Year","Entire Payroll Year";
        }
        field(6; "Amount Type"; Option)
        {
            Caption = 'Amount Type';
            OptionCaption = 'Payroll Amount,Taxable Amount,Quantity,Payment Days,Number of Employees';
            OptionMembers = "Payroll Amount","Taxable Amount",Quantity,"Payment Days","Number of Employees";
        }
        field(8; Formula; Code[80])
        {
            Caption = 'Formula';
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
            NotBlank = true;
            OptionCaption = 'Always,Never,When Positive,When Negative';
            OptionMembers = Always,Never,"When Positive","When Negative";
        }
        field(12; "Rounding Factor"; Option)
        {
            Caption = 'Rounding Factor';
            OptionCaption = 'None,1,1000,1000000';
            OptionMembers = "None","1","1000","1000000";
        }
        field(13; "Comparison Period Formula"; Code[20])
        {
            Caption = 'Comparison Period Formula';
        }
    }

    keys
    {
        key(Key1; "Analysis Column Template", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        Text001: Label '%1 is not a valid Period Formula';
        Text002: Label 'P', Comment = 'Period';
        Text003: Label 'FY', Comment = 'Fiscal Year';
        Text004: Label 'CP', Comment = 'Current Period';
        Text005: Label 'LP', Comment = 'Last Period';

    [Scope('OnPrem')]
    procedure ParsePeriodFormula(Formula: Code[20]; var Steps: Integer; var Type: Option " ",Period,"Fiscal Year","Fiscal Halfyear","Fiscal Quarter"; var RangeFromType: Option Int,CP,LP; var RangeToType: Option Int,CP,LP; var RangeFromInt: Integer; var RangeToInt: Integer)
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

        OriginalFormula := Formula;
        Formula := DelChr(Formula);

        if not ParseFormula(Formula, Steps, Type) then
            Error(Text001, OriginalFormula);

        if Type = Type::"Fiscal Year" then
            if not ParseRange(Formula, RangeFromType, RangeFromInt, RangeToType, RangeToInt) then
                Error(Text001, OriginalFormula);

        if Formula <> '' then
            Error(Text001, OriginalFormula);
    end;

    local procedure ParseFormula(var Formula: Code[20]; var Steps: Integer; var Type: Option " ",Period,"Fiscal Year","Fiscal Halfyear","Fiscal Quarter"): Boolean
    begin
        Steps := 0;
        Type := Type::" ";

        if Formula = '' then
            exit(true);

        if not ParseSignedInteger(Formula, Steps) then
            exit(false);

        if Formula = '' then
            exit(false);

        if not ParseType(Formula, Type) then
            exit(false);

        exit(true);
    end;

    local procedure ParseSignedInteger(var Formula: Code[20]; var Int: Integer): Boolean
    begin
        Int := 0;

        case CopyStr(Formula, 1, 1) of
            '-':
                begin
                    Formula := CopyStr(Formula, 2);
                    if not ParseInt(Formula, Int, false) then
                        exit(false);
                    Int := -Int;
                end;
            '+':
                begin
                    Formula := CopyStr(Formula, 2);
                    if not ParseInt(Formula, Int, false) then
                        exit(false);
                end;
            else
                if not ParseInt(Formula, Int, true) then
                    exit(false);
        end;
        exit(true);
    end;

    local procedure ParseInt(var Formula: Code[20]; var Int: Integer; AllowNotInt: Boolean): Boolean
    var
        IntegerStr: Code[20];
    begin
        if CopyStr(Formula, 1, 1) in ['1' .. '9'] then
            repeat
                IntegerStr := IntegerStr + CopyStr(Formula, 1, 1);
                Formula := CopyStr(Formula, 2);
                if Formula = '' then
                    exit(false);
            until not (CopyStr(Formula, 1, 1) in ['0' .. '9'])
        else
            exit(AllowNotInt);
        Evaluate(Int, IntegerStr);
        exit(true);
    end;

    local procedure ParseType(var Formula: Code[20]; var Type: Option " ",Period,"Fiscal Year"): Boolean
    begin
        case ReadToken(Formula) of
            Text002:
                Type := Type::Period;
            Text003:
                Type := Type::"Fiscal Year";
            else
                exit(false);
        end;
        exit(true);
    end;

    local procedure ParseRange(var Formula: Code[20]; var FromType: Option Int,CP,LP; var FromInt: Integer; var ToType: Option Int,CP,LP; var ToInt: Integer): Boolean
    begin
        FromType := FromType::CP;
        ToType := ToType::CP;

        if Formula = '' then
            exit(true);

        if not ParseToken(Formula, '[') then
            exit(false);

        if not ParseIndex(Formula, FromType, FromInt) then
            exit(false);
        if Formula = '' then
            exit(false);

        if CopyStr(Formula, 1, 1) = '.' then begin
            if not ParseToken(Formula, '..') then
                exit(false);
            if not ParseIndex(Formula, ToType, ToInt) then
                exit(false);
        end else begin
            ToType := FromType;
            ToInt := FromInt;
        end;

        if not ParseToken(Formula, ']') then
            exit(false);

        exit(true);
    end;

    local procedure ParseIndex(var Formula: Code[20]; var IndexType: Option Int,CP,LP; var Index: Integer): Boolean
    begin
        if Formula = '' then
            exit(false);

        if ParseInt(Formula, Index, false) then
            IndexType := IndexType::Int
        else
            case ReadToken(Formula) of
                Text004:
                    IndexType := IndexType::CP;
                Text005:
                    IndexType := IndexType::LP;
                else
                    exit(false);
            end;

        exit(true);
    end;

    local procedure ParseToken(var Formula: Code[20]; Token: Code[20]): Boolean
    begin
        if CopyStr(Formula, 1, StrLen(Token)) <> Token then
            exit(false);
        Formula := CopyStr(Formula, StrLen(Token) + 1);
        exit(true)
    end;

    local procedure ReadToken(var Formula: Code[20]): Code[20]
    var
        Token: Code[20];
        p: Integer;
    begin
        for p := 1 to StrLen(Formula) do begin
            if CopyStr(Formula, p, 1) in ['[', ']', '.'] then begin
                Formula := CopyStr(Formula, StrLen(Token) + 1);
                exit(Token);
            end;
            Token := Token + CopyStr(Formula, p, 1);
        end;

        Formula := '';
        exit(Token);
    end;

    [Scope('OnPrem')]
    procedure GetRecDescription(): Text[250]
    begin
        exit(
          StrSubstNo('%1 %2=''%3'', %4=''%5''',
            TableCaption,
            FieldCaption("Analysis Column Template"), "Analysis Column Template",
            FieldCaption("Line No."), "Line No."));
    end;
}

