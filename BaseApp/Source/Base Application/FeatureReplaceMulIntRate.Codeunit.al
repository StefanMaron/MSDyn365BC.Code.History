#if not CLEAN20
#pragma warning disable AL0432
/// <summary>
/// Copies data from tables of multiple interest rate feature CZ to tables of finance charge interest rate feature.
/// </summary>
codeunit 31429 "Feature Replace Mul. Int. Rate" implements "Feature Data Update"
{
    Access = Internal;
    Permissions = tabledata "Finance Charge Memo Header" = rimd,
                  tabledata "Reminder Header" = rimd,
                  tabledata "Detailed Fin. Charge Memo Line" = rimd,
                  tabledata "Detailed Reminder Line" = rimd,
                  tabledata "Detailed Iss.Fin.Ch. Memo Line" = rimd,
                  tabledata "Detailed Issued Reminder Line" = rimd,
                  tabledata "Issued Fin. Charge Memo Header" = rimd,
                  tabledata "Issued Fin. Charge Memo Line" = rimd,
                  tabledata "Issued Reminder Header" = rimd,
                  tabledata "Issued Reminder Line" = rimd,
                  tabledata "Multiple Interest Rate" = rimd,
                  tabledata "Finance Charge Interest Rate" = rimd;

    [Obsolete('Replaced by normal upgrade process.', '20.0')]
    procedure IsDataUpdateRequired(): Boolean;
    begin
        CountRecords();
        exit(not TempDocumentEntry.IsEmpty);
    end;

    [Obsolete('Replaced by normal upgrade process.', '20.0')]
    procedure ReviewData();
    var
        DataUpgradeOverview: Page "Data Upgrade Overview";
    begin
        Commit();
        Clear(DataUpgradeOverview);
        DataUpgradeOverview.Set(TempDocumentEntry);
        DataUpgradeOverview.RunModal();
    end;

    [Obsolete('Replaced by normal upgrade process.', '20.0')]
    procedure AfterUpdate(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    begin
    end;

    [Obsolete('Replaced by normal upgrade process.', '20.0')]
    procedure UpdateData(FeatureDataUpdateStatus: Record "Feature Data Update Status");
    begin
        UpdateSalesReceivablesSetup(FeatureDataUpdateStatus);
        UpdateMultipleInterestRate(FeatureDataUpdateStatus);
        UpdateFinanceChargeMemoHeader(FeatureDataUpdateStatus);
        UpdateDetailedFinanceChargeMemoLine(FeatureDataUpdateStatus);
        UpdateReminderHeader(FeatureDataUpdateStatus);
        UpdateDetailedReminderLine(FeatureDataUpdateStatus);
        UpdateIssuedFinChargeMemoHeader(FeatureDataUpdateStatus);
        UpdateDetailedIssuedFinanceChargeMemoLine(FeatureDataUpdateStatus);
        UpdateIssuedReminderHeader(FeatureDataUpdateStatus);
        UpdateDetailedIssuedReminderLine(FeatureDataUpdateStatus);
    end;

    [Obsolete('Replaced by normal upgrade process.', '20.0')]
    procedure GetTaskDescription() TaskDescription: Text;
    begin
        TaskDescription := DescriptionTxt;
    end;

    var
        DetailedFinChargeMemoLine: Record "Detailed Fin. Charge Memo Line";
        DetailedReminderLine: Record "Detailed Reminder Line";
        DetailedIssFinChMemoLine: Record "Detailed Iss.Fin.Ch. Memo Line";
        DetailedIssuedReminderLine: Record "Detailed Issued Reminder Line";
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        FinanceChargeTerms: Record "Finance Charge Terms";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line";
        IssuedReminderHeader: Record "Issued Reminder Header";
        IssuedReminderLine: Record "Issued Reminder Line";
        MultipleInterestRate: Record "Multiple Interest Rate";
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        TempDocumentEntry: Record "Document Entry" temporary;
        FeatureDataUpdateMgt: Codeunit "Feature Data Update Mgt.";
        DescriptionTxt: Label 'Copies data from tables of multiple interest rate feature CZ to tables of finance charge interest rate feature.';
        DocumentTxt: Label 'Document';

    local procedure CountRecords()
    begin
        TempDocumentEntry.DeleteAll();
        InsertDocumentEntry(Database::"Sales & Receivables Setup", SalesReceivablesSetup.TableCaption(), SalesReceivablesSetup.CountApprox());
        InsertDocumentEntry(Database::"Multiple Interest Rate", MultipleInterestRate.TableCaption(), MultipleInterestRate.CountApprox());
        InsertDocumentEntry(Database::"Finance Charge Memo Header", FinanceChargeMemoHeader.TableCaption(), FinanceChargeMemoHeader.CountApprox());
        InsertDocumentEntry(Database::"Detailed Fin. Charge Memo Line", DetailedFinChargeMemoLine.TableCaption(), DetailedFinChargeMemoLine.CountApprox());
        InsertDocumentEntry(Database::"Reminder Header", ReminderHeader.TableCaption(), ReminderHeader.CountApprox());
        InsertDocumentEntry(Database::"Detailed Reminder Line", DetailedReminderLine.TableCaption(), DetailedReminderLine.CountApprox());
        InsertDocumentEntry(Database::"Issued Fin. Charge Memo Header", IssuedFinChargeMemoHeader.TableCaption(), IssuedFinChargeMemoHeader.CountApprox());
        InsertDocumentEntry(Database::"Detailed Iss.Fin.Ch. Memo Line", DetailedIssFinChMemoLine.TableCaption(), DetailedIssFinChMemoLine.CountApprox());
        InsertDocumentEntry(Database::"Issued Reminder Header", IssuedReminderHeader.TableCaption(), IssuedReminderHeader.CountApprox());
        InsertDocumentEntry(Database::"Detailed Issued Reminder Line", DetailedIssuedReminderLine.TableCaption(), DetailedIssuedReminderLine.CountApprox());
        OnAfterCountRecords(TempDocumentEntry);
    end;

    local procedure InsertDocumentEntry(TableID: Integer; TableName: Text; RecordCount: Integer)
    begin
        if RecordCount = 0 then
            exit;

        TempDocumentEntry.Init();
        TempDocumentEntry."Entry No." += 1;
        TempDocumentEntry."Table ID" := TableID;
        TempDocumentEntry."Table Name" := CopyStr(TableName, 1, MaxStrLen(TempDocumentEntry."Table Name"));
        TempDocumentEntry."No. of Records" := RecordCount;
        TempDocumentEntry.Insert();
    end;

    local procedure UpdateSalesReceivablesSetup(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    var
        StartDateTime: DateTime;
    begin
        StartDateTime := CurrentDateTime();
        if not SalesReceivablesSetup.Get() then
            exit;

        SalesReceivablesSetup."Multiple Interest Rates" := false;
        SalesReceivablesSetup.Modify();

        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, SalesReceivablesSetup.TableCaption(), StartDateTime);
    end;

    local procedure UpdateMultipleInterestRate(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    var
        FinanceChargeInterestRate: Record "Finance Charge Interest Rate";
        StartDateTime: DateTime;
    begin
        StartDateTime := CurrentDateTime();
        if MultipleInterestRate.FindSet() then
            repeat
                if not FinanceChargeInterestRate.Get(MultipleInterestRate."Finance Charge Code", MultipleInterestRate."Valid from Date") then begin
                    FinanceChargeInterestRate.Init();
                    FinanceChargeInterestRate."Fin. Charge Terms Code" := MultipleInterestRate."Finance Charge Code";
                    FinanceChargeInterestRate."Start Date" := MultipleInterestRate."Valid from Date";
                    FinanceChargeInterestRate."Interest Rate" := MultipleInterestRate."Interest Rate";
                    FinanceChargeInterestRate."Interest Period (Days)" := MultipleInterestRate."Interest Period (Days)";
                    FinanceChargeInterestRate.SystemId := MultipleInterestRate.SystemId;
                    FinanceChargeInterestRate.Insert(false, true);
                end;
            until MultipleInterestRate.Next() = 0;

        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, MultipleInterestRate.TableCaption(), StartDateTime);
    end;

    local procedure UpdateFinanceChargeMemoHeader(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    var
        StartDateTime: DateTime;
    begin
        StartDateTime := CurrentDateTime();
        if FinanceChargeMemoHeader.FindSet() then
            repeat
                FinanceChargeMemoHeader."Multiple Interest Rates" := false;
                FinanceChargeMemoHeader.Modify();
            until FinanceChargeMemoHeader.Next() = 0;

        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, FinanceChargeMemoHeader.TableCaption(), StartDateTime);
    end;

    local procedure UpdateDetailedFinanceChargeMemoLine(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    var
        TempFinanceChargeMemoLine: Record "Finance Charge Memo Line" temporary;
        TempDetailedFinChargeMemoLine: Record "Detailed Fin. Charge Memo Line" temporary;
        ListOfDocumentNo: List of [Code[20]];
        DocumentNo: Code[20];
        StartDateTime: DateTime;
        LineNo: Integer;
    begin
        StartDateTime := CurrentDateTime();
        if DetailedFinChargeMemoLine.FindSet() then
            repeat
                if not ListOfDocumentNo.Contains(DetailedFinChargeMemoLine."Finance Charge Memo No.") then
                    ListOfDocumentNo.Add(DetailedFinChargeMemoLine."Finance Charge Memo No.");
                TempDetailedFinChargeMemoLine.Init();
                TempDetailedFinChargeMemoLine := DetailedFinChargeMemoLine;
                TempDetailedFinChargeMemoLine.Insert();
            until DetailedFinChargeMemoLine.Next() = 0;

        foreach DocumentNo in ListOfDocumentNo do begin
            TempFinanceChargeMemoLine.Reset();
            TempFinanceChargeMemoLine.DeleteAll();
            FinanceChargeMemoLine.SetRange("Finance Charge Memo No.", DocumentNo);
            if FinanceChargeMemoLine.FindSet() then
                repeat
                    TempFinanceChargeMemoLine.Init();
                    TempFinanceChargeMemoLine := FinanceChargeMemoLine;
                    TempFinanceChargeMemoLine.Insert();
                until FinanceChargeMemoLine.Next() = 0;

            FinanceChargeMemoLine.DeleteAll(true);

            LineNo := 0;
            if TempFinanceChargeMemoLine.FindSet() then
                repeat
                    LineNo += 10000;
                    FinanceChargeMemoLine.Init();
                    FinanceChargeMemoLine := TempFinanceChargeMemoLine;
                    FinanceChargeMemoLine."Line No." := LineNo;
                    FinanceChargeMemoLine.SystemId := TempFinanceChargeMemoLine.SystemId;
                    FinanceChargeMemoLine.Insert(false, true);

                    if FinanceChargeMemoLine."Entry No." <> 0 then begin
                        FinanceChargeMemoLine.SkipCalcFinChrgCZ();
                        FinanceChargeMemoLine.Validate("Entry No.");
                        FinanceChargeMemoLine.Modify();

                        TempDetailedFinChargeMemoLine.SetRange("Finance Charge Memo No.", TempFinanceChargeMemoLine."Finance Charge Memo No.");
                        TempDetailedFinChargeMemoLine.SetRange("Fin. Charge. Memo Line No.", TempFinanceChargeMemoLine."Line No.");
                        if TempDetailedFinChargeMemoLine.FindSet() then
                            repeat
                                DetailedFinChargeMemoLine.Init();
                                DetailedFinChargeMemoLine := TempDetailedFinChargeMemoLine;
                                DetailedFinChargeMemoLine."Fin. Charge. Memo Line No." := FinanceChargeMemoLine."Line No.";
                                DetailedFinChargeMemoLine.SystemId := TempDetailedFinChargeMemoLine.SystemId;
                                DetailedFinChargeMemoLine.Insert(false, true);
                            until TempDetailedFinChargeMemoLine.Next() = 0;

                        FinanceChargeMemoLine.FindLast();
                        LineNo := FinanceChargeMemoLine."Line No.";
                    end;
                until TempFinanceChargeMemoLine.Next() = 0;
        end;

        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, DetailedFinChargeMemoLine.TableCaption(), StartDateTime);
    end;

    local procedure UpdateReminderHeader(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    var
        StartDateTime: DateTime;
    begin
        StartDateTime := CurrentDateTime();
        if ReminderHeader.FindSet() then
            repeat
                ReminderHeader."Multiple Interest Rates" := false;
                ReminderHeader.Modify();
            until ReminderHeader.Next() = 0;

        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, ReminderHeader.TableCaption(), StartDateTime);
    end;

    local procedure UpdateDetailedReminderLine(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    var
        TempReminderLine: Record "Reminder Line" temporary;
        TempDetailedReminderLine: Record "Detailed Reminder Line" temporary;
        ListOfDocumentNo: List of [Code[20]];
        DocumentNo: Code[20];
        StartDateTime: DateTime;
        LineNo: Integer;
    begin
        StartDateTime := CurrentDateTime();
        if DetailedReminderLine.FindSet() then
            repeat
                if not ListOfDocumentNo.Contains(DetailedReminderLine."Reminder No.") then
                    ListOfDocumentNo.Add(DetailedReminderLine."Reminder No.");
                TempDetailedReminderLine.Init();
                TempDetailedReminderLine := DetailedReminderLine;
                TempDetailedReminderLine.Insert();
            until DetailedReminderLine.Next() = 0;

        foreach DocumentNo in ListOfDocumentNo do begin
            TempReminderLine.Reset();
            TempReminderLine.DeleteAll();
            ReminderLine.SetRange("Reminder No.", DocumentNo);
            if ReminderLine.FindSet() then
                repeat
                    TempReminderLine.Init();
                    TempReminderLine := ReminderLine;
                    TempReminderLine.Insert();
                until ReminderLine.Next() = 0;

            ReminderLine.DeleteAll(true);

            LineNo := 0;
            if TempReminderLine.FindSet() then
                repeat
                    LineNo += 10000;
                    ReminderLine.Init();
                    ReminderLine := TempReminderLine;
                    ReminderLine."Line No." := LineNo;
                    ReminderLine.SystemId := TempReminderLine.SystemId;
                    ReminderLine.Insert(false, true);

                    if ReminderLine."Entry No." <> 0 then begin
                        ReminderLine.SkipCalcFinChrgCZ();
                        ReminderLine.Validate("Entry No.");
                        ReminderLine.Modify();

                        TempDetailedReminderLine.SetRange("Reminder No.", TempReminderLine."Reminder No.");
                        TempDetailedReminderLine.SetRange("Line No.", TempReminderLine."Line No.");
                        if TempDetailedReminderLine.FindSet() then
                            repeat
                                DetailedReminderLine.Init();
                                DetailedReminderLine := TempDetailedReminderLine;
                                DetailedReminderLine."Reminder Line No." := ReminderLine."Line No.";
                                DetailedReminderLine.SystemId := TempDetailedReminderLine.SystemId;
                                DetailedReminderLine.Insert(false, true);
                            until TempDetailedReminderLine.Next() = 0;

                        ReminderLine.FindLast();
                        LineNo := ReminderLine."Line No.";
                    end;
                until TempReminderLine.Next() = 0;
        end;

        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, DetailedReminderLine.TableCaption(), StartDateTime);
    end;

    local procedure UpdateIssuedFinChargeMemoHeader(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    var
        StartDateTime: DateTime;
    begin
        StartDateTime := CurrentDateTime();
        if IssuedFinChargeMemoHeader.FindSet() then
            repeat
                IssuedFinChargeMemoHeader."Multiple Interest Rates" := false;
                IssuedFinChargeMemoHeader.Modify();
            until IssuedFinChargeMemoHeader.Next() = 0;

        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, IssuedFinChargeMemoHeader.TableCaption(), StartDateTime);
    end;

    local procedure UpdateDetailedIssuedFinanceChargeMemoLine(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ExtraIssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line";
        TempIssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line" temporary;
        TempDetailedIssFinChMemoLine: Record "Detailed Iss.Fin.Ch. Memo Line" temporary;
        ListOfDocumentNo: List of [Code[20]];
        BaseAmount: Decimal;
        DocumentNo: Code[20];
        DueDate: Date;
        StartDateTime: DateTime;
        LineNo: Integer;
        Days: Integer;
    begin
        StartDateTime := CurrentDateTime();
        if DetailedIssFinChMemoLine.FindSet() then
            repeat
                if not ListOfDocumentNo.Contains(DetailedIssFinChMemoLine."Finance Charge Memo No.") then
                    ListOfDocumentNo.Add(DetailedIssFinChMemoLine."Finance Charge Memo No.");
                TempDetailedIssFinChMemoLine.Init();
                TempDetailedIssFinChMemoLine := DetailedIssFinChMemoLine;
                TempDetailedIssFinChMemoLine.Insert();

                DetailedIssFinChMemoLine.Delete();
            until DetailedIssFinChMemoLine.Next() = 0;

        foreach DocumentNo in ListOfDocumentNo do begin
            IssuedFinChargeMemoHeader.Get(DocumentNo);
            FinanceChargeTerms.Get(IssuedFinChargeMemoHeader."Fin. Charge Terms Code");

            TempIssuedFinChargeMemoLine.Reset();
            TempIssuedFinChargeMemoLine.DeleteAll();
            IssuedFinChargeMemoLine.SetRange("Finance Charge Memo No.", IssuedFinChargeMemoHeader."No.");
            if IssuedFinChargeMemoLine.FindSet() then
                repeat
                    TempIssuedFinChargeMemoLine.Init();
                    TempIssuedFinChargeMemoLine := IssuedFinChargeMemoLine;
                    TempIssuedFinChargeMemoLine.Insert();

                    IssuedFinChargeMemoLine.Delete();
                until IssuedFinChargeMemoLine.Next() = 0;

            LineNo := 0;
            if TempIssuedFinChargeMemoLine.FindSet() then
                repeat
                    LineNo += 10000;
                    IssuedFinChargeMemoLine.Init();
                    IssuedFinChargeMemoLine := TempIssuedFinChargeMemoLine;
                    IssuedFinChargeMemoLine."Line No." := LineNo;
                    IssuedFinChargeMemoLine.SystemId := TempIssuedFinChargeMemoLine.SystemId;
                    IssuedFinChargeMemoLine.Insert(false, true);

                    if IssuedFinChargeMemoLine."Entry No." <> 0 then begin
                        CustLedgerEntry.Get(IssuedFinChargeMemoLine."Entry No.");
                        CustLedgerEntry.CalcFields(Amount, "Remaining Amount");
                        Days := 0;
                        DueDate := CalcDate('<1D>', IssuedFinChargeMemoLine."Due Date");

                        TempDetailedIssFinChMemoLine.SetRange("Finance Charge Memo No.", TempIssuedFinChargeMemoLine."Finance Charge Memo No.");
                        TempDetailedIssFinChMemoLine.SetRange("Fin. Charge. Memo Line No.", TempIssuedFinChargeMemoLine."Line No.");
                        if TempDetailedIssFinChMemoLine.FindSet() then
                            repeat
                                DetailedIssFinChMemoLine.Init();
                                DetailedIssFinChMemoLine := TempDetailedIssFinChMemoLine;
                                DetailedIssFinChMemoLine."Fin. Charge. Memo Line No." := IssuedFinChargeMemoLine."Line No.";
                                DetailedIssFinChMemoLine.SystemId := TempDetailedIssFinChMemoLine.SystemId;
                                DetailedIssFinChMemoLine.Insert(false, true);

                                LineNo += 10000;
                                ExtraIssuedFinChargeMemoLine.Init();
                                ExtraIssuedFinChargeMemoLine := IssuedFinChargeMemoLine;
                                ExtraIssuedFinChargeMemoLine."Line No." := LineNo;
                                ExtraIssuedFinChargeMemoLine."Due Date" := DueDate;
                                ExtraIssuedFinChargeMemoLine."Interest Rate" := TempDetailedIssFinChMemoLine."Interest Rate";
                                ExtraIssuedFinChargeMemoLine.Amount := TempDetailedIssFinChMemoLine."Interest Amount";
                                ExtraIssuedFinChargeMemoLine."Remaining Amount" := CustLedgerEntry."Remaining Amount";
                                BaseAmount := Round(100 * ExtraIssuedFinChargeMemoLine.Amount / ExtraIssuedFinChargeMemoLine."Interest Rate");
                                ExtraIssuedFinChargeMemoLine.Description :=
                                    BuildDescription(
                                        FinanceChargeTerms."Line Description", CustLedgerEntry.Description,
                                        IssuedFinChargeMemoLine."Document Type", IssuedFinChargeMemoLine."Document No.",
                                        IssuedFinChargeMemoHeader."Currency Code", ExtraIssuedFinChargeMemoLine."Interest Rate",
                                        ExtraIssuedFinChargeMemoLine."Due Date", TempDetailedIssFinChMemoLine.Days,
                                        CustLedgerEntry.Amount, BaseAmount);
                                ExtraIssuedFinChargeMemoLine."Detailed Interest Rates Entry" := true;
                                ExtraIssuedFinChargeMemoLine.Insert();

                                Days += TempDetailedIssFinChMemoLine.Days;
                                DueDate += Days;
                            until TempDetailedIssFinChMemoLine.Next() = 0;
                    end;
                until TempIssuedFinChargeMemoLine.Next() = 0;
        end;

        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, DetailedIssFinChMemoLine.TableCaption(), StartDateTime);
    end;

    local procedure UpdateIssuedReminderHeader(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    var
        StartDateTime: DateTime;
    begin
        StartDateTime := CurrentDateTime();
        if IssuedReminderHeader.FindSet() then
            repeat
                IssuedReminderHeader."Multiple Interest Rates" := false;
                IssuedReminderHeader.Modify();
            until IssuedReminderHeader.Next() = 0;

        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, IssuedReminderHeader.TableCaption(), StartDateTime);
    end;

    local procedure UpdateDetailedIssuedReminderLine(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ExtraIssuedReminderLine: Record "Issued Reminder Line";
        TempIssuedReminderLine: Record "Issued Reminder Line" temporary;
        TempDetailedIssuedReminderLine: Record "Detailed Issued Reminder Line" temporary;
        ListOfDocumentNo: List of [Code[20]];
        DocumentNo: Code[20];
        DueDate: Date;
        StartDateTime: DateTime;
        LineNo: Integer;
        Days: Integer;
    begin
        StartDateTime := CurrentDateTime();
        if DetailedIssuedReminderLine.FindSet() then
            repeat
                if not ListOfDocumentNo.Contains(DetailedIssuedReminderLine."Issued Reminder No.") then
                    ListOfDocumentNo.Add(DetailedIssuedReminderLine."Issued Reminder No.");
                TempDetailedIssuedReminderLine.Init();
                TempDetailedIssuedReminderLine := DetailedIssuedReminderLine;
                TempDetailedIssuedReminderLine.Insert();

                DetailedIssuedReminderLine.Delete();
            until DetailedIssuedReminderLine.Next() = 0;

        foreach DocumentNo in ListOfDocumentNo do begin
            TempIssuedReminderLine.Reset();
            TempIssuedReminderLine.DeleteAll();
            IssuedReminderLine.SetRange("Reminder No.", DocumentNo);
            if IssuedReminderLine.FindSet() then
                repeat
                    TempIssuedReminderLine.Init();
                    TempIssuedReminderLine := IssuedReminderLine;
                    TempIssuedReminderLine.Insert();

                    IssuedReminderLine.Delete();
                until IssuedReminderLine.Next() = 0;

            LineNo := 0;
            if TempIssuedReminderLine.FindSet() then
                repeat
                    LineNo += 10000;
                    IssuedReminderLine.Init();
                    IssuedReminderLine := TempIssuedReminderLine;
                    IssuedReminderLine."Line No." := LineNo;
                    IssuedReminderLine.SystemId := TempIssuedReminderLine.SystemId;
                    IssuedReminderLine.Insert(false, true);

                    if IssuedReminderLine."Entry No." <> 0 then begin
                        CustLedgerEntry.Get(IssuedReminderLine."Entry No.");
                        CustLedgerEntry.CalcFields("Remaining Amount");

                        Days := 0;
                        DueDate := CalcDate('<1D>', IssuedReminderLine."Due Date");

                        TempDetailedIssuedReminderLine.SetRange("Issued Reminder No.", TempIssuedReminderLine."Reminder No.");
                        TempDetailedIssuedReminderLine.SetRange("Issued Reminder Line No.", TempIssuedReminderLine."Line No.");
                        if TempDetailedIssuedReminderLine.FindSet() then
                            repeat
                                DetailedIssuedReminderLine.Init();
                                DetailedIssuedReminderLine := TempDetailedIssuedReminderLine;
                                DetailedIssuedReminderLine."Issued Reminder Line No." := IssuedReminderLine."Line No.";
                                DetailedIssuedReminderLine.SystemId := TempDetailedIssuedReminderLine.SystemId;
                                DetailedIssuedReminderLine.Insert(false, true);

                                LineNo += 10000;
                                ExtraIssuedReminderLine.Init();
                                ExtraIssuedReminderLine := IssuedReminderLine;
                                ExtraIssuedReminderLine."Line No." := LineNo;
                                ExtraIssuedReminderLine."Due Date" := DueDate;
                                ExtraIssuedReminderLine."Interest Rate" := TempDetailedIssuedReminderLine."Interest Rate";
                                ExtraIssuedReminderLine.Amount := TempDetailedIssuedReminderLine."Interest Amount";
                                ExtraIssuedReminderLine."Remaining Amount" := CustLedgerEntry."Remaining Amount";
                                ExtraIssuedReminderLine."Detailed Interest Rates Entry" := true;
                                ExtraIssuedReminderLine.Insert();

                                Days += TempDetailedIssuedReminderLine.Days;
                                DueDate += Days;
                            until TempDetailedIssuedReminderLine.Next() = 0;
                    end;
                until TempIssuedReminderLine.Next() = 0;
        end;

        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, DetailedIssuedReminderLine.TableCaption(), StartDateTime);
    end;

    local procedure BuildDescription(LineDescription: Text[100]; EntryDescription: Text[100]; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; CurrencyCode: Code[20]; InterestRate: Decimal; DueDate: Date; NrOfDays: Integer; OriginalAmount: Decimal; BaseAmount: Decimal): Text[100]
    var
        AutoFormat: Codeunit "Auto Format";
        AutoFormatType: Enum "Auto Format";
        DocumentTypeText: Text[30];
    begin
        if LineDescription = '' then
            exit(CopyStr(EntryDescription, 1, 100));

        DocumentTypeText := CopyStr(DelChr(Format(DocumentType), '<'), 1, 30);
        if DocumentTypeText = '' then
            DocumentTypeText := DocumentTxt;

        exit(
            CopyStr(
                StrSubstNo(
                    LineDescription,
                    EntryDescription,
                    DocumentTypeText,
                    DocumentNo,
                    InterestRate,
                    Format(OriginalAmount, 0, AutoFormat.ResolveAutoFormat(AutoFormatType::AmountFormat, CurrencyCode)),
                    Format(BaseAmount, 0, AutoFormat.ResolveAutoFormat(AutoFormatType::AmountFormat, CurrencyCode)),
                    DueDate,
                    CurrencyCode,
                    NrOfDays),
                1, 100));
    end;

    [Obsolete('Replaced by normal upgrade process.', '20.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterCountRecords(var TempDocumentEntry: Record "Document Entry" temporary)
    begin
    end;
}
#endif