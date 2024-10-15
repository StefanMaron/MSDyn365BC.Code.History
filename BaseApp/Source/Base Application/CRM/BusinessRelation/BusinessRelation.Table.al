namespace Microsoft.CRM.BusinessRelation;

table 5053 "Business Relation"
{
    Caption = 'Business Relation';
    DataCaptionFields = "Code", Description;
    DataClassification = CustomerContent;
    LookupPageID = "Business Relations";

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
        field(3; "No. of Contacts"; Integer)
        {
            CalcFormula = count ("Contact Business Relation" where("Business Relation Code" = field(Code)));
            Caption = 'No. of Contacts';
            Editable = false;
            FieldClass = FlowField;
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
}

