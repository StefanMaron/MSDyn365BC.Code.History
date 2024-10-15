namespace Microsoft.CRM.Outlook;

table 5310 "Outlook Synch. Setup Detail"
{
    Caption = 'Outlook Synch. Setup Detail';
    DataClassification = CustomerContent;
    ReplicateData = false;
    ObsoleteState = Removed;
    ObsoleteReason = 'Legacy outlook sync functionality has been removed.';
    ObsoleteTag = '22.0';

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            NotBlank = true;
        }
        field(2; "Synch. Entity Code"; Code[10])
        {
            Caption = 'Synch. Entity Code';
            Editable = false;
        }
        field(3; "Element No."; Integer)
        {
            Caption = 'Element No.';
            Editable = false;

            trigger OnValidate()
            begin
                CalcFields("Outlook Collection");
            end;
        }
        field(4; "Outlook Collection"; Text[80])
        {
            Caption = 'Outlook Collection';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Table No."; Integer)
        {
            Caption = 'Table No.';
        }
    }

    keys
    {
        key(Key1; "User ID", "Synch. Entity Code", "Element No.")
        {
            Clustered = true;
        }
        key(Key2; "Table No.")
        {
        }
    }

    fieldgroups
    {
    }
}
