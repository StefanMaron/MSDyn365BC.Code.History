table 20291 "Use Case Event"
{
    LookupPageID = "Use Case Events";
    DrillDownPageID = "Use Case Events";
    Caption = 'Use Case Event';
    DataClassification = EndUserIdentifiableInformation;
    Access = Public;
    Extensible = false;
    fields
    {
        field(1; Name; Text[100])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Name';
        }
        field(2; "Table ID"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Table ID';
        }
        field(3; Description; Text[250])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Description';
        }
        field(4; "Table Name"; Text[30])
        {
            DataClassification = SystemMetadata;
            Caption = 'Table Name';
            Editable = false;
        }
        field(5; Indentation; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Indentation';
        }
        field(6; "Dummy Event"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Dummy Event';
        }
        field(7; "Presentation Order"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Presentation Order';
        }
        field(8; Enable; Boolean)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Enable';
        }
    }

    keys
    {
        key(K0; Name)
        {
            Clustered = True;
        }
        key(Key2; "Presentation Order") { }
        key(Key3; Enable) { }
    }
}