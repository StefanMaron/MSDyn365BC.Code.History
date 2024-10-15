namespace Microsoft.CRM.Outlook;

using System.Reflection;

table 5301 "Outlook Synch. Entity Element"
{
    Caption = 'Outlook Synch. Entity Element';
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
        }
        field(2; "Element No."; Integer)
        {
            Caption = 'Element No.';
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
        field(5; "Table Relation"; Text[250])
        {
            Caption = 'Table Relation';
            Editable = false;

            trigger OnValidate()
            begin
                TestField("Table Relation");
            end;
        }
        field(6; "Outlook Collection"; Text[80])
        {
            Caption = 'Outlook Collection';

        }
        field(7; "Master Table No."; Integer)
        {
            Caption = 'Master Table No.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "Record GUID"; Guid)
        {
            Caption = 'Record GUID';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(9; "No. of Dependencies"; Integer)
        {
            Caption = 'No. of Dependencies';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Synch. Entity Code", "Element No.")
        {
            Clustered = true;
        }
        key(Key2; "Table No.")
        {
        }
        key(Key3; "Record GUID")
        {
        }
    }

    fieldgroups
    {
    }
}
