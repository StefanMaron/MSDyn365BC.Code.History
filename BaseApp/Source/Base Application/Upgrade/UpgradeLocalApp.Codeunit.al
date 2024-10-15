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
#if CLEAN19

    var
        DefaultCodeTxt: Label 'DEFAULT';
#endif

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
#if CLEAN19
        UpdatePaymentOrderWorkflowTemplate();
        UpdateAdvanceLetterWorkflowTemplate();
        UpdateBankPaymentApplicationRule();
#endif
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

#if CLEAN19
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

    local procedure UpdateBankPaymentApplicationRule()
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        BankPmtApplRule2: Record "Bank Pmt. Appl. Rule";
        BankPmtApplRuleCode: Record "Bank Pmt. Appl. Rule Code";
        BankPmtApplSettings: Record "Bank Pmt. Appl. Settings";
        BankPmtApplSettings2: Record "Bank Pmt. Appl. Settings";
        UpgradeTag: Codeunit "Upgrade Tag";
        LocalUpgradeTagDefinitions: Codeunit "Local Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(LocalUpgradeTagDefinitions.GetBankPaymentApplicationWithoutCodeUpgradeTag()) then
            exit;

        BankPmtApplRule.SetRange("Bank Pmt. Appl. Rule Code", DefaultCodeTxt);
        if BankPmtApplRule.FindSet(true) then begin
            BankPmtApplRule2.SetRange("Bank Pmt. Appl. Rule Code", BankPmtApplRule2.GetDefaultCode());
            BankPmtApplRule2.DeleteAll();
            repeat
                BankPmtApplRule2.Init();
                BankPmtApplRule2 := BankPmtApplRule;
                BankPmtApplRule2."Bank Pmt. Appl. Rule Code" := BankPmtApplRule2.GetDefaultCode();
                BankPmtApplRule2.Insert();
            until BankPmtApplRule.Next() = 0;
            BankPmtApplRule.DeleteAll();
        end;

        if BankPmtApplSettings.Get(DefaultCodeTxt) then begin
            if BankPmtApplSettings2.Get(BankPmtApplRule.GetDefaultCode()) then
                BankPmtApplSettings2.Delete();
            BankPmtApplSettings2.Init();
            BankPmtApplSettings2 := BankPmtApplSettings;
            BankPmtApplSettings2.PrimaryKey := BankPmtApplRule.GetDefaultCode();
            BankPmtApplSettings2.Insert();
            BankPmtApplSettings.Delete();
        end;

        UpgradeTag.SetUpgradeTag(LocalUpgradeTagDefinitions.GetBankPaymentApplicationWithoutCodeUpgradeTag());
    end;
#endif

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