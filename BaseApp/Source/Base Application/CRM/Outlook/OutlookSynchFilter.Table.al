namespace Microsoft.CRM.Outlook;

using System.Reflection;

table 5303 "Outlook Synch. Filter"
{
    Caption = 'Outlook Synch. Filter';
    DataCaptionFields = "Filter Type";
    DataClassification = CustomerContent;
    PasteIsValid = false;
    ReplicateData = false;
    ObsoleteState = Removed;
    ObsoleteReason = 'Legacy outlook sync functionality has been removed.';
    ObsoleteTag = '22.0';

    fields
    {
        field(1; "Record GUID"; Guid)
        {
            Caption = 'Record GUID';
            DataClassification = SystemMetadata;
            Editable = false;
            NotBlank = true;
        }
        field(2; "Filter Type"; Option)
        {
            Caption = 'Filter Type';
            OptionCaption = 'Condition,Table Relation';
            OptionMembers = Condition,"Table Relation";
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Table No."; Integer)
        {
            Caption = 'Table No.';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(5; "Field No."; Integer)
        {
            Caption = 'Field No.';
            TableRelation = Field."No." where(TableNo = field("Table No."));
        }
        field(7; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'CONST,FILTER,FIELD';
            OptionMembers = "CONST","FILTER","FIELD";
        }
        field(8; Value; Text[250])
        {
            Caption = 'Value';
        }
        field(9; "Master Table No."; Integer)
        {
            Caption = 'Master Table No.';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(10; "Master Table Field No."; Integer)
        {
            Caption = 'Master Table Field No.';
            TableRelation = Field."No." where(TableNo = field("Master Table No."));
        }
        field(99; FilterExpression; Text[250])
        {
            Caption = 'FilterExpression';
        }
    }

    keys
    {
        key(Key1; "Record GUID", "Filter Type", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Table No.", "Field No.")
        {
        }
    }

    fieldgroups
    {
    }
}
