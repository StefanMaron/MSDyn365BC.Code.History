table 17378 "Posted Staff List Order Line"
{
    Caption = 'Posted Staff List Order Line';

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Posted Staff List Order Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = ' ,Position,Org. Unit';
            OptionMembers = " ",Position,"Org. Unit";
        }
        field(4; "Code"; Code[20])
        {
            Caption = 'Code';
            TableRelation = IF (Type = CONST("Org. Unit")) "Organizational Unit"
            ELSE
            IF (Type = CONST(Position)) Position;
        }
        field(5; Name; Text[50])
        {
            Caption = 'Name';
            Editable = false;
        }
        field(6; "Action"; Option)
        {
            Caption = 'Action';
            OptionCaption = 'Approve,Reopen,Close,Rename';
            OptionMembers = Approve,Reopen,Close,Rename;
        }
        field(7; "New Name"; Text[50])
        {
            Caption = 'New Name';
        }
    }

    keys
    {
        key(Key1; "Document No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure ShowComments()
    var
        HROrderCommentLine: Record "HR Order Comment Line";
        HROrderCommentLines: Page "HR Order Comment Lines";
    begin
        TestField("Document No.");
        TestField("Line No.");
        HROrderCommentLine.SetRange("Table Name", HROrderCommentLine."Table Name"::"P.SL Order");
        HROrderCommentLine.SetRange("No.", "Document No.");
        HROrderCommentLine.SetRange("Line No.", "Line No.");
        HROrderCommentLines.SetTableView(HROrderCommentLine);
        HROrderCommentLines.RunModal;
    end;
}

