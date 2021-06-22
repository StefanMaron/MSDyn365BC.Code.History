table 5060 "Contact Web Source"
{
    Caption = 'Contact Web Source';
    DrillDownPageID = "Contact Web Sources";

    fields
    {
        field(1; "Contact No."; Code[20])
        {
            Caption = 'Contact No.';
            NotBlank = true;
            TableRelation = Contact WHERE(Type = CONST(Company));
        }
        field(2; "Web Source Code"; Code[10])
        {
            Caption = 'Web Source Code';
            NotBlank = true;
            TableRelation = "Web Source";
        }
        field(3; "Search Word"; Text[30])
        {
            Caption = 'Search Word';
        }
        field(4; "Web Source Description"; Text[100])
        {
            CalcFormula = Lookup ("Web Source".Description WHERE(Code = FIELD("Web Source Code")));
            Caption = 'Web Source Description';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Contact Name"; Text[100])
        {
            CalcFormula = Lookup (Contact.Name WHERE("No." = FIELD("Contact No.")));
            Caption = 'Contact Name';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Contact No.", "Web Source Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure Launch()
    var
        WebSource: Record "Web Source";
    begin
        WebSource.Get("Web Source Code");
        WebSource.TestField(URL);
        HyperLink(StrSubstNo(WebSource.URL, "Search Word"));
    end;
}

