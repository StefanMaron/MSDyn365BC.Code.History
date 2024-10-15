table 11605 "BAS Comment Line"
{
    Caption = 'BAS Comment Line';

    fields
    {
        field(1; "No."; Code[11])
        {
            Caption = 'No.';
            TableRelation = "BAS Calculation Sheet".A1;
        }
        field(2; "Version No."; Integer)
        {
            Caption = 'Version No.';
            TableRelation = "BAS Calculation Sheet"."BAS Version" WHERE(A1 = FIELD("No."));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; Comment; Text[80])
        {
            Caption = 'Comment';
        }
        field(5; Date; Date)
        {
            Caption = 'Date';
        }
    }

    keys
    {
        key(Key1; "No.", "Version No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure SetUpNewLine()
    var
        BASCommentLine: Record "BAS Comment Line";
    begin
        BASCommentLine.SetRange("No.", "No.");
        BASCommentLine.SetRange("Version No.", "Version No.");
        if not BASCommentLine.FindFirst then
            Date := WorkDate;
    end;
}

