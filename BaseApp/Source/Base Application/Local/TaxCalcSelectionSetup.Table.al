table 17309 "Tax Calc. Selection Setup"
{
    Caption = 'Tax Calc. Selection Setup';
    LookupPageID = "Tax Calc. Selection Setup";

    fields
    {
        field(1; "Register No."; Code[10])
        {
            Caption = 'Register No.';
            TableRelation = "Tax Calc. Header"."No.";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(6; "Account No."; Code[100])
        {
            Caption = 'Account No.';
            TableRelation = "G/L Account"."No.";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                if "Account No." <> '' then
                    if "Register Type" = "Register Type"::Item then
                        "Bal. Account No." := '';
            end;
        }
        field(8; "Bal. Account No."; Code[100])
        {
            Caption = 'Bal. Account No.';
            TableRelation = "G/L Account"."No.";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                if "Bal. Account No." <> '' then
                    if "Register Type" = "Register Type"::Item then
                        "Account No." := '';
            end;
        }
        field(11; "Register Type"; Option)
        {
            Caption = 'Register Type';
            OptionCaption = ' ,Item';
            OptionMembers = " ",Item;

            trigger OnValidate()
            begin
                if "Register Type" = "Register Type"::Item then begin
                    TaxCalcHeader.Get("Section Code", "Register No.");
                    if TaxCalcHeader."Table ID" <> DATABASE::"Tax Calc. Item Entry" then
                        FieldError("Register Type");
                end;
            end;
        }
        field(12; "Line Code"; Code[10])
        {
            Caption = 'Line Code';
        }
        field(13; "Section Code"; Code[10])
        {
            Caption = 'Section Code';
            NotBlank = true;
            TableRelation = "Tax Calc. Section";
        }
        field(14; "Dimensions Filters"; Boolean)
        {
            CalcFormula = Exist ("Tax Calc. Dim. Filter" WHERE("Section Code" = FIELD("Section Code"),
                                                               "Register No." = FIELD("Register No."),
                                                               Define = CONST("Entry Setup"),
                                                               "Line No." = FIELD("Line No.")));
            Caption = 'Dimensions Filters';
            Editable = false;
            FieldClass = FlowField;
        }
        field(16; "G/L Corr. Dimensions Filters"; Boolean)
        {
            CalcFormula = Exist ("Tax Diff. Corr. Dim. Filter" WHERE("Section Code" = FIELD("Section Code"),
                                                                     "Tax Calc. No." = FIELD("Register No."),
                                                                     "Line No." = FIELD("Line No."),
                                                                     Define = CONST("Entry Setup")));
            Caption = 'G/L Corr. Dimensions Filters';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Section Code", "Register No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TaxCalcSection.Get("Section Code");
        TaxCalcSection.ValidateChange();

        TaxCalcDimFilter.SetRange("Section Code", "Section Code");
        TaxCalcDimFilter.SetRange("Register No.", "Register No.");
        TaxCalcDimFilter.SetRange(Define, TaxCalcDimFilter.Define::"Entry Setup");
        TaxCalcDimFilter.SetRange("Line No.", "Line No.");
        TaxCalcDimFilter.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        TaxCalcSection.Get("Section Code");
        TaxCalcSection.ValidateChange();

        SetupRegisterType();
        Validate("Account No.");
        Validate("Bal. Account No.");
    end;

    trigger OnModify()
    begin
        TaxCalcSection.Get("Section Code");
        TaxCalcSection.ValidateChange();
    end;

    var
        TaxCalcSection: Record "Tax Calc. Section";
        TaxCalcDimFilter: Record "Tax Calc. Dim. Filter";
        TaxCalcHeader: Record "Tax Calc. Header";

    [Scope('OnPrem')]
    procedure SetupRegisterType()
    begin
        TaxCalcHeader.Get("Section Code", "Register No.");
        if TaxCalcHeader."Table ID" = DATABASE::"Tax Calc. Item Entry" then
            "Register Type" := "Register Type"::Item
        else
            "Register Type" := "Register Type"::" ";
    end;

    [Scope('OnPrem')]
    procedure GetGLCorrDimFilter(DimCode: Code[20]; FilterGroup: Option Debit,Credit) DimFilter: Text[250]
    var
        TaxDifGLCorrDimFilter: Record "Tax Diff. Corr. Dim. Filter";
    begin
        if TaxDifGLCorrDimFilter.Get("Section Code", "Register No.", 1, "Line No.", FilterGroup, DimCode) then
            DimFilter := TaxDifGLCorrDimFilter."Dimension Value Filter";
    end;
}

