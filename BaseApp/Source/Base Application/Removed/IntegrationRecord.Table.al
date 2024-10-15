table 5151 "Integration Record"
{
    Caption = 'Integration Record';
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
        key(Key6; "Table ID", "Modified On")
        {
        }
    }

    fieldgroups
    {
    }

    var
#pragma warning disable AA0470
        CannotInsertWithNullIntegrationIdErr: Label 'Integration ID cannot be null. Table %1';
#pragma warning restore AA0470

    trigger OnInsert()
    var
        CannotInsertWithNullIntIdErrorInfo: ErrorInfo;
    begin
        if IsNullGuid("Integration ID") then begin
            CannotInsertWithNullIntIdErrorInfo.DataClassification := DataClassification::SystemMetadata;
            CannotInsertWithNullIntIdErrorInfo.ErrorType := ErrorType::Internal;
            CannotInsertWithNullIntIdErrorInfo.Message := StrSubstNo(CannotInsertWithNullIntegrationIdErr, "Table ID");
            Error(CannotInsertWithNullIntIdErrorInfo);
        end;

        "Modified On" := CurrentDateTime;
    end;

    trigger OnModify()
    begin
        "Modified On" := CurrentDateTime;
    end;

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

    internal procedure FindBySystemId(FindRecordId: RecordID; ParentSystemId: Guid): Boolean
    begin
        if FindRecordId.TableNo = 0 then
            exit(false);

        // It is possible to use RecordID to find records via temporary tables
        // that don't have the systemID set but use RecordId to find the parent
        // We need to support this get in order not to break existing scenarios
        if IsNullGuid(ParentSystemId) then
            exit(FindByRecordId(FindRecordId));

        Reset();
        if not Rec.Get(ParentSystemId) then
            exit(false);

        if (Rec."Record ID" <> FindRecordId) or (Rec."Table ID" <> FindRecordId.TableNo()) then begin
            // Tables are out of sync, fix on the fly
            Rec."Record ID" := FindRecordId;
            Rec."Table ID" := FindRecordId.TableNo();
            Rec.Modify(true);
        end;

        exit(true);
    end;
}
