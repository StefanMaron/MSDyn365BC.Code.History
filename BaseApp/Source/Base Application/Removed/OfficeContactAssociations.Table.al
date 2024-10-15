table 1625 "Office Contact Associations"
{
    Caption = 'Office Contact Associations';
    ObsoleteState = Removed;
    ObsoleteReason = 'Had to change the key field, so moved to Office Contact Details table.';
    ObsoleteTag = '15.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Contact No."; Code[20])
        {
            Caption = 'Contact No.';
        }
        field(2; "Business Relation Code"; Code[10])
        {
            Caption = 'Business Relation Code';
            TableRelation = "Business Relation";
        }
        field(3; "Associated Table"; Option)
        {
            Caption = 'Associated Table';
            OptionCaption = ' ,Customer,Vendor,Bank Account,Company';
            OptionMembers = " ",Customer,Vendor,"Bank Account",Company;
        }
        field(4; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if ("Associated Table" = const(Customer)) Customer
            else
            if ("Associated Table" = const(Vendor)) Vendor
            else
            if ("Associated Table" = const("Bank Account")) "Bank Account";
        }
        field(5; "Business Relation Description"; Text[100])
        {
            Caption = 'Business Relation Description';
            Editable = false;
        }
        field(6; "Contact Name"; Text[100])
        {
            Caption = 'Contact Name';
        }
        field(7; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Company,Contact Person';
            OptionMembers = Company,"Contact Person";
        }
        field(8; Company; Text[50])
        {
            Caption = 'Company';
            DataClassification = OrganizationIdentifiableInformation;
        }
    }

    keys
    {
        key(Key1; "Contact No.", Type, "Associated Table")
        {
        }
    }

    fieldgroups
    {
    }

    procedure GetContactNo() ContactNo: Code[20]
    begin
        if "Associated Table" = "Associated Table"::" " then
            ContactNo := "Contact No."
        else
            ContactNo := "No.";
    end;
}

