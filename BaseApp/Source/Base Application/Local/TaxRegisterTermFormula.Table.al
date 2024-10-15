table 17205 "Tax Register Term Formula"
{
    Caption = 'Tax Register Term Formula';
    LookupPageID = "Tax Register Term Lines";

    fields
    {
        field(1; "Term Code"; Code[20])
        {
            Caption = 'Term Code';
            NotBlank = true;
            TableRelation = "Tax Register Term"."Term Code";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            NotBlank = true;
        }
        field(3; "Expression Type"; Option)
        {
            CalcFormula = Lookup ("Tax Register Term"."Expression Type" WHERE("Term Code" = FIELD("Term Code")));
            Caption = 'Expression Type';
            FieldClass = FlowField;
            OptionCaption = 'Plus/Minus,Multiply/Divide,Compare';
            OptionMembers = "Plus/Minus","Multiply/Divide",Compare;
        }
        field(4; Operation; Option)
        {
            Caption = 'Operation';
            OptionCaption = '+,-,*,/,Negative,Zero,Positive';
            OptionMembers = "+","-","*","/",Negative,Zero,Positive;

            trigger OnValidate()
            begin
                CalcFields("Expression Type");
                if ("Expression Type" = "Expression Type"::"Plus/Minus") and
                   not (Operation = Operation::"+") and not (Operation = Operation::"-")
                then
                    Error(Text000);

                if ("Expression Type" = "Expression Type"::"Multiply/Divide") and
                   not (Operation = Operation::"*") and not (Operation = Operation::"/")
                then
                    Error(Text001);

                if ("Expression Type" = "Expression Type"::Compare) and
                   not (Operation = Operation::Negative) and not (Operation = Operation::Zero) and
                   not (Operation = Operation::Positive)
                then
                    Error(Text002);

                if Operation <> xRec.Operation then begin
                    TaxRegSection.Get("Section Code");
                    TaxRegSection.ValidateChangeDeclaration();
                end;
            end;
        }
        field(5; "Account Type"; Option)
        {
            Caption = 'Account Type';
            OptionCaption = 'Constant,G/L Account,Term,Net Change,Norm';
            OptionMembers = Constant,"G/L Account",Term,"Net Change",Norm;

            trigger OnValidate()
            begin
                CalcFields("Expression Type");
                if "Expression Type" = "Expression Type"::Compare then
                    "Account Type" := "Account Type"::Term
                else begin
                    "Account No." := '';
                    "Bal. Account No." := '';
                    "Amount Type" := "Amount Type"::Debit
                end;
                if "Account Type" <> xRec."Account Type" then begin
                    TaxRegSection.Get("Section Code");
                    TaxRegSection.ValidateChangeDeclaration();
                end;
            end;
        }
        field(6; "Account No."; Code[100])
        {
            Caption = 'Account No.';
            TableRelation = IF ("Expression Type" = FILTER(<> Compare),
                                "Account Type" = CONST("G/L Account")) "G/L Account"."No."
            ELSE
            IF ("Expression Type" = FILTER(<> Compare),
                                         "Account Type" = CONST("Net Change")) "G/L Account"."No."
            ELSE
            IF ("Account Type" = CONST(Term)) "Tax Register Term"."Term Code"
            ELSE
            IF ("Account Type" = CONST(Norm)) "Tax Register Norm Group".Code WHERE("Norm Jurisdiction Code" = FIELD("Norm Jurisdiction Code"),
                                                                                                                    "Has Details" = CONST(true));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                CalcFields("Expression Type");
                if "Expression Type" = "Expression Type"::Compare then begin
                    TaxRegTermFormula.Reset();
                    TaxRegTermFormula.SetRange("Section Code", "Section Code");
                    TaxRegTermFormula.SetRange("Term Code", "Term Code");
                    TaxRegTermFormula.SetFilter("Line No.", '<>%1', "Line No.");
                    TaxRegTermFormula.ModifyAll("Account No.", "Account No.", false);
                    TaxRegTermFormula.Reset();
                end;
                if "Account No." <> xRec."Account No." then begin
                    TaxRegSection.Get("Section Code");
                    TaxRegSection.ValidateChangeDeclaration();
                end;
            end;
        }
        field(7; "Amount Type"; Option)
        {
            Caption = 'Amount Type';
            OptionCaption = ' ,Net Change,Debit,Credit';
            OptionMembers = " ","Net Change",Debit,Credit;

            trigger OnValidate()
            begin
                if "Account Type" = "Account Type"::"Net Change" then begin
                    if "Amount Type" = "Amount Type"::"Net Change" then
                        "Amount Type" := "Amount Type"::Debit;
                    if not ("Amount Type" in ["Amount Type"::Debit, "Amount Type"::Credit]) then
                        FieldError("Amount Type",
                          StrSubstNo(Text003, "Amount Type", "Account Type"));
                end else
                    if "Account Type" <> "Account Type"::"G/L Account" then
                        TestField("Amount Type", "Amount Type"::" ")
                    else
                        TestField("Amount Type");
                if "Amount Type" <> xRec."Amount Type" then begin
                    TaxRegSection.Get("Section Code");
                    TaxRegSection.ValidateChangeDeclaration();
                end;
            end;
        }
        field(8; "Bal. Account No."; Code[100])
        {
            Caption = 'Bal. Account No.';
            TableRelation = IF ("Expression Type" = CONST(Compare),
                                "Account Type" = CONST(Term)) "Tax Register Line Setup"."Tax Register No."
            ELSE
            IF ("Account Type" = CONST("Net Change")) "G/L Account"."No.";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                CalcFields("Expression Type");
                if ("Account Type" = "Account Type"::"Net Change") or
                   ("Expression Type" = "Expression Type"::Compare)
                then
                    TestField("Bal. Account No.");
                if "Bal. Account No." <> xRec."Bal. Account No." then begin
                    TaxRegSection.Get("Section Code");
                    TaxRegSection.ValidateChangeDeclaration();
                end;
            end;
        }
        field(9; "Process Sign"; Option)
        {
            Caption = 'Process Sign';
            OptionCaption = ' ,Skip Negative,Skip Positive,Always Positive,Always Negative';
            OptionMembers = " ","Skip Negative","Skip Positive","Always Positive","Always Negative";

            trigger OnValidate()
            begin
                if "Process Sign" <> xRec."Process Sign" then begin
                    TaxRegSection.Get("Section Code");
                    TaxRegSection.ValidateChangeDeclaration();
                end;
            end;
        }
        field(10; "Process Division by Zero"; Option)
        {
            Caption = 'Process Division by Zero';
            OptionCaption = 'Zero,One';
            OptionMembers = Zero,One;
        }
        field(13; "Section Code"; Code[10])
        {
            Caption = 'Section Code';
            NotBlank = true;
            TableRelation = "Tax Register Section";
        }
        field(14; "Norm Jurisdiction Code"; Code[10])
        {
            CalcFormula = Lookup ("Tax Register Section"."Norm Jurisdiction Code" WHERE(Code = FIELD("Section Code")));
            Caption = 'Norm Jurisdiction Code';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Section Code", "Term Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TaxRegSection.Get("Section Code");
        TaxRegSection.ValidateChangeDeclaration();
    end;

    trigger OnInsert()
    begin
        TaxRegSection.Get("Section Code");
        TaxRegSection.ValidateChangeDeclaration();
    end;

    trigger OnModify()
    begin
        TaxRegSection.Get("Section Code");
        TaxRegSection.ValidateChangeDeclaration();
    end;

    var
        TaxRegTermFormula: Record "Tax Register Term Formula";
        Text000: Label 'Operation must be + or -.';
        Text001: Label 'Operation must be * or /.';
        Text002: Label 'Operation must be Compare.';
        TaxRegSection: Record "Tax Register Section";
        Text003: Label 'cannot be %1 if Account Type is %2.';
}

