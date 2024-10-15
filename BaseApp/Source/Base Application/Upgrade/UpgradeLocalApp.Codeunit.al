codeunit 104150 "Upgrade - Local App"
{
#if not CLEAN21
    ObsoleteState = Pending;
    ObsoleteReason = 'The access of this codeunit will be changed to internal.';
    ObsoleteTag = '21.0';
#else
    Access = internal;
#endif
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerDatabase()
    var
        HybridDeployment: Codeunit "Hybrid Deployment";
    begin
        if not HybridDeployment.VerifyCanStartUpgrade('') then
            exit;

        UpdatePermissions();
    end;

    trigger OnUpgradePerCompany()
    var
        HybridDeployment: Codeunit "Hybrid Deployment";
    begin
        if not HybridDeployment.VerifyCanStartUpgrade(CompanyName()) then
            exit;

        UpdateVATPostingSetup();
        UpdateVATControlReportLine();
        UpdateSalesReceivablesSetup();
        UpdateVendorTemplate();
        UpdateIntrastatJnlLine();
        UpdateItemJournalLine();
        UpdateItemLedgerEntry();
        UpdateCashDeskWorkflowTemplate();
        UpdateCreditWorkflowTemplate();
        UpdatePaymentOrderWorkflowTemplate();
        UpdateAdvanceLetterWorkflowTemplate();
        UpdateReplaceMultipleInterestRate();
    end;

    local procedure UpdateVATPostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        LocalUpgradeTagDefinitions: Codeunit "Local Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(LocalUpgradeTagDefinitions.GetCorrectionsForBadReceivableUpgradeTag()) then
            exit;

        with VATPostingSetup do
            if FindSet() then
                repeat
                    // "Insolvency Proceedings (p.44)" field replaced by "Corrections for Bad Receivable" field
                    "Corrections for Bad Receivable" := "Corrections for Bad Receivable"::" ";
                    if "Insolvency Proceedings (p.44)" then begin
                        "Corrections for Bad Receivable" := "Corrections for Bad Receivable"::"Insolvency Proceedings (p.44)";
                        Modify();
                    end;
                until Next() = 0;

        UpgradeTag.SetUpgradeTag(LocalUpgradeTagDefinitions.GetCorrectionsForBadReceivableUpgradeTag());
    end;

    local procedure UpdateVATControlReportLine()
    var
        VATControlReportLine: Record "VAT Control Report Line";
        UpgradeTag: Codeunit "Upgrade Tag";
        LocalUpgradeTagDefinitions: Codeunit "Local Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(LocalUpgradeTagDefinitions.GetCorrectionsForBadReceivableUpgradeTag()) then
            exit;

        with VATControlReportLine do
            if FindSet() then
                repeat
                    // "Insolvency Proceedings (p.44)" field replaced by "Corrections for Bad Receivable" field
                    "Corrections for Bad Receivable" := "Corrections for Bad Receivable"::" ";
                    if "Insolvency Proceedings (p.44)" then begin
                        "Corrections for Bad Receivable" := "Corrections for Bad Receivable"::"Insolvency Proceedings (p.44)";
                        Modify();
                    end;
                until Next() = 0;

        UpgradeTag.SetUpgradeTag(LocalUpgradeTagDefinitions.GetCorrectionsForBadReceivableUpgradeTag());
    end;

    local procedure UpdatePermissions()
    var
        Permission: Record Permission;
        NewPermission: Record Permission;
        UpgradeTag: Codeunit "Upgrade Tag";
        LocalUpgradeTagDefinitions: Codeunit "Local Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(LocalUpgradeTagDefinitions.GetUseIsolatedCertificateInsteadOfCertificateCZ()) then
            exit;

        with Permission do begin
            SetRange("Object Type", "Object Type"::"Table Data");
            SetRange("Object ID", Database::"Certificate CZ");
            if FindSet() then
                repeat
                    if not NewPermission.Get("Role ID", "Object Type", Database::"Isolated Certificate") then begin
                        NewPermission.Init();
                        NewPermission := Permission;
                        NewPermission."Object ID" := Database::"Isolated Certificate";
                        NewPermission.Insert();
                    end;
                    Delete();
                until Next() = 0;
        end;

        UpgradeTag.SetUpgradeTag(LocalUpgradeTagDefinitions.GetUseIsolatedCertificateInsteadOfCertificateCZ());
    end;

    local procedure UpdateSalesReceivablesSetup()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        LocalUpgradeTagDefinitions: Codeunit "Local Upgrade Tag Definitions";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(LocalUpgradeTagDefinitions.GetObsoleteGeneralLedgerEntryDescriptionFeatureUpgradeTag()) then
            exit;

        if SalesSetup.Get() then begin
            SalesSetup."Copy Line Descr. to G/L Entry" := SalesSetup."G/L Entry as Doc. Lines (Acc.)";
            SalesSetup.Modify();
        end;

        UpgradeTag.SetUpgradeTag(LocalUpgradeTagDefinitions.GetObsoleteGeneralLedgerEntryDescriptionFeatureUpgradeTag());
    end;

    local procedure UpdateVendorTemplate()
    var
        VendorTemplate: Record "Vendor Template";
        VendorTempl: Record "Vendor Templ.";
        SourceDefaultDimension: Record "Default Dimension";
        DestDefaultDimension: Record "Default Dimension";
        UpgradeTag: Codeunit "Upgrade Tag";
        LocalUpgradeTagDefinitions: Codeunit "Local Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(LocalUpgradeTagDefinitions.GetVendorTemplateUpgradeTag()) then
            exit;

        if VendorTemplate.FindSet() then
            repeat
                if not VendorTempl.Get(VendorTemplate.Code) then begin
                    VendorTempl.Init();
                    VendorTempl.Code := VendorTemplate.Code;
                    VendorTempl.Description := VendorTemplate.Description;
                    VendorTempl."Global Dimension 1 Code" := VendorTemplate."Global Dimension 1 Code";
                    VendorTempl."Global Dimension 2 Code" := VendorTemplate."Global Dimension 2 Code";
                    VendorTempl."Vendor Posting Group" := VendorTemplate."Vendor Posting Group";
                    VendorTempl."Currency Code" := VendorTemplate."Currency Code";
                    VendorTempl."Language Code" := VendorTemplate."Language Code";
                    VendorTempl."Payment Terms Code" := VendorTemplate."Payment Terms Code";
                    VendorTempl."Invoice Disc. Code" := VendorTemplate."Invoice Disc. Code";
                    VendorTempl."Country/Region Code" := VendorTemplate."Country/Region Code";
                    VendorTempl."Payment Method Code" := VendorTemplate."Payment Method Code";
                    VendorTempl."Gen. Bus. Posting Group" := VendorTemplate."Gen. Bus. Posting Group";
                    VendorTempl."VAT Bus. Posting Group" := VendorTemplate."VAT Bus. Posting Group";
                    VendorTempl.Insert(true);

                    DestDefaultDimension.SetRange("Table ID", Database::"Vendor Templ.");
                    DestDefaultDimension.SetRange("No.", VendorTempl.Code);
                    DestDefaultDimension.DeleteAll(true);

                    SourceDefaultDimension.SetRange("Table ID", Database::"Vendor Template");
                    SourceDefaultDimension.SetRange("No.", VendorTemplate.Code);
                    if SourceDefaultDimension.FindSet() then
                        repeat
                            DestDefaultDimension.Init();
                            DestDefaultDimension.Validate("Table ID", Database::"Vendor Templ.");
                            DestDefaultDimension.Validate("No.", VendorTempl.Code);
                            DestDefaultDimension.Validate("Dimension Code", SourceDefaultDimension."Dimension Code");
                            DestDefaultDimension.Validate("Dimension Value Code", SourceDefaultDimension."Dimension Value Code");
                            DestDefaultDimension.Validate("Value Posting", SourceDefaultDimension."Value Posting");
                            if DestDefaultDimension.Insert(true) then;
                        until SourceDefaultDimension.Next() = 0;
                end;
            until VendorTemplate.Next() = 0;

        UpgradeTag.SetUpgradeTag(LocalUpgradeTagDefinitions.GetVendorTemplateUpgradeTag());
    end;

    local procedure UpdateIntrastatJnlLine()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        UpgradeTag: Codeunit "Upgrade Tag";
        LocalUpgradeTagDefinitions: Codeunit "Local Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(LocalUpgradeTagDefinitions.GetIntrastatJnlLineShipmentMethodCodeUpgradeTag()) then
            exit;

        IntrastatJnlLine.SetFilter("Shipment Method Code", '<>%1', '');
        if IntrastatJnlLine.FindSet() then
            repeat
                IntrastatJnlLine."Shpt. Method Code" := IntrastatJnlLine."Shipment Method Code";
                IntrastatJnlLine.Modify();
            until IntrastatJnlLine.Next() = 0;

        UpgradeTag.SetUpgradeTag(LocalUpgradeTagDefinitions.GetIntrastatJnlLineShipmentMethodCodeUpgradeTag());
    end;

    local procedure UpdateItemJournalLine()
    var
        ItemJournalLine: Record "Item Journal Line";
        UpgradeTag: Codeunit "Upgrade Tag";
        LocalUpgradeTagDefinitions: Codeunit "Local Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(LocalUpgradeTagDefinitions.GetItemJournalLineShipmentMethodCodeUpgradeTag()) then
            exit;

        ItemJournalLine.SetFilter("Shipment Method Code", '<>%1', '');
        if ItemJournalLine.FindSet() then
            repeat
                ItemJournalLine."Shpt. Method Code" := ItemJournalLine."Shipment Method Code";
                ItemJournalLine.Modify();
            until ItemJournalLine.Next() = 0;

        UpgradeTag.SetUpgradeTag(LocalUpgradeTagDefinitions.GetItemJournalLineShipmentMethodCodeUpgradeTag());
    end;

    local procedure UpdateItemLedgerEntry()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        UpgradeTag: Codeunit "Upgrade Tag";
        LocalUpgradeTagDefinitions: Codeunit "Local Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(LocalUpgradeTagDefinitions.GetItemLedgerEntryShipmentMethodCodeUpgradeTag()) then
            exit;

        ItemLedgerEntry.SetFilter("Shipment Method Code", '<>%1', '');
        if ItemLedgerEntry.FindSet() then
            repeat
                ItemLedgerEntry."Shpt. Method Code" := ItemLedgerEntry."Shipment Method Code";
                ItemLedgerEntry.Modify();
            until ItemLedgerEntry.Next() = 0;

        UpgradeTag.SetUpgradeTag(LocalUpgradeTagDefinitions.GetItemLedgerEntryShipmentMethodCodeUpgradeTag());
    end;

    local procedure UpdateCashDeskWorkflowTemplate()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        LocalUpgradeTagDefinitions: Codeunit "Local Upgrade Tag Definitions";
        CashDocApprWorkflowCodeTxt: Label 'MS-CDAPW', Locked = true;
    begin
        if UpgradeTag.HasUpgradeTag(LocalUpgradeTagDefinitions.GetCashDeskWorkflowTemplatesCodeUpgradeTag()) then
            exit;

        DeleteWorkflowTemplate(CashDocApprWorkflowCodeTxt);

        UpgradeTag.SetUpgradeTag(LocalUpgradeTagDefinitions.GetCashDeskWorkflowTemplatesCodeUpgradeTag());
    end;

    local procedure UpdateCreditWorkflowTemplate()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        LocalUpgradeTagDefinitions: Codeunit "Local Upgrade Tag Definitions";
        CreditDocApprWorkflowCodeTxt: Label 'MS-CRAPW', Locked = true;
    begin
        if UpgradeTag.HasUpgradeTag(LocalUpgradeTagDefinitions.GetCreditWorkflowTemplatesCodeUpgradeTag()) then
            exit;

        DeleteWorkflowTemplate(CreditDocApprWorkflowCodeTxt);

        UpgradeTag.SetUpgradeTag(LocalUpgradeTagDefinitions.GetCreditWorkflowTemplatesCodeUpgradeTag());
    end;

    local procedure UpdatePaymentOrderWorkflowTemplate()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        LocalUpgradeTagDefinitions: Codeunit "Local Upgrade Tag Definitions";
        PaymentOrderApprWorkflowCodeTxt: Label 'MS-PMTORDAPW', Locked = true;
    begin
        if UpgradeTag.HasUpgradeTag(LocalUpgradeTagDefinitions.GetPaymentOrderWorkflowTemplatesCodeUpgradeTag()) then
            exit;

        DeleteWorkflowTemplate(PaymentOrderApprWorkflowCodeTxt);

        UpgradeTag.SetUpgradeTag(LocalUpgradeTagDefinitions.GetPaymentOrderWorkflowTemplatesCodeUpgradeTag());
    end;

    local procedure UpdateAdvanceLetterWorkflowTemplate()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        LocalUpgradeTagDefinitions: Codeunit "Local Upgrade Tag Definitions";
        SalesAdvanceLetterApprWorkflowCodeTxt: Label 'MS-SALAPW', Locked = true;
        PurchAdvanceLetterApprWorkflowCodeTxt: Label 'MS-PALAPW', Locked = true;
    begin
        if UpgradeTag.HasUpgradeTag(LocalUpgradeTagDefinitions.GetAdvanceLetterWorkflowTemplatesCodeUpgradeTag()) then
            exit;

        DeleteWorkflowTemplate(SalesAdvanceLetterApprWorkflowCodeTxt);
        DeleteWorkflowTemplate(PurchAdvanceLetterApprWorkflowCodeTxt);

        UpgradeTag.SetUpgradeTag(LocalUpgradeTagDefinitions.GetAdvanceLetterWorkflowTemplatesCodeUpgradeTag());
    end;

    local procedure UpdateReplaceMultipleInterestRate()
    begin
        UpdateMultipleInterestRateSetup();
        UpdateMultipleInterestRate();
        UpdateMultipleInterestRateFinanceChargeMemos();
        UpdateMultipleInterestRateReminders();
        UpdateMultipleInterestRateIssuedFinanceChargeMemos();
        UpdateMultipleInterestRateIssuedReminders();
    end;

    local procedure UpdateMultipleInterestRateSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        LocalUpgradeTagDefinitions: Codeunit "Local Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(LocalUpgradeTagDefinitions.GetReplaceMulIntRateSalesSetupUpgradeTag()) then
            exit;

        if not SalesReceivablesSetup.Get() then
            exit;

        SalesReceivablesSetup."Multiple Interest Rates" := false;
        SalesReceivablesSetup.Modify();

        UpgradeTag.SetUpgradeTag(LocalUpgradeTagDefinitions.GetReplaceMulIntRateSalesSetupUpgradeTag());
    end;

    local procedure UpdateMultipleInterestRate()
    var
        FinanceChargeInterestRate: Record "Finance Charge Interest Rate";
        MultipleInterestRate: Record "Multiple Interest Rate";
        UpgradeTag: Codeunit "Upgrade Tag";
        LocalUpgradeTagDefinitions: Codeunit "Local Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(LocalUpgradeTagDefinitions.GetReplaceMulIntRateFinChargeIntRateUpgradeTag()) then
            exit;

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

        UpgradeTag.SetUpgradeTag(LocalUpgradeTagDefinitions.GetReplaceMulIntRateFinChargeIntRateUpgradeTag());
    end;

    local procedure UpdateMultipleInterestRateFinanceChargeMemos()
    var
        DetailedFinChargeMemoLine: Record "Detailed Fin. Charge Memo Line";
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        TempFinanceChargeMemoLine: Record "Finance Charge Memo Line" temporary;
        TempDetailedFinChargeMemoLine: Record "Detailed Fin. Charge Memo Line" temporary;
        UpgradeTag: Codeunit "Upgrade Tag";
        LocalUpgradeTagDefinitions: Codeunit "Local Upgrade Tag Definitions";
        ListOfDocumentNo: List of [Code[20]];
        DocumentNo: Code[20];
        LineNo: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(LocalUpgradeTagDefinitions.GetReplaceMulIntRateFinanceChargeMemosUpgradeTag()) then
            exit;

        if FinanceChargeMemoHeader.FindSet() then
            repeat
                FinanceChargeMemoHeader."Multiple Interest Rates" := false;
                FinanceChargeMemoHeader.Modify();
            until FinanceChargeMemoHeader.Next() = 0;

        if DetailedFinChargeMemoLine.FindSet() then
            repeat
                if not ListOfDocumentNo.Contains(DetailedFinChargeMemoLine."Finance Charge Memo No.") then
                    ListOfDocumentNo.Add(DetailedFinChargeMemoLine."Finance Charge Memo No.");
                TempDetailedFinChargeMemoLine.Init();
                TempDetailedFinChargeMemoLine := DetailedFinChargeMemoLine;
                TempDetailedFinChargeMemoLine.Insert();
            until DetailedFinChargeMemoLine.Next() = 0;

        // remove already upgraded documents
        foreach DocumentNo in ListOfDocumentNo do begin
            FinanceChargeMemoLine.SetRange("Finance Charge Memo No.", DocumentNo);
            FinanceChargeMemoLine.SetRange("Detailed Interest Rates Entry", true);
            if not FinanceChargeMemoLine.IsEmpty() then
                ListOfDocumentNo.Remove(DocumentNo);
        end;

        // recreate lines of documents
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

        UpgradeTag.SetUpgradeTag(LocalUpgradeTagDefinitions.GetReplaceMulIntRateFinanceChargeMemosUpgradeTag());
    end;

    local procedure UpdateMultipleInterestRateReminders()
    var
        DetailedReminderLine: Record "Detailed Reminder Line";
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        TempReminderLine: Record "Reminder Line" temporary;
        TempDetailedReminderLine: Record "Detailed Reminder Line" temporary;
        UpgradeTag: Codeunit "Upgrade Tag";
        LocalUpgradeTagDefinitions: Codeunit "Local Upgrade Tag Definitions";
        ListOfDocumentNo: List of [Code[20]];
        DocumentNo: Code[20];
        LineNo: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(LocalUpgradeTagDefinitions.GetReplaceMulIntRateRemindersUpgradeTag()) then
            exit;

        if ReminderHeader.FindSet() then
            repeat
                ReminderHeader."Multiple Interest Rates" := false;
                ReminderHeader.Modify();
            until ReminderHeader.Next() = 0;

        if DetailedReminderLine.FindSet() then
            repeat
                if not ListOfDocumentNo.Contains(DetailedReminderLine."Reminder No.") then
                    ListOfDocumentNo.Add(DetailedReminderLine."Reminder No.");
                TempDetailedReminderLine.Init();
                TempDetailedReminderLine := DetailedReminderLine;
                TempDetailedReminderLine.Insert();
            until DetailedReminderLine.Next() = 0;

        // remove already upgraded documents
        foreach DocumentNo in ListOfDocumentNo do begin
            ReminderLine.SetRange("Reminder No.", DocumentNo);
            ReminderLine.SetRange("Detailed Interest Rates Entry", true);
            if not ReminderLine.IsEmpty() then
                ListOfDocumentNo.Remove(DocumentNo);
        end;

        // recreate lines of documents
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

        UpgradeTag.SetUpgradeTag(LocalUpgradeTagDefinitions.GetReplaceMulIntRateRemindersUpgradeTag());
    end;

    local procedure UpdateMultipleInterestRateIssuedFinanceChargeMemos()
    var
        DetailedIssFinChMemoLine: Record "Detailed Iss.Fin.Ch. Memo Line";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line";
        FinanceChargeTerms: Record "Finance Charge Terms";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ExtraIssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line";
        TempIssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line" temporary;
        TempDetailedIssFinChMemoLine: Record "Detailed Iss.Fin.Ch. Memo Line" temporary;
        UpgradeTag: Codeunit "Upgrade Tag";
        LocalUpgradeTagDefinitions: Codeunit "Local Upgrade Tag Definitions";
        ListOfDocumentNo: List of [Code[20]];
        BaseAmount: Decimal;
        DocumentNo: Code[20];
        DueDate: Date;
        LineNo: Integer;
        Days: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(LocalUpgradeTagDefinitions.GetReplaceMulIntRateIssuedFinanceChargeMemosUpgradeTag()) then
            exit;

        if IssuedFinChargeMemoHeader.FindSet() then
            repeat
                IssuedFinChargeMemoHeader."Multiple Interest Rates" := false;
                IssuedFinChargeMemoHeader.Modify();
            until IssuedFinChargeMemoHeader.Next() = 0;

        if DetailedIssFinChMemoLine.FindSet() then
            repeat
                if not ListOfDocumentNo.Contains(DetailedIssFinChMemoLine."Finance Charge Memo No.") then
                    ListOfDocumentNo.Add(DetailedIssFinChMemoLine."Finance Charge Memo No.");
                TempDetailedIssFinChMemoLine.Init();
                TempDetailedIssFinChMemoLine := DetailedIssFinChMemoLine;
                TempDetailedIssFinChMemoLine.Insert();

                DetailedIssFinChMemoLine.Delete();
            until DetailedIssFinChMemoLine.Next() = 0;

        // remove already upgraded documents
        foreach DocumentNo in ListOfDocumentNo do begin
            IssuedFinChargeMemoLine.SetRange("Finance Charge Memo No.", DocumentNo);
            IssuedFinChargeMemoLine.SetRange("Detailed Interest Rates Entry", true);
            if not IssuedFinChargeMemoLine.IsEmpty() then
                ListOfDocumentNo.Remove(DocumentNo);
        end;

        // recreate lines of documents
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

        UpgradeTag.SetUpgradeTag(LocalUpgradeTagDefinitions.GetReplaceMulIntRateIssuedFinanceChargeMemosUpgradeTag());
    end;

    local procedure UpdateMultipleInterestRateIssuedReminders()
    var
        DetailedIssuedReminderLine: Record "Detailed Issued Reminder Line";
        IssuedReminderHeader: Record "Issued Reminder Header";
        IssuedReminderLine: Record "Issued Reminder Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ExtraIssuedReminderLine: Record "Issued Reminder Line";
        TempIssuedReminderLine: Record "Issued Reminder Line" temporary;
        TempDetailedIssuedReminderLine: Record "Detailed Issued Reminder Line" temporary;
        UpgradeTag: Codeunit "Upgrade Tag";
        LocalUpgradeTagDefinitions: Codeunit "Local Upgrade Tag Definitions";
        ListOfDocumentNo: List of [Code[20]];
        DocumentNo: Code[20];
        DueDate: Date;
        LineNo: Integer;
        Days: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(LocalUpgradeTagDefinitions.GetReplaceMulIntRateIssuedRemindersUpgradeTag()) then
            exit;

        if IssuedReminderHeader.FindSet() then
            repeat
                IssuedReminderHeader."Multiple Interest Rates" := false;
                IssuedReminderHeader.Modify();
            until IssuedReminderHeader.Next() = 0;

        if DetailedIssuedReminderLine.FindSet() then
            repeat
                if not ListOfDocumentNo.Contains(DetailedIssuedReminderLine."Issued Reminder No.") then
                    ListOfDocumentNo.Add(DetailedIssuedReminderLine."Issued Reminder No.");
                TempDetailedIssuedReminderLine.Init();
                TempDetailedIssuedReminderLine := DetailedIssuedReminderLine;
                TempDetailedIssuedReminderLine.Insert();

                DetailedIssuedReminderLine.Delete();
            until DetailedIssuedReminderLine.Next() = 0;

        // remove already upgraded documents
        foreach DocumentNo in ListOfDocumentNo do begin
            IssuedReminderLine.SetRange("Reminder No.", DocumentNo);
            IssuedReminderLine.SetRange("Detailed Interest Rates Entry", true);
            if not IssuedReminderLine.IsEmpty() then
                ListOfDocumentNo.Remove(DocumentNo);
        end;

        // recreate lines of documents
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

        UpgradeTag.SetUpgradeTag(LocalUpgradeTagDefinitions.GetReplaceMulIntRateIssuedRemindersUpgradeTag());
    end;

    local procedure BuildDescription(LineDescription: Text[100]; EntryDescription: Text[100]; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; CurrencyCode: Code[20]; InterestRate: Decimal; DueDate: Date; NrOfDays: Integer; OriginalAmount: Decimal; BaseAmount: Decimal): Text[100]
    var
        AutoFormat: Codeunit "Auto Format";
        AutoFormatType: Enum "Auto Format";
        DocumentTypeText: Text[30];
        DocumentTxt: Label 'Document';
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

    internal procedure DeleteWorkflowTemplate(WorkflowCode: Code[20])
    var
        Workflow: Record Workflow;
    begin
        if Workflow.Get(WorkflowCode) then begin
            Workflow.TestField(Template, true);
            DeleteWorkflowSteps(Workflow.Code);
            Workflow.Delete(false);
        end;
    end;

    local procedure DeleteWorkflowSteps(WorkflowCode: Code[20])
    var
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowRule: Record "Workflow Rule";
        ZeroGuid: Guid;
    begin
        WorkflowStep.SetRange("Workflow Code", WorkflowCode);
        if WorkflowStep.FindSet() then
            repeat
                if WorkflowStepArgument.Get(WorkflowStep.Argument) then
                    WorkflowStepArgument.Delete(false);

                WorkflowRule.SetRange("Workflow Code", WorkflowStep."Workflow Code");
                WorkflowRule.SetRange("Workflow Step ID", WorkflowStep.ID);
                WorkflowRule.SetRange("Workflow Step Instance ID", ZeroGuid);
                if not WorkflowRule.IsEmpty() then
                    WorkflowRule.DeleteAll();

                WorkflowStep.Delete(false);
            until WorkflowStep.Next() = 0;
    end;
}