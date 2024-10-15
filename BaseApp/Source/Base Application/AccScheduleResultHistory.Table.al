table 31088 "Acc. Schedule Result History"
{
    Caption = 'Acc. Schedule Result History';
    ObsoleteState = Removed;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '22.0';

    fields
    {
        field(1; "Result Code"; Code[20])
        {
            Caption = 'Result Code';
        }
        field(2; "Row No."; Integer)
        {
            Caption = 'Row No.';
        }
        field(3; "Column No."; Integer)
        {
            Caption = 'Column No.';
        }
        field(4; "Variant No."; Integer)
        {
            Caption = 'Variant No.';
        }
        field(10; "New Value"; Decimal)
        {
            Caption = 'New Value';
        }
        field(11; "Old Value"; Decimal)
        {
            Caption = 'Old Value';
        }
        field(12; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(13; "Modified DateTime"; DateTime)
        {
            Caption = 'Modified DateTime';
        }
    }

    keys
    {
        key(Key1; "Result Code", "Row No.", "Column No.", "Variant No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        "User ID" := UserId;
        "Modified DateTime" := CurrentDateTime;
    end;
}

