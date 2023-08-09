codeunit 5623 "FA MoveEntries"
{
    Permissions = TableData "FA Ledger Entry" = rm,
                  TableData "Maintenance Ledger Entry" = rm,
                  TableData "Ins. Coverage Ledger Entry" = rm;

    trigger OnRun()
    begin
    end;

    var
        FA: Record "Fixed Asset";
        FALedgEntry: Record "FA Ledger Entry";
        MaintenanceLedgEntry: Record "Maintenance Ledger Entry";
        InsCoverageLedgEntry: Record "Ins. Coverage Ledger Entry";
        AccountingPeriod: Record "Accounting Period";
        FiscalYearStartDate: Date;

        Text000: Label 'Only disposed fixed assets can be deleted.';
        Text001: Label 'You cannot delete a fixed asset that has ledger entries in a fiscal year that has not been closed yet.';
        Text002: Label 'The field %1 cannot be changed for a fixed asset with ledger entries.';
        Text003: Label 'The field %1 cannot be changed for a fixed asset with insurance coverage ledger entries.';

    procedure MoveFAEntries(FADeprBook: Record "FA Depreciation Book")
    begin
        ClearAll();
        FA.LockTable();
        FALedgEntry.LockTable();
        MaintenanceLedgEntry.LockTable();
        InsCoverageLedgEntry.LockTable();
        FA.Get(FADeprBook."FA No.");

        AccountingPeriod.SetCurrentKey(Closed);
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst() then
            FiscalYearStartDate := AccountingPeriod."Starting Date"
        else
            FiscalYearStartDate := 0D;

        FALedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Date");
        MaintenanceLedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Date");

        FALedgEntry.SetRange("FA No.", FADeprBook."FA No.");
        MaintenanceLedgEntry.SetRange("FA No.", FADeprBook."FA No.");

        FALedgEntry.SetRange("Depreciation Book Code", FADeprBook."Depreciation Book Code");
        MaintenanceLedgEntry.SetRange("Depreciation Book Code", FADeprBook."Depreciation Book Code");

        if FA."Budgeted Asset" then
            DeleteNo(FADeprBook)
        else begin
            if FALedgEntry.FindFirst() then
                if FADeprBook."Disposal Date" = 0D then
                    Error(Text000);

            FALedgEntry.SetFilter("FA Posting Date", '>=%1', FiscalYearStartDate);
            if FALedgEntry.FindFirst() then
                CreateError(0);

            MaintenanceLedgEntry.SetFilter("FA Posting Date", '>=%1', FiscalYearStartDate);
            if MaintenanceLedgEntry.FindFirst() then
                CreateError(0);

            FALedgEntry.SetRange("FA Posting Date");
            MaintenanceLedgEntry.SetRange("FA Posting Date");

            FALedgEntry.SetCurrentKey(
              "FA No.", "Depreciation Book Code", "FA Posting Category", "FA Posting Type", "Posting Date");
            MaintenanceLedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "Posting Date");

            FALedgEntry.SetFilter("Posting Date", '>=%1', FiscalYearStartDate);
            if FALedgEntry.FindFirst() then
                CreateError(0);
            MaintenanceLedgEntry.SetFilter("Posting Date", '>=%1', FiscalYearStartDate);
            if MaintenanceLedgEntry.FindFirst() then
                CreateError(0);

            FALedgEntry.SetRange("Posting Date");
            MaintenanceLedgEntry.SetRange("Posting Date");
            DeleteNo(FADeprBook);
        end;
    end;

    local procedure DeleteNo(var FADeprBook: Record "FA Depreciation Book")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteNo(FADeprBook, IsHandled);
        if IsHandled then
            exit;

        FALedgEntry.ModifyAll("FA No.", '');
        FALedgEntry.SetRange("FA No.");
        FALedgEntry.SetCurrentKey("Canceled from FA No.");
        FALedgEntry.SetRange("Canceled from FA No.", FADeprBook."FA No.");
        FALedgEntry.ModifyAll("Canceled from FA No.", '');

        MaintenanceLedgEntry.ModifyAll("FA No.", '');
        MoveFAInsuranceEntries(FADeprBook."FA No.");
    end;

    procedure MoveInsuranceEntries(Insurance: Record Insurance)
    begin
        with InsCoverageLedgEntry do begin
            Reset();
            LockTable();
            SetCurrentKey("Insurance No.");
            SetRange("Insurance No.", Insurance."No.");
            if Find('-') then
                repeat
                    "FA No." := '';
                    "Insurance No." := '';
                    Modify();
                until Next() = 0;
        end;
    end;

    procedure MoveFAInsuranceEntries(FANo: Code[20])
    begin
        with InsCoverageLedgEntry do begin
            SetCurrentKey("FA No.");
            SetRange("FA No.", FANo);
            if Find('-') then
                repeat
                    "Insurance No." := '';
                    "FA No." := '';
                    Modify();
                until Next() = 0;
        end;
    end;

    procedure ChangeBudget(FA: Record "Fixed Asset")
    begin
        FALedgEntry.Reset();
        MaintenanceLedgEntry.Reset();
        InsCoverageLedgEntry.Reset();

        FALedgEntry.LockTable();
        MaintenanceLedgEntry.LockTable();
        InsCoverageLedgEntry.LockTable();

        FALedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Date");
        MaintenanceLedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Date");
        InsCoverageLedgEntry.SetCurrentKey("FA No.");

        FALedgEntry.SetRange("FA No.", FA."No.");
        MaintenanceLedgEntry.SetRange("FA No.", FA."No.");
        InsCoverageLedgEntry.SetRange("FA No.", FA."No.");

        if FALedgEntry.FindFirst() then
            CreateError(1);
        if MaintenanceLedgEntry.FindFirst() then
            CreateError(1);
        if InsCoverageLedgEntry.Find('-') then
            CreateError(2);
    end;

    local procedure CreateError(CheckType: Option Delete,Budget,Insurance)
    var
        FA: Record "Fixed Asset";
    begin
        case CheckType of
            CheckType::Delete:
                Error(
                  Text001);
            CheckType::Budget:
                Error(
                  Text002,
                  FA.FieldCaption("Budgeted Asset"));
            CheckType::Insurance:
                Error(
                  Text003,
                  FA.FieldCaption("Budgeted Asset"));
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteNo(var FADepreciationBook: Record "FA Depreciation Book"; var IsHandled: Boolean)
    begin
    end;
}

