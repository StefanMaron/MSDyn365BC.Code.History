namespace Microsoft.CRM.Outlook;

using System.Reflection;

table 5300 "Outlook Synch. Entity"
{
    Caption = 'Outlook Synch. Entity';
    DataCaptionFields = "Code", Description;
    DataClassification = CustomerContent;
    PasteIsValid = false;
    ReplicateData = false;
    ObsoleteState = Removed;
    ObsoleteReason = 'Legacy outlook sync functionality has been removed.';
    ObsoleteTag = '22.0';

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[80])
        {
            Caption = 'Description';

        }
        field(3; "Table No."; Integer)
        {
            BlankZero = true;
            Caption = 'Table No.';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(4; "Table Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table),
                                                                           "Object ID" = field("Table No.")));
            Caption = 'Table Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; Condition; Text[250])
        {
            Caption = 'Condition';
            Editable = false;

            trigger OnValidate()
            var
                RecordRef: RecordRef;
            begin
                RecordRef.Open("Table No.");
                RecordRef.SetView(Condition);
                Condition := RecordRef.GetView(false);
            end;
        }
        field(6; "Outlook Item"; Text[80])
        {
            Caption = 'Outlook Item';
        }
        field(7; "Record GUID"; Guid)
        {
            Caption = 'Record GUID';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; "Record GUID")
        {
        }
    }

    fieldgroups
    {
    }
}
