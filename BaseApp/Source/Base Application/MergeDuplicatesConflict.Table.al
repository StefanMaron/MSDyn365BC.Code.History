table 66 "Merge Duplicates Conflict"
{
    Caption = 'Merge Duplicates Conflict';
    ReplicateData = false;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                AllObjWithCaption: Record AllObjWithCaption;
            begin
                AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, "Table ID");
                "Table Name" := AllObjWithCaption."Object Caption";
            end;
        }
        field(2; Duplicate; RecordID)
        {
            Caption = 'Duplicate';
            DataClassification = CustomerContent;
        }
        field(3; Current; RecordID)
        {
            Caption = 'Current';
            DataClassification = CustomerContent;
        }
        field(4; "Field ID"; Integer)
        {
            Caption = 'Field ID';
            DataClassification = SystemMetadata;
        }
        field(5; "Table Name"; Text[249])
        {
            Caption = 'Table Name';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Table ID", Duplicate)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure Merge(): Boolean
    var
        MergeDuplicate: Page "Merge Duplicate";
    begin
        MergeDuplicate.SetConflict(Rec);
        MergeDuplicate.RunModal();
        exit(MergeDuplicate.IsConflictResolved());
    end;
}

