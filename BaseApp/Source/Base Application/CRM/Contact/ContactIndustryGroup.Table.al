namespace Microsoft.CRM.Contact;

using Microsoft.CRM.Setup;

table 5058 "Contact Industry Group"
{
    Caption = 'Contact Industry Group';
    DrillDownPageID = "Contact Industry Groups";

    fields
    {
        field(1; "Contact No."; Code[20])
        {
            Caption = 'Contact No.';
            NotBlank = true;
            TableRelation = Contact where(Type = const(Company));
        }
        field(2; "Industry Group Code"; Code[10])
        {
            Caption = 'Industry Group Code';
            NotBlank = true;
            TableRelation = "Industry Group";
        }
        field(3; "Industry Group Description"; Text[100])
        {
            CalcFormula = Lookup("Industry Group".Description where(Code = field("Industry Group Code")));
            Caption = 'Industry Group Description';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Contact Name"; Text[100])
        {
            CalcFormula = Lookup(Contact.Name where("No." = field("Contact No.")));
            Caption = 'Contact Name';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Contact No.", "Industry Group Code")
        {
            Clustered = true;
        }
        key(Key2; "Industry Group Code")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        Contact: Record Contact;
    begin
        Contact.TouchContact("Contact No.");
    end;

    trigger OnInsert()
    var
        Contact: Record Contact;
    begin
        Contact.TouchContact("Contact No.");
    end;

    trigger OnModify()
    var
        Contact: Record Contact;
    begin
        Contact.TouchContact("Contact No.");
    end;

    trigger OnRename()
    var
        Contact: Record Contact;
    begin
        if xRec."Contact No." = "Contact No." then
            Contact.TouchContact("Contact No.")
        else begin
            Contact.TouchContact("Contact No.");
            Contact.TouchContact(xRec."Contact No.");
        end;
    end;
}

