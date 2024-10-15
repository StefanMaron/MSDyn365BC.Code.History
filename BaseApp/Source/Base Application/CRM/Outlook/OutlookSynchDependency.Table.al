namespace Microsoft.CRM.Outlook;

table 5311 "Outlook Synch. Dependency"
{
    Caption = 'Outlook Synch. Dependency';
    DataCaptionFields = "Synch. Entity Code";
    DataClassification = CustomerContent;
    PasteIsValid = false;
    ReplicateData = false;
    ObsoleteState = Removed;
    ObsoleteReason = 'Legacy outlook sync functionality has been removed.';
    ObsoleteTag = '22.0';

    fields
    {
        field(1; "Synch. Entity Code"; Code[10])
        {
            Caption = 'Synch. Entity Code';
            NotBlank = true;
            trigger OnValidate()
            begin
                TestField("Element No.");
            end;
        }
        field(2; "Element No."; Integer)
        {
            Caption = 'Element No.';
        }
        field(3; "Depend. Synch. Entity Code"; Code[10])
        {
            Caption = 'Depend. Synch. Entity Code';
        }
        field(4; Description; Text[80])
        {
            Caption = 'Description';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; Condition; Text[250])
        {
            Caption = 'Condition';
            Editable = false;
        }
        field(6; "Table Relation"; Text[250])
        {
            Caption = 'Table Relation';
            Editable = false;

            trigger OnValidate()
            begin
                TestField("Table Relation");
            end;
        }
        field(7; "Record GUID"; Guid)
        {
            Caption = 'Record GUID';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(8; "Depend. Synch. Entity Tab. No."; Integer)
        {
            Caption = 'Depend. Synch. Entity Tab. No.';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Synch. Entity Code", "Element No.", "Depend. Synch. Entity Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
