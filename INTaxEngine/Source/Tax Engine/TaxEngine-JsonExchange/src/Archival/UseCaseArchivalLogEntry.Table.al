table 20360 "Use Case Archival Log Entry"
{
    DataClassification = EndUserIdentifiableInformation;
    LookupPageId = "Use Case Archival Log Entries";
    DrillDownPageId = "Use Case Archival Log Entries";
    Access = Public;
    Extensible = true;
    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Case ID"; Guid)
        {
            DataClassification = EndUserPseudonymousIdentifiers;
            Caption = 'Case ID';
        }
        field(3; "Description"; Text[2000])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Description';
        }
        field(4; "Log Date-Time"; DateTime)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Log Date-Time';
        }
        field(5; "Version"; Decimal)
        {
            DataClassification = EndUserIdentifiableInformation;
            DecimalPlaces = 2 : 5;
            Caption = 'Version';
        }
        field(6; "Configuration Data"; Blob)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Configuration Data';
        }
        field(7; "Active Version"; Boolean)
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Active Version';
        }
        field(8; "Changed by"; Text[100])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'Changed By';
        }
        field(9; "User ID"; Code[50])
        {
            DataClassification = EndUserIdentifiableInformation;
            Caption = 'User ID';
            TableRelation = "User Setup";
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}