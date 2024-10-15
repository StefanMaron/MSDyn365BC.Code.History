table 17381 "Employee Journal Batch"
{
    Caption = 'Employee Journal Batch';
    LookupPageID = "Employee Journal Batches";

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            NotBlank = true;
            TableRelation = "Employee Journal Template";
        }
        field(2; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(3; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(4; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(5; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                if "No. Series" <> '' then begin
                    if "No. Series" = "Posting No. Series" then
                        Validate("Posting No. Series", '');
                end;
            end;
        }
        field(6; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                if ("Posting No. Series" = "No. Series") and ("Posting No. Series" <> '') then
                    FieldError("Posting No. Series", StrSubstNo(Text001, "Posting No. Series"));
                EmployeeJnlLine.SetRange("Journal Template Name", "Journal Template Name");
                EmployeeJnlLine.SetRange("Journal Batch Name", Name);
                EmployeeJnlLine.ModifyAll("Posting No. Series", "Posting No. Series");
                Modify;
            end;
        }
        field(21; "Template Type"; Option)
        {
            CalcFormula = Lookup ("Employee Journal Template".Type WHERE(Name = FIELD("Journal Template Name")));
            Caption = 'Template Type';
            Editable = false;
            FieldClass = FlowField;
            OptionCaption = 'Salary,Vacation';
            OptionMembers = Salary,Vacation;
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", Name)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        EmployeeJnlTemplate: Record "Employee Journal Template";
        EmployeeJnlLine: Record "Employee Journal Line";
        Text001: Label 'must not be %1';

    [Scope('OnPrem')]
    procedure SetupNewBatch()
    begin
        EmployeeJnlTemplate.Get("Journal Template Name");
        "No. Series" := EmployeeJnlTemplate."No. Series";
        "Posting No. Series" := EmployeeJnlTemplate."Posting No. Series";
        "Reason Code" := EmployeeJnlTemplate."Reason Code";
    end;
}

