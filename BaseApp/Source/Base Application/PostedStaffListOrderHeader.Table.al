table 17377 "Posted Staff List Order Header"
{
    Caption = 'Posted Staff List Order Header';
    LookupPageID = "Posted Staff List Orders";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(4; "HR Manager No."; Code[20])
        {
            Caption = 'HR Manager No.';
            TableRelation = Employee;
        }
        field(5; "Chief Accountant No."; Code[20])
        {
            Caption = 'Chief Accountant No.';
            TableRelation = Employee;
        }
        field(6; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(7; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(8; "HR Order No."; Code[20])
        {
            Caption = 'HR Order No.';
        }
        field(9; "HR Order Date"; Date)
        {
            Caption = 'HR Order Date';
        }
        field(10; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(15; Comment; Boolean)
        {
            CalcFormula = Exist ("HR Order Comment Line" WHERE("Table Name" = CONST("P.SL Order"),
                                                               "No." = FIELD("No."),
                                                               "Line No." = CONST(0)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure PrintOrder()
    begin
        // Reserved for FP
    end;
}

