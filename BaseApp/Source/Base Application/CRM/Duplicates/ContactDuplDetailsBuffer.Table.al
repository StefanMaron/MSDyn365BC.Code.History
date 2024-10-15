namespace Microsoft.CRM.Duplicates;

using Microsoft.CRM.Contact;

table 5113 "Contact Dupl. Details Buffer"
{
    Caption = 'Contact Dupl. Details Buffer';
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; "Field No."; Integer)
        {
            Caption = 'Field No.';
        }
        field(2; "Field Name"; Text[30])
        {
            Caption = 'Field Name';
        }
        field(3; "Field Value"; Text[250])
        {
            Caption = 'Field Value';
        }
        field(4; "Duplicate Field Value"; Text[250])
        {
            Caption = 'Duplicate Field Value';
        }
    }

    keys
    {
        key(Key1; "Field No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure CreateContactDuplicateDetails(ContactNo: Code[20]; DuplicateContactNo: Code[20])
    var
        DuplicateSearchStringSetup: Record "Duplicate Search String Setup";
        Contact: Record Contact;
        DuplicateContact: Record Contact;
        ContactRecRef: RecordRef;
        DuplicateContactRecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        if (ContactNo = '') or (DuplicateContactNo = '') then
            exit;

        Contact.Get(ContactNo);
        DuplicateContact.Get(DuplicateContactNo);
        ContactRecRef.GetTable(Contact);
        DuplicateContactRecRef.GetTable(DuplicateContact);

        DuplicateSearchStringSetup.FindSet();
        repeat
            Init();
            "Field No." := DuplicateSearchStringSetup."Field No.";
            "Field Name" := DuplicateSearchStringSetup."Field Name";
            FieldRef := ContactRecRef.Field("Field No.");
            "Field Value" := FieldRef.Value();
            FieldRef := DuplicateContactRecRef.Field("Field No.");
            "Duplicate Field Value" := FieldRef.Value();
            if Insert() then;
        until DuplicateSearchStringSetup.Next() = 0;
    end;
}

