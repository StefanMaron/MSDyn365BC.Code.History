codeunit 10500 "IRS 1099 Management"
{

    trigger OnRun()
    begin
    end;

    var
        BlockIfUpgradeNeededErr: Label 'You must update the form boxes in the 1099 Forms-Boxes window before you can run this report.';
        UpgradeFormBoxesNotificationMsg: Label 'The list of 1099 form boxes is not up to date. Update: %1.', Comment = '%1 = year';
        UpgradeFormBoxesMsg: Label 'Upgrade the form boxes.';
        ScheduleUpgradeFormBoxesMsg: Label 'Schedule an update of the form boxes.';
        UpgradeFormBoxesScheduledMsg: Label 'A job queue entry has been created.\\Make sure Earliest Start Date/Time field in the Job Queue Entry Card window is correct, and then choose the Set Status to Ready action to schedule a background job.';
        ConfirmUpgradeNowQst: Label 'The update process can take a while and block other users activities. Do you want to start the update now?';
        FormBoxesUpgradedMsg: Label 'The 1099 form boxes are successfully updated.';
        UnkownCodeErr: Label 'Invoice %1 for vendor %2 has unknown 1099 code %3.', Comment = '%1 = document number;%2 = vendor number;%3 = IRS 1099 code.';
        IRS1099CodeHasNotBeenSetupErr: Label 'IRS1099 code %1 was not set up during the initialization.', Comment = '%1 = misc code';
        February2020Lbl: Label 'February 2020';

    procedure Calculate1099Amount(var Invoice1099Amount: Decimal; var Amounts: array[20] of Decimal; Codes: array[20] of Code[10]; LastLineNo: Integer; VendorLedgerEntry: Record "Vendor Ledger Entry"; AppliedAmount: Decimal)
    begin
        VendorLedgerEntry.CalcFields(Amount);
        Invoice1099Amount := -AppliedAmount * VendorLedgerEntry."IRS 1099 Amount" / VendorLedgerEntry.Amount;
        UpdateLines(
          Amounts, Codes, LastLineNo, VendorLedgerEntry, VendorLedgerEntry."IRS 1099 Code", Invoice1099Amount);
    end;

    procedure Run1099MiscReport()
    begin
        if Upgrade2020Needed then
            REPORT.Run(REPORT::"Vendor 1099 Misc")
        else
            REPORT.Run(REPORT::"Vendor 1099 Misc 2020");
    end;

    procedure Run1099NecReport()
    begin
        REPORT.Run(REPORT::"Vendor 1099 Nec");
    end;

    [Scope('OnPrem')]
    procedure ShowUpgradeFormBoxesNotificationIfUpgradeNeeded()
    var
        UpgradeYear: Text;
    begin
        case true of
            Upgrade2019Needed():
                UpgradeYear := '2019';
            Upgrade2020Needed():
                UpgradeYear := '2020';
            Upgrade2020FebruaryNeeded():
                UpgradeYear := February2020Lbl;
            else
                exit;
        end;

        SendIRS1099UpgradeNotification(UpgradeYear);
    end;

    local procedure SendIRS1099UpgradeNotification(UpgradeYear: Text)
    var
        UpgradeFormBoxes: Notification;
    begin
        UpgradeFormBoxes.Id := GetUpgradeFormBoxesNotificationID;
        UpgradeFormBoxes.Message := StrSubstNo(UpgradeFormBoxesNotificationMsg, UpgradeYear);
        UpgradeFormBoxes.Scope := NOTIFICATIONSCOPE::LocalScope;
        UpgradeFormBoxes.AddAction(
          GetUpgradeFormBoxesNotificationMsg, CODEUNIT::"IRS 1099 Management", 'UpgradeFormBoxesFromNotification');
        UpgradeFormBoxes.Send;
    end;

    [Scope('OnPrem')]
    procedure ThrowErrorfUpgrade2019Needed()
    begin
        if Upgrade2019Needed() then
            Error(BlockIfUpgradeNeededErr);
    end;

    [Scope('OnPrem')]
    procedure ThrowErrorfUpgrade2020Needed()
    begin
        if Upgrade2020Needed() then
            Error(BlockIfUpgradeNeededErr);
    end;

    [Scope('OnPrem')]
    procedure ThrowErrorfUpgrade2020FebruaryNeeded()
    begin
        if Upgrade2020FebruaryNeeded() then
            Error(BlockIfUpgradeNeededErr);
    end;

    [Scope('OnPrem')]
    procedure UpgradeNeeded(): Boolean
    begin
        exit(Upgrade2019Needed() or Upgrade2020Needed() or Upgrade2020FebruaryNeeded());
    end;

    [Scope('OnPrem')]
    procedure Upgrade2019Needed(): Boolean
    var
        IRS1099FormBox: Record "IRS 1099 Form-Box";
    begin
        exit(not IRS1099FormBox.Get('DIV-07'));
    end;

    [Scope('OnPrem')]
    procedure Upgrade2020Needed(): Boolean
    var
        IRS1099FormBox: Record "IRS 1099 Form-Box";
    begin
        exit(not IRS1099FormBox.Get('NEC-01'));
    end;

    [Scope('OnPrem')]
    procedure Upgrade2020FebruaryNeeded(): Boolean
    var
        IRS1099FormBox: Record "IRS 1099 Form-Box";
    begin
        exit(not IRS1099FormBox.Get('NEC-04'));
    end;

    local procedure GetUpgradeFormBoxesNotificationID(): Text
    begin
        exit('644a30e2-a1f4-45d1-ae23-4eb14071ea8a');
    end;

    local procedure GetUpgradeFormBoxesNotificationMsg(): Text
    begin
        if TASKSCHEDULER.CanCreateTask then
            exit(ScheduleUpgradeFormBoxesMsg);
        exit(UpgradeFormBoxesMsg);
    end;

    [Scope('OnPrem')]
    procedure GetAdjustmentAmount(VendorLedgerEntry: Record "Vendor Ledger Entry"): Decimal
    var
        IRS1099Adjustment: Record "IRS 1099 Adjustment";
    begin
        if VendorLedgerEntry."IRS 1099 Code" = '' then
            exit(0);
        if IRS1099Adjustment.Get(
             VendorLedgerEntry."Vendor No.", VendorLedgerEntry."IRS 1099 Code", Date2DMY(VendorLedgerEntry."Posting Date", 3))
        then
            exit(IRS1099Adjustment.Amount);
    end;

    [Scope('OnPrem')]
    procedure GetAdjustmentRec(var IRS1099Adjustment: Record "IRS 1099 Adjustment"; VendorLedgerEntry: Record "Vendor Ledger Entry"): Boolean
    begin
        if VendorLedgerEntry."IRS 1099 Code" = '' then
            exit(false);
        exit(
          IRS1099Adjustment.Get(
            VendorLedgerEntry."Vendor No.", VendorLedgerEntry."IRS 1099 Code", Date2DMY(VendorLedgerEntry."Posting Date", 3)));
    end;

    [Scope('OnPrem')]
    procedure UpgradeFormBoxesFromNotification(Notification: Notification)
    begin
        UpgradeFormBoxes;
    end;

    [Scope('OnPrem')]
    procedure UpgradeFormBoxes()
    var
        JobQueueEntry: Record "Job Queue Entry";
        UpgradeIRS1099FormBoxes: Codeunit "Upgrade IRS 1099 Form Boxes";
        JobQueueManagement: Codeunit "Job Queue Management";
        Confirmed: Boolean;
        Handled: Boolean;
        CanCreateTask: Boolean;
    begin
        if not UpgradeNeeded then
            exit;

        OnBeforeUpgradeFormBoxes(Handled, CanCreateTask);
        if not Handled then
            CanCreateTask := TASKSCHEDULER.CanCreateTask;
        if CanCreateTask then begin
            JobQueueEntry.Init;
            JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
            JobQueueEntry."Earliest Start Date/Time" := CreateDateTime(Today, Time + 60000);
            JobQueueEntry."Object ID to Run" := CODEUNIT::"Upgrade IRS 1099 Form Boxes";
            JobQueueManagement.CreateJobQueueEntry(JobQueueEntry);
            if GuiAllowed then
                Message(UpgradeFormBoxesScheduledMsg);
            JobQueueEntry.SetRecFilter;
            PAGE.Run(PAGE::"Job Queue Entry Card", JobQueueEntry);
        end else begin
            if GuiAllowed then
                Confirmed := Confirm(ConfirmUpgradeNowQst)
            else
                Confirmed := true;
            if Confirmed then begin
                UpgradeIRS1099FormBoxes.Run;
                Message(FormBoxesUpgradedMsg);
            end;
        end;
    end;

    local procedure UpdateLines(var Amounts: array[20] of Decimal; Codes: array[20] of Code[10]; LastLineNo: Integer; ApplVendorLedgerEntry: Record "Vendor Ledger Entry"; "Code": Code[10]; Amount: Decimal): Integer
    var
        i: Integer;
    begin
        i := 1;
        while (Codes[i] <> Code) and (i <= LastLineNo) do
            i := i + 1;

        if (Codes[i] = Code) and (i <= LastLineNo) then
            Amounts[i] += Amount
        else
            Error(UnkownCodeErr, ApplVendorLedgerEntry."Entry No.", ApplVendorLedgerEntry."Vendor No.", Code);
        exit(i);
    end;

    procedure AnyCodeHasAmountExceedMinimum(Codes: array[20] of Code[10]; Amounts: array[20] of Decimal; LastLineNo: Integer): Boolean
    var
        IRS1099FormBox: Record "IRS 1099 Form-Box";
        i: Integer;
    begin
        for i := 1 to LastLineNo do
            if IRS1099FormBox.Get(Codes[i]) then begin
                if IRS1099FormBox."Minimum Reportable" < 0.0 then
                    if Amounts[i] <> 0.0 then begin
                        Amounts[i] := -Amounts[i];
                        exit(true);
                    end;
                if IRS1099FormBox."Minimum Reportable" >= 0.0 then
                    if Amounts[i] <> 0.0 then
                        if Amounts[i] >= IRS1099FormBox."Minimum Reportable" then
                            exit(true);
            end;
        exit(false);
    end;

    procedure GetFormattedVendorAddress(Vendor: Record Vendor) FormattedAddress: Text[30]
    begin
        with Vendor do begin
            FormattedAddress := '';
            if StrLen(City + ', ' + County + '  ' + "Post Code") > MaxStrLen(FormattedAddress) then
                exit(City);
            if (City <> '') and (County <> '') then
                exit(CopyStr(City + ', ' + County + '  ' + "Post Code", 1, MaxStrLen(FormattedAddress)));
            exit(CopyStr(DelChr(City + ' ' + County + ' ' + "Post Code", '<>'), 1, MaxStrLen(FormattedAddress)));
        end;
    end;

    procedure FormatCompanyAddress(var CompanyAddress: array[5] of Text[100]; var CompanyInfo: Record "Company Information"; TestPrint: Boolean)
    var
        i: Integer;
    begin
        with CompanyInfo do begin
            if TestPrint then begin
                for i := 1 to ArrayLen(CompanyAddress) do
                    CompanyAddress[i] := PadStr('x', MaxStrLen(CompanyAddress[i]), 'X');
                exit;
            end;
            Get;

            Clear(CompanyAddress);
            CompanyAddress[1] := Name;
            CompanyAddress[2] := Address;
            CompanyAddress[3] := "Address 2";
            if StrLen(City + ', ' + County + '  ' + "Post Code") > MaxStrLen(CompanyAddress[4]) then begin
                CompanyAddress[4] := City;
                CompanyAddress[5] := County + '  ' + "Post Code";
                if CompressArray(CompanyAddress) = ArrayLen(CompanyAddress) then begin
                    CompanyAddress[3] := CompanyAddress[4];  // lose address 2 to add phone no.
                    CompanyAddress[4] := CompanyAddress[5];
                end;
                CompanyAddress[5] := "Phone No.";
            end else
                if (City <> '') and (County <> '') then begin
                    CompanyAddress[4] := CopyStr(City + ', ' + County + '  ' + "Post Code", 1, MaxStrLen(CompanyAddress[4]));
                    CompanyAddress[5] := "Phone No.";
                end else begin
                    CompanyAddress[4] := CopyStr(DelChr(City + ' ' + County + ' ' + "Post Code", '<>'), 1, MaxStrLen(CompanyAddress[4]));
                    CompanyAddress[5] := "Phone No.";
                end;
            CompressArray(CompanyAddress);
        end;
    end;

    procedure GetAmtByCode(Codes: array[20] of Code[10]; Amounts: array[20] of Decimal; LastLineNo: Integer; "Code": Code[10]; TestPrint: Boolean): Decimal
    var
        i: Integer;
    begin
        if TestPrint then
            exit(9999999.99);

        i := 1;
        while (Codes[i] <> Code) and (i <= LastLineNo) do
            i := i + 1;

        if (Codes[i] = Code) and (i <= LastLineNo) then
            exit(Amounts[i]);

        Error(IRS1099CodeHasNotBeenSetupErr, Code);
    end;

    procedure ProcessVendorInvoices(var Amounts: array[20] of Decimal; VendorNo: Code[20]; PeriodDate: array[2] of Date; Codes: array[20] of Code[10]; LastLineNo: Integer; "Filter": Text)
    var
        TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
        IRS1099Adjustment: Record "IRS 1099 Adjustment";
        TempIRS1099Adjustment: Record "IRS 1099 Adjustment" temporary;
        EntryApplicationManagement: Codeunit "Entry Application Management";
        Invoice1099Amount: Decimal;
    begin
        EntryApplicationManagement.GetAppliedVendorEntries(
          TempVendorLedgerEntry, VendorNo, PeriodDate, true);
        with TempVendorLedgerEntry do begin
            SetFilter("Document Type", '%1|%2', "Document Type"::Invoice, "Document Type"::"Credit Memo");
            SetFilter("IRS 1099 Amount", '<>0');
            if Filter <> '' then
                SetFilter("IRS 1099 Code", Filter);
            if FindSet() then
                repeat
                    Calculate1099Amount(
                      Invoice1099Amount, Amounts, Codes, LastLineNo, TempVendorLedgerEntry, "Amount to Apply");
                    if GetAdjustmentRec(IRS1099Adjustment, TempVendorLedgerEntry) then begin
                        TempIRS1099Adjustment := IRS1099Adjustment;
                        if not TempIRS1099Adjustment.Find() then begin
                            UpdateLines(
                              Amounts, Codes, LastLineNo, TempVendorLedgerEntry, "IRS 1099 Code", IRS1099Adjustment.Amount);
                            TempIRS1099Adjustment.Insert();
                        end;
                    end;
                until Next() = 0;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpgradeFormBoxes(var Handled: Boolean; var CreateTask: Boolean)
    begin
    end;
}

