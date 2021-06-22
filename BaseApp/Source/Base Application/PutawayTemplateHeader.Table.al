table 7307 "Put-away Template Header"
{
    Caption = 'Put-away Template Header';
    LookupPageID = "Put-away Template List";
    ReplicateData = true;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        PutAwayTemplateLine: Record "Put-away Template Line";
    begin
        PutAwayTemplateLine.SetRange("Put-away Template Code", Code);
        PutAwayTemplateLine.DeleteAll();
    end;
}

