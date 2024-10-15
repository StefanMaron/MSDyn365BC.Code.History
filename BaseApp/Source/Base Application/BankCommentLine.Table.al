table 10122 "Bank Comment Line"
{
    Caption = 'Bank Comment Line';
    DrillDownPageID = "Bank Comment List";
    LookupPageID = "Bank Comment List";

    fields
    {
        field(1; "Table Name"; Option)
        {
            Caption = 'Table Name';
            OptionCaption = 'Bank Rec.,Posted Bank Rec.,Deposit,Posted Deposit';
            OptionMembers = "Bank Rec.","Posted Bank Rec.",Deposit,"Posted Deposit";
        }
        field(2; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            NotBlank = true;
            TableRelation = "Bank Account";
        }
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = IF ("Table Name" = CONST("Bank Rec.")) "Bank Rec. Header"."Statement No." WHERE("Bank Account No." = FIELD("Bank Account No."))
            ELSE
            IF ("Table Name" = CONST("Posted Bank Rec.")) "Posted Bank Rec. Header"."Statement No." WHERE("Bank Account No." = FIELD("Bank Account No."))
            ELSE
            IF ("Table Name" = CONST(Deposit)) "Deposit Header"
            ELSE
            IF ("Table Name" = CONST("Posted Deposit")) "Posted Deposit Header";
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; Date; Date)
        {
            Caption = 'Date';
        }
        field(6; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(7; Comment; Text[80])
        {
            Caption = 'Comment';
        }
    }

    keys
    {
        key(Key1; "Table Name", "Bank Account No.", "No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure SetUpNewLine()
    var
        CommentLine: Record "Bank Comment Line";
    begin
        CommentLine.SetRange("Table Name", "Table Name");
        CommentLine.SetRange("Bank Account No.", "Bank Account No.");
        CommentLine.SetRange("No.", "No.");
        if not CommentLine.FindFirst then
            Date := WorkDate;
    end;
}

