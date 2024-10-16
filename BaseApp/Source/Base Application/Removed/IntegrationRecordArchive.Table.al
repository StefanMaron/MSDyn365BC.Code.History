table 5152 "Integration Record Archive"
{
    Caption = 'Integration Record Archive';
    ObsoleteState = Removed;
    ObsoleteReason = 'This functionality will be replaced by the systemID field';
    ObsoleteTag = '22.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
        }
        field(2; "Page ID"; Integer)
        {
            Caption = 'Page ID';
        }
        field(3; "Record ID"; RecordID)
        {
            Caption = 'Record ID';
            DataClassification = CustomerContent;
        }
        field(194; "Webhook Notification"; BLOB)
        {
            Caption = 'Webhook Notification';
        }
        field(5150; "Integration ID"; Guid)
        {
            Caption = 'Integration ID';
        }
        field(5151; "Deleted On"; DateTime)
        {
            Caption = 'Deleted On';
        }
        field(5152; "Modified On"; DateTime)
        {
            Caption = 'Modified On';
        }
    }

    keys
    {
        key(Key1; "Integration ID")
        {
            Clustered = true;
        }
        key(Key2; "Record ID")
        {
        }
        key(Key3; "Page ID", "Deleted On")
        {
        }
        key(Key4; "Page ID", "Modified On")
        {
        }
        key(Key5; "Table ID", "Record ID")
        {
        }
    }

    fieldgroups
    {
    }

    procedure FindByIntegrationId(IntegrationId: Guid): Boolean
    begin
        if IsNullGuid(IntegrationId) then
            exit(false);

        exit(Get(IntegrationId));
    end;

    procedure FindByRecordId(FindRecordId: RecordID): Boolean
    begin
        if FindRecordId.TableNo = 0 then
            exit(false);

        Reset();
        SetCurrentKey("Table ID", "Record ID");
        SetRange("Table ID", FindRecordId.TableNo);
        SetRange("Record ID", FindRecordId);
        exit(FindFirst());
    end;
}

