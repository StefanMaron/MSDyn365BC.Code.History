codeunit 3994 "Reten. Pol. Doc. Arch. Fltrng." Implements "Reten. Pol. Filtering"
{
    Access = Internal;

    var
        MissingReadPermissionLbl: Label 'The user does not have Read permission for table %1, %2.', Comment = '%1 = table number, %2 = table caption';
        NoRecordsToDeleteLbl: Label 'There are no records to delete for table ID %1, %2.', Comment = '%1 = a id of a table (integer), %2 = the caption of the table.';
        MinExpirationDateErr: Label 'The expiration date for table %1, %2 must be at least %3 days before the current date. Please update the retention policy.', Comment = '%1 = table number, %2 = table caption, %3 = integer';

    procedure HasReadPermission(TableId: Integer): Boolean
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(TableId);
        exit(RecRef.ReadPermission())
    end;

    procedure Count(RecRef: RecordRef): Integer
    begin
        exit(RecRef.Count())
    end;

    procedure ApplyRetentionPolicyAllRecordFilters(RetentionPolicySetup: Record "Retention Policy Setup"; var RecRef: RecordRef; var RetenPolFilteringParam: Record "Reten. Pol. Filtering Param" temporary): Boolean
    begin
        // not used
    end;

    procedure ApplyRetentionPolicySubSetFilters(RetentionPolicySetup: Record "Retention Policy Setup"; var RecRef: RecordRef; var RetenPolFilteringParam: Record "Reten. Pol. Filtering Param" temporary): Boolean
    var
        RetentionPolicyLog: Codeunit "Retention Policy Log";
    begin
        RecRef.Open(RetentionPolicySetup."Table ID");
        if not RecRef.ReadPermission() then begin
            RetentionPolicyLog.LogWarning(LogCategory(), StrSubstNo(MissingReadPermissionLbl, RecRef.Number, RecRef.Caption));
            exit(false);
        end;

        // Pass 1: Mark Records to delete
        MarkRecordRefWithRecordsToDelete(RetentionPolicySetup, RecRef, RetenPolFilteringParam);
        // Pass 2: UnMark Records to keep
        UnMarkRecordRefWithRecordsToKeep(RetentionPolicySetup, RecRef, RetenPolFilteringParam);
        // Delete remaining Marked records
        RecRef.MarkedOnly(true);

        if not RecRef.IsEmpty() then
            exit(true);

        RetentionPolicyLog.LogInfo(LogCategory(), StrSubstNo(NoRecordsToDeleteLbl, RetentionPolicySetup."Table Id", RetentionPolicySetup."Table Caption"));
        exit(false);
    end;

    local procedure CalculateExpirationDate(RetentionPeriod: Record "Retention Period"): Date
    var
        RetentionPeriodInterface: Interface "Retention Period";
    begin
        RetentionPeriodInterface := RetentionPeriod."Retention Period";
        exit(RetentionPeriodInterface.CalculateExpirationDate(RetentionPeriod, Today()));
    end;

    local procedure ValidateExpirationDate(ExpirationDate: Date; TableId: Integer; TableCaption: Text)
    var
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
        RetentionPolicyLog: Codeunit "Retention Policy Log";
        MinExpirationDate: Date;
    begin
        if ExpirationDate > Today() then // a future expiration date means keep forever
            exit;
        MinExpirationDate := RetenPolAllowedTables.CalcMinimumExpirationDate(TableId);
        if ExpirationDate > MinExpirationDate then
            RetentionPolicyLog.LogError(LogCategory(), StrSubstNo(MinExpirationDateErr, TableId, TableCaption, RetenPolAllowedTables.GetMandatoryMinimumRetentionDays(TableId)));
    end;

    local procedure MarkRecordRefWithRecordsToDelete(RetentionPolicySetup: Record "Retention Policy Setup"; var RecRef: RecordRef; var RetenPolFilteringParam: Record "Reten. Pol. Filtering Param" temporary)
    begin
        SetMarksOnRecordRef(RetentionPolicySetup, RecRef, true, RetenPolFilteringParam);
    end;

    local procedure UnMarkRecordRefWithRecordsToKeep(RetentionPolicySetup: Record "Retention Policy Setup"; RecRef: RecordRef; var RetenPolFilteringParam: Record "Reten. Pol. Filtering Param" temporary)
    begin
        SetMarksOnRecordRef(RetentionPolicySetup, RecRef, false, RetenPolFilteringParam);
    end;

    local procedure SetMarksOnRecordRef(RetentionPolicySetup: Record "Retention Policy Setup"; RecRef: RecordRef; MarkValue: boolean; var RetenPolFilteringParam: Record "Reten. Pol. Filtering Param" temporary);
    var
        RetentionPolicySetupLine: Record "Retention Policy Setup Line";
        RetentionPeriod: Record "Retention Period";
        ApplyRetentionPolicy: Codeunit "Apply Retention Policy";
        ExpirationDate: Date;
        UsingKeepLastVersion: Boolean;
    begin
        UsingKeepLastVersion := UseKeepLastVersion(RetentionPolicySetup."Table ID");
        RetentionPolicySetupLine.SetRange("Table ID", RetentionPolicySetup."Table ID");
        RetentionPolicySetupLine.SetRange(Enabled, true);
        if RetentionPolicySetupLine.FindSet(false, false) then
            repeat
                if RetentionPeriod.Get(RetentionPolicySetupLine."Retention Period") then begin
                    ExpirationDate := CalculateExpirationDate(RetentionPeriod);
                    if MarkValue then begin
                        RetentionPolicySetupLine.CalcFields("Table Caption");
                        ValidateExpirationDate(ExpirationDate, RetentionPolicySetupLine."Table ID", RetentionPolicySetupLine."Table Caption");
                    end;
                    // set filter for Table Filter in filtergroup 10
                    SetRetentionPolicyLineTableFilter(RetentionPolicySetupLine, RecRef, 10);
                    // set filter for date in filtergroup 11
                    if MarkValue then
                        ApplyRetentionPolicy.SetWhereOlderExpirationDateFilter(RetentionPolicySetupLine."Date Field No.", ExpirationDate, RecRef, 11, RetenPolFilteringParam."Null Date Replacement value")
                    else
                        // if ExpirationDate is >= today - 1, don't set filter and remove all records from temp
                        if ExpirationDate < Yesterday() then
                            ApplyRetentionPolicy.SetWhereNewerExpirationDateFilter(RetentionPolicySetupLine."Date Field No.", ExpirationDate, RecRef, 11, RetenPolFilteringParam."Null Date Replacement value");

                    if RecRef.FindSet(false, false) then
                        repeat
                            if MarkValue then begin
                                if RetentionPolicySetupLine."Keep last version" then begin
                                    if not IsMaxArchivedVersion(RecRef) then
                                        RecRef.Mark := true
                                end else
                                    RecRef.Mark := true;
                            end else begin
                                if ExpirationDate > Yesterday() then // if ExpirationDate is >= today - 1 remove all records from temp
                                    RecRef.Mark := false;
                                if UsingKeepLastVersion and (not RetentionPolicySetupLine."Keep Last Version") then begin
                                    if IsMaxArchivedVersion(RecRef) then
                                        RecRef.Mark := false;
                                end else
                                    RecRef.Mark := false;
                            end;
                        until RecRef.Next() = 0;
                end;
                ClearFilterGroupOnRecRef(RecRef, 10);
                ClearFilterGroupOnRecRef(RecRef, 11);
            until RetentionPolicySetupLine.Next() = 0;
    end;

    local procedure UseKeepLastVersion(TableId: Integer): boolean
    var
        RetentionPolicySetupLine: Record "Retention Policy Setup Line";
    begin
        RetentionPolicySetupLine.SetRange("Table ID", TableId);
        RetentionPolicySetupLine.SetRange(Enabled, true);
        RetentionPolicySetupLine.SetRange("Keep Last Version", true);
        exit(not RetentionPolicySetupLine.IsEmpty())
    end;

    local procedure IsMaxArchivedVersion(RecRef: RecordRef): Boolean
    var
        SalesHeaderArchive: Record "Sales Header Archive";
        PurchaseHeaderArchive: Record "Purchase Header Archive";
        VersionFieldRef: FieldRef;
        MaxVersionFieldRef: FieldRef;
        Version: Integer;
        MaxVersion: Integer;
    begin
        case RecRef.Number of
            Database::"Sales Header Archive":
                begin
                    VersionFieldRef := RecRef.Field(SalesHeaderArchive.FieldNo("Version No."));
                    MaxVersionFieldRef := RecRef.Field(SalesHeaderArchive.FieldNo("No. of Archived Versions"));
                end;
            Database::"Purchase Header Archive":
                begin
                    VersionFieldRef := RecRef.Field(PurchaseHeaderArchive.FieldNo("Version No."));
                    MaxVersionFieldRef := RecRef.Field(PurchaseHeaderArchive.FieldNo("No. of Archived Versions"));
                end;

            else
                exit(false);
        end;
        MaxVersionFieldRef.CalcField();
        Version := VersionFieldRef.Value();
        MaxVersion := MaxVersionFieldRef.Value();
        exit(Version = MaxVersion);
    end;

    local procedure SetRetentionPolicyLineTableFilter(var RetentionPolicySetupLine: Record "Retention Policy Setup Line"; var RecRef: RecordRef; FilterGroup: Integer);
    begin
        RecRef.FilterGroup := FilterGroup;
        RecRef.SetView(RetentionPolicySetupLine.GetTableFilterView());
    end;

    local procedure ClearFilterGroupOnRecRef(var RecRef: RecordRef; FilterGroup: Integer)
    begin
        RecRef.FilterGroup := FilterGroup;
        RecRef.SetView('');
    end;

    local procedure LogCategory(): Enum "Retention Policy Log Category"
    var
        RetentionPolicyLogCategory: Enum "Retention Policy Log Category";
    begin
        exit(RetentionPolicyLogCategory::"Retention Policy - Apply");
    end;

    local procedure Yesterday(): Date
    begin
        Exit(CalcDate('<-1D>', Today()))
    end;
}