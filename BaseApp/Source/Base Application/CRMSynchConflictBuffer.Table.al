table 5374 "CRM Synch. Conflict Buffer"
{
    Caption = 'CRM Synch. Conflict Buffer';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Integration ID"; Guid)
        {
            Caption = 'Integration ID';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                CRMIntegrationRecord: Record "CRM Integration Record";
                RecRef: RecordRef;
                RecId: RecordId;
            begin
                CRMIntegrationRecord."Integration ID" := "Integration ID";
                CRMIntegrationRecord."Table ID" := "Table ID";
                if CRMIntegrationRecord.FindRecordId(RecId) then begin
                    "Record ID" := RecId;
                    Description := CopyStr(GetRecDescription, 1, MaxStrLen(Description));
                    "Record Exists" := RecRef.Get("Record ID");
                end;
            end;
        }
        field(3; "CRM ID"; Guid)
        {
            Caption = 'CRM ID';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                CRMIntegrationRecord: Record "CRM Integration Record";
                IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
                IntegrationTableMapping: Record "Integration Table Mapping";
                CRMSetupDefaults: Codeunit "CRM Setup Defaults";
                RecRef: RecordRef;
                FieldRef: FieldRef;
                TableID: Integer;
            begin
                if CRMIntegrationRecord.FindByCRMID("CRM ID") then begin
                    if CRMIntegrationRecord.GetLatestError(IntegrationSynchJobErrors) then begin
                        "Error Message" := IntegrationSynchJobErrors.Message;
                        "Failed On" := IntegrationSynchJobErrors."Date/Time";
                    end;
                    TableID := CRMIntegrationRecord.GetTableID();
                    if TableID <> 0 then begin
                        "Int. Table ID" := CRMSetupDefaults.GetCRMTableNo(TableID);
                        if CRMIntegrationRecord.GetCRMRecordRef("Int. Table ID", RecRef) then begin
                            FieldRef := RecRef.Field(CRMSetupDefaults.GetNameFieldNo(RecRef.Number));
                            "Int. Record ID" := RecRef.RecordId;
                            "Int. Description" := FieldRef.Value;
                            "Int. Record Exists" := true;

                            IntegrationTableMapping.SetRange("Table ID", "Table ID");
                            if IntegrationTableMapping.FindFirst then begin
                                FieldRef := RecRef.Field(IntegrationTableMapping."Int. Tbl. Modified On Fld. No.");
                                "Int. Modified On" := FieldRef.Value;
                            end;
                            RecRef.Close;
                        end;
                    end;
                end;
            end;
        }
        field(4; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                "Table Name" := GetTableCaption;
            end;
        }
        field(5; "Table Name"; Text[250])
        {
            Caption = 'Table Name';
            DataClassification = SystemMetadata;
        }
        field(6; "Record ID"; RecordID)
        {
            Caption = 'Record ID';
            DataClassification = SystemMetadata;
        }
        field(7; Description; Text[250])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
        field(8; "Modified On"; DateTime)
        {
            Caption = 'Modified On';
            DataClassification = SystemMetadata;
        }
        field(9; "Int. Table ID"; Integer)
        {
            Caption = 'Int. Table ID';
            DataClassification = SystemMetadata;
        }
        field(10; "Int. Record ID"; RecordID)
        {
            Caption = 'Int. Record ID';
            DataClassification = SystemMetadata;
        }
        field(11; "Int. Description"; Text[250])
        {
            Caption = 'Int. Description';
            DataClassification = SystemMetadata;
        }
        field(12; "Int. Modified On"; DateTime)
        {
            Caption = 'Int. Modified On';
            DataClassification = SystemMetadata;
        }
        field(13; "Error Message"; Text[250])
        {
            Caption = 'Error Message';
            DataClassification = SystemMetadata;
        }
        field(14; "Failed On"; DateTime)
        {
            Caption = 'Failed On';
            DataClassification = SystemMetadata;
        }
        field(15; "Deleted On"; DateTime)
        {
            Caption = 'Deleted On';
            ObsoleteState = Pending;
            ObsoleteReason = 'This field is obsolete and should not be used after Integration Record is deprecated.';
            DataClassification = SystemMetadata;
            ObsoleteTag = '16.0';
        }
        field(16; "Record Exists"; Boolean)
        {
            Caption = 'Record Exists';
            DataClassification = SystemMetadata;
        }
        field(17; "Int. Record Exists"; Boolean)
        {
            Caption = 'Int. Record Exists';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        NoPermissionToDeleteInCRMErr: Label 'You do not have permission to delete entities in Dynamics 365 Sales.';

    procedure DeleteCoupledRecords()
    var
        TempCRMSynchConflictBuffer: Record "CRM Synch. Conflict Buffer" temporary;
    begin
        TempCRMSynchConflictBuffer.Copy(Rec, true);
        if TempCRMSynchConflictBuffer.FindSet then
            repeat
                TempCRMSynchConflictBuffer.DeleteCoupledRecord;
            until TempCRMSynchConflictBuffer.Next = 0;
    end;

    procedure DeleteCoupledRecord()
    begin
        if IsOneRecordDeleted then
            if "Record Exists" then
                DeleteCoupledRecInNAV
            else
                DeleteCoupledRecInCRM;
    end;

    local procedure DeleteCoupledRecInCRM()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecRef: RecordRef;
    begin
        if CRMIntegrationRecord.FindByCRMID("CRM ID") then begin
            if CRMIntegrationRecord.GetCRMRecordRef("Int. Table ID", RecRef) then
                if not TryToDeleteCRMRecord(RecRef) then
                    Error(NoPermissionToDeleteInCRMErr);
            if CRMIntegrationRecord.Delete(true) then
                Delete;
        end;
    end;

    local procedure DeleteCoupledRecInNAV()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecRef: RecordRef;
    begin
        if CRMIntegrationRecord.FindByRecordID("Record ID") then begin
            RecRef.Get("Record ID");
            RecRef.Delete(true);
            if CRMIntegrationRecord.Delete(true) then
                Delete;
        end;
    end;

    procedure DeleteCouplings()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        TempCRMSynchConflictBuffer: Record "CRM Synch. Conflict Buffer" temporary;
        LocalRecordRef: RecordRef;
        LocalIdList: List of [Guid];
        IntegrationIdList: List of [Guid];
        LocalTableID: Integer;
        PrevLocalTableID: Integer;
        IntegrationTableID: Integer;
        PrevIntegrationTableID: Integer;
        LocalId: Guid;
        IntegrationId: Guid;
    begin
        TempCRMSynchConflictBuffer.Copy(Rec, true);
        TempCRMSynchConflictBuffer.SetCurrentKey("Table ID");
        if not TempCRMSynchConflictBuffer.FindSet() then
            exit;

        PrevLocalTableID := 0;
        PrevIntegrationTableID := 0;
        repeat
            LocalTableID := TempCRMSynchConflictBuffer."Table ID";
            IntegrationTableID := TempCRMSynchConflictBuffer."Int. Table ID";
            if LocalTableID <> PrevLocalTableID then begin
                if PrevLocalTableID <> 0 then begin
                    UncoupleLocalRecords(PrevLocalTableID, LocalIdList);
                    UncoupleIntegrationRecords(PrevLocalTableID, PrevIntegrationTableID, IntegrationIdList);
                    LocalIdList.RemoveRange(1, LocalIdList.Count());
                    IntegrationIdList.RemoveRange(1, IntegrationIdList.Count());
                    LocalRecordRef.Close();
                end;
                LocalRecordRef.Open(TempCRMSynchConflictBuffer."Table ID");
                PrevLocalTableID := TempCRMSynchConflictBuffer."Table ID";
                PrevIntegrationTableID := TempCRMSynchConflictBuffer."Int. Table ID";
            end;
            if TempCRMSynchConflictBuffer."Record Exists" then begin
                if LocalRecordRef.Get(TempCRMSynchConflictBuffer."Record ID") then begin
                    LocalId := LocalRecordRef.Field(LocalRecordRef.SystemIdNo()).Value();
                    if not IsNullGuid(LocalId) then
                        LocalIdList.Add(LocalId);
                end;
            end else begin
                IntegrationId := TempCRMSynchConflictBuffer."CRM ID";
                if TempCRMSynchConflictBuffer."Int. Record Exists" then begin
                    if not IsNullGuid(IntegrationId) then
                        IntegrationIdList.Add(IntegrationId);
                end else
                    CRMIntegrationRecord.RemoveCouplingToCRMID(IntegrationId, PrevLocalTableID);
            end;
        until TempCRMSynchConflictBuffer.Next() = 0;
        UncoupleLocalRecords(PrevLocalTableID, LocalIdList);
        UncoupleIntegrationRecords(PrevLocalTableID, IntegrationTableID, IntegrationIdList);
        TempCRMSynchConflictBuffer.DeleteAll();
    end;

    local procedure UncoupleLocalRecords(LocalTableId: Integer; var LocalIdList: List of [Guid])
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        if LocalTableId = 0 then
            exit;
        if LocalIdList.Count() = 0 then
            exit;
        CRMIntegrationManagement.RemoveCoupling(LocalTableId, LocalIdList);
    end;

    local procedure UncoupleIntegrationRecords(LocalTableId: Integer; IntegrationTableId: Integer; var IntegrationIdList: List of [Guid])
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        if LocalTableId = 0 then
            exit;
        if IntegrationTableId = 0 then
            exit;
        if IntegrationIdList.Count() = 0 then
            exit;
        CRMIntegrationManagement.RemoveCoupling(LocalTableId, IntegrationTableId, IntegrationIdList);
    end;

    procedure DeleteCoupling()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        TempCRMIntegrationRecord: Record "CRM Integration Record" temporary;
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
        RecId: RecordId;
    begin
        if "Record Exists" then begin
            CRMIntegrationRecord."Integration ID" := "Integration ID";
            CRMIntegrationRecord."Table ID" := "Table ID";
            CRMIntegrationRecord.FindRecordId(RecId);
            CRMCouplingManagement.RemoveCouplingWithTracking(RecId, TempCRMIntegrationRecord);
        end else
            CRMCouplingManagement.RemoveCouplingWithTracking("Table ID", "Int. Table ID", "CRM ID", TempCRMIntegrationRecord);
        TempCRMIntegrationRecord.SetRecFilter();
        UpdateSourceTable(TempCRMIntegrationRecord);
    end;

    procedure Fill(var CRMIntegrationRecord: Record "CRM Integration Record"): Integer
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        cnt: Integer;
        TableIdFilter: Text;
    begin
        DeleteAll();
        CRMIntegrationManagement.RepairBrokenCouplings(true);
        CRMIntegrationRecord.SetCurrentKey(Skipped, "Table ID");
        TableIdFilter := CRMIntegrationRecord.GetFilter("Table ID");
        if TableIdFilter = '' then
            CRMIntegrationRecord.SetFilter("Table ID", '<>0');
        if CRMIntegrationRecord.FindSet then
            repeat
                cnt += 1;
                "Entry No." += 1;
                InitFromCRMIntegrationRecord(CRMIntegrationRecord);
                if DoesOneRecordExist then
                    Insert
                else
                    CRMIntegrationRecord.Delete();
            until ((CRMIntegrationRecord.Next = 0) or (cnt = 100));
        exit(cnt);
    end;

    procedure GetRecDescription() Result: Text
    var
        RecRef: RecordRef;
        PKFilter: Text;
        Delimiter: Text;
        Pos: Integer;
    begin
        if RecRef.Get("Record ID") then begin
            RecRef.SetRecFilter;
            PKFilter := RecRef.GetView;
            repeat
                Pos := StrPos(PKFilter, '=FILTER(');
                if Pos <> 0 then begin
                    PKFilter := CopyStr(PKFilter, Pos + 8);
                    Result += Delimiter + CopyStr(PKFilter, 1, StrPos(PKFilter, ')') - 1);
                    Delimiter := ',';
                end;
            until Pos = 0;
        end;
    end;

    local procedure GetTableCaption(): Text[250]
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        if "Table ID" <> 0 then
            if AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, "Table ID") then
                exit(AllObjWithCaption."Object Caption");
    end;

    procedure InitFromCRMIntegrationRecord(CRMIntegrationRecord: Record "CRM Integration Record")
    begin
        Init();

        Validate("Table ID", CRMIntegrationRecord."Table ID");
        Validate("Integration ID", CRMIntegrationRecord."Integration ID");
        Validate("CRM ID", CRMIntegrationRecord."CRM ID");
    end;

    procedure IsOneRecordDeleted(): Boolean
    begin
        exit("Record Exists" xor "Int. Record Exists");
    end;

    procedure DoBothRecordsExist(): Boolean
    begin
        exit("Record Exists" and "Int. Record Exists");
    end;

    procedure DoesOneRecordExist(): Boolean
    begin
        exit("Record Exists" or "Int. Record Exists");
    end;

    procedure RestoreDeletedRecords()
    var
        TempCRMSynchConflictBuffer: Record "CRM Synch. Conflict Buffer" temporary;
    begin
        TempCRMSynchConflictBuffer.Copy(Rec, true);
        if TempCRMSynchConflictBuffer.FindSet then
            repeat
                TempCRMSynchConflictBuffer.RestoreDeletedRecord;
            until TempCRMSynchConflictBuffer.Next = 0;
    end;

    procedure RestoreDeletedRecord()
    begin
        if IsOneRecordDeleted then
            if "Record Exists" then
                RestoreDeletedRecordInCRM
            else
                RestoreDeletedRecordInNAV;
    end;

    local procedure RestoreDeletedRecordInCRM()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        RecRef: RecordRef;
    begin
        if CRMIntegrationRecord.FindByRecordID("Record ID") then
            CRMIntegrationRecord.Delete();
        RecRef.Get("Record ID");
        RecRef.SetRecFilter;
        CRMIntegrationManagement.CreateNewRecordsInCRM(RecRef);
        Delete;
    end;

    local procedure RestoreDeletedRecordInNAV()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        RecRef: RecordRef;
    begin
        if CRMIntegrationRecord.FindByCRMID("CRM ID") and
           CRMIntegrationRecord.GetCRMRecordRef("Int. Table ID", RecRef)
        then begin
            CRMIntegrationRecord.Delete();
            RecRef.SetRecFilter;
            CRMIntegrationManagement.CreateNewRecordsFromCRM(RecRef);
            Delete;
        end;
    end;

    procedure SetSelectionFilter(var CRMIntegrationRecord: Record "CRM Integration Record")
    begin
        SetRange("Record Exists", true);
        SetRange("Int. Record Exists", true);
        if FindSet then
            repeat
                if CRMIntegrationRecord.Get("CRM ID", "Integration ID") then
                    CRMIntegrationRecord.Mark(true);
            until Next = 0;
        CRMIntegrationRecord.MarkedOnly(true);
    end;

    [TryFunction]
    local procedure TryToDeleteCRMRecord(var RecRef: RecordRef)
    begin
        RecRef.Delete(true);
    end;

    procedure UpdateSourceTable(var CRMIntegrationRecord: Record "CRM Integration Record"): Integer
    var
        TempCRMSynchConflictBuffer: Record "CRM Synch. Conflict Buffer" temporary;
    begin
        if not CRMIntegrationRecord.Get("CRM ID", "Integration ID") then
            Delete;
        TempCRMSynchConflictBuffer.Copy(Rec, true);
        CRMIntegrationRecord.SetRange(Skipped, false);
        if CRMIntegrationRecord.FindSet then
            repeat
                TempCRMSynchConflictBuffer.SetRange("CRM ID", CRMIntegrationRecord."CRM ID");
                TempCRMSynchConflictBuffer.SetRange("Integration ID", CRMIntegrationRecord."Integration ID");
                TempCRMSynchConflictBuffer.DeleteAll();
            until CRMIntegrationRecord.Next = 0;
        exit(Count);
    end;
}

