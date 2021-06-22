codeunit 5455 "Graph Data Setup"
{

    trigger OnRun()
    begin
        OnCreateIntegrationMappings;
    end;

    procedure AddIntgrationFieldMapping(MappingName: Text[20]; NavFieldNo: Integer; IntegrationFieldNo: Integer; ValidateField: Boolean)
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        with IntegrationFieldMapping do begin
            Init;
            "Integration Table Mapping Name" := MappingName;
            "Field No." := NavFieldNo;
            "Integration Table Field No." := IntegrationFieldNo;
            Direction := Direction::Bidirectional;
            "Validate Field" := ValidateField;
            Insert(true);
        end;
    end;

    procedure AddIntegrationTableMapping(MappingName: Code[20]; TableID: Integer; IntTableID: Integer; IntTableUIDFldNo: Integer; IntTableModFldNo: Integer; ParentName: Text[20]; IntTableDeltaTokenFldNo: Integer; IntTableChangeKeyFldNo: Integer; IntTableStateFldNo: Integer)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        with IntegrationTableMapping do begin
            Init;
            Name := MappingName;
            "Table ID" := TableID;
            "Integration Table ID" := IntTableID;
            "Integration Table UID Fld. No." := IntTableUIDFldNo;
            "Int. Tbl. Modified On Fld. No." := IntTableModFldNo;
            "Synch. Codeunit ID" := CODEUNIT::"Graph Integration Table Sync";
            Direction := Direction::Bidirectional;
            "Synch. Only Coupled Records" := false;
            "Parent Name" := ParentName;
            "Int. Tbl. Delta Token Fld. No." := IntTableDeltaTokenFldNo;
            "Int. Tbl. ChangeKey Fld. No." := IntTableChangeKeyFldNo;
            "Int. Tbl. State Fld. No." := IntTableStateFldNo;
            if not Insert(true) then
                Modify(true);
        end;
    end;

    procedure CanSyncRecord(EntityRecRef: RecordRef) CanSync: Boolean
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
        EmptyRecordRef: RecordRef;
        FieldRef: FieldRef;
        EmptyFieldRef: FieldRef;
        MappingName: Code[20];
        Handled: Boolean;
    begin
        // Determines whether the record is empty based on the fields
        // within the integration field mapping table

        OnCheckCanSyncRecord(EntityRecRef, CanSync, Handled);
        if Handled then
            exit;

        EmptyRecordRef.Open(EntityRecRef.Number);
        EmptyRecordRef.Init();

        MappingName := GetMappingCodeForTable(EntityRecRef.Number);
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", MappingName);
        if IntegrationFieldMapping.FindSet then
            repeat
                FieldRef := EntityRecRef.Field(IntegrationFieldMapping."Field No.");
                EmptyFieldRef := EmptyRecordRef.Field(IntegrationFieldMapping."Field No.");
                CanSync := FieldRef.Value <> EmptyFieldRef.Value;
            until (IntegrationFieldMapping.Next = 0) or CanSync;
    end;

    procedure ClearIntegrationMapping(MappingCode: Code[20])
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        IntegrationTableMapping.SetRange(Name, MappingCode);
        IntegrationTableMapping.DeleteAll(true);
    end;

    procedure CreateIntegrationMapping(MappingCode: Code[20])
    begin
        if IntegrationMappingExists(MappingCode) then
            ClearIntegrationMapping(MappingCode);
        AddIntegrationMapping(MappingCode);
    end;

    procedure GetGraphRecord(var GraphRecordRef: RecordRef; DestinationGraphID: Text[250]; TableID: Integer) Found: Boolean
    begin
        OnGetGraphRecord(GraphRecordRef, DestinationGraphID, TableID, Found);
    end;

    procedure GetInboundTableID(MappingCode: Code[20]) TableID: Integer
    begin
        OnGetInboundTableID(MappingCode, TableID);
    end;

    procedure GetIntegrationTableMapping(var IntegrationTableMapping: Record "Integration Table Mapping"; MappingCode: Code[20])
    var
        GraphDataSetup: Codeunit "Graph Data Setup";
        IntegrationManagement: Codeunit "Integration Management";
        InsertEnabled: Boolean;
        ModifyEnabled: Boolean;
        DeleteEnabled: Boolean;
        RenameEnabled: Boolean;
    begin
        if not IntegrationTableMapping.Get(MappingCode) then begin
            GraphDataSetup.CreateIntegrationMapping(MappingCode);
            IntegrationTableMapping.Get(MappingCode)
        end;

        // This code is needed to make sure the integration for the table is set
        IntegrationManagement.GetDatabaseTableTriggerSetup(
          IntegrationTableMapping."Table ID", InsertEnabled, ModifyEnabled, DeleteEnabled, RenameEnabled);
    end;

    procedure GetMappingCodeForTable(TableID: Integer) MappingCode: Code[20]
    begin
        OnGetMappingCodeForTable(TableID, MappingCode);
    end;

    procedure IntegrationMappingExists(MappingCode: Code[20]): Boolean
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        if not IntegrationTableMapping.Get(MappingCode) then
            exit(false);

        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", MappingCode);
        exit(not IntegrationFieldMapping.IsEmpty);
    end;

    local procedure AddIntegrationMapping(MappingCode: Code[20])
    var
        TableID: Integer;
    begin
        OnGetInboundTableID(MappingCode, TableID);
        OnAddIntegrationMapping(MappingCode);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddIntegrationMapping(MappingCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCanSyncRecord(EntityRecordRef: RecordRef; var CanSyncRecord: Boolean; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateIntegrationMappings()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetGraphRecord(var GraphRecordRef: RecordRef; DestinationGraphID: Text[250]; TableID: Integer; var Found: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetInboundTableID(MappingCode: Code[20]; var TableID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetMappingCodeForTable(TableID: Integer; var MappingCode: Code[20])
    begin
    end;
}

