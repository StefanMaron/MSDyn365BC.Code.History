codeunit 2 "Company-Initialize"
{
    Permissions = TableData "Company Information" = i,
                  TableData "General Ledger Setup" = i,
                  TableData "Incoming Documents Setup" = i,
                  TableData "Sales & Receivables Setup" = i,
                  TableData "Purchases & Payables Setup" = i,
                  TableData "Inventory Setup" = i,
                  TableData "Resources Setup" = i,
                  TableData "Jobs Setup" = i,
                  TableData "Tax Setup" = i,
                  TableData "VAT Report Setup" = i,
                  TableData "Cash Flow Setup" = i,
                  TableData "Social Listening Setup" = i,
                  TableData "Assembly Setup" = i,
                  TableData "Job WIP Method" = i,
                  TableData "Cost Accounting Setup" = i,
                  TableData "Data Migration Setup" = i,
                  TableData "Marketing Setup" = i,
                  TableData "Interaction Template Setup" = i,
                  TableData "Human Resources Setup" = i,
                  TableData "FA Setup" = i,
                  TableData "Nonstock Item Setup" = i,
                  TableData "Warehouse Setup" = i,
                  TableData "Service Mgt. Setup" = i,
                  TableData "Config. Setup" = i;

    trigger OnRun()
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        TransformationRule: Record "Transformation Rule";
        AddOnIntegrMgt: Codeunit AddOnIntegrManagement;
        WorkflowSetup: Codeunit "Workflow Setup";
        VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
        SatisfactionSurveyMgt: Codeunit "Satisfaction Survey Mgt.";
        UpgradeTag: Codeunit "Upgrade Tag";
        Window: Dialog;
    begin
        Window.Open(Text000);

        OnBeforeOnRun;

        InitSetupTables;
        AddOnIntegrMgt.InitMfgSetup;
        InitSourceCodeSetup;
        InitStandardTexts;
        InitReportSelection;
        InitJobWIPMethods;
        InitBankExportImportSetup;
        InitDocExchServiceSetup;
        BankPmtApplRule.InsertDefaultMatchingRules;
        InsertClientAddIns;
        VATRegistrationLogMgt.InitServiceSetup;
        WorkflowSetup.InitWorkflow;
        TransformationRule.CreateDefaultTransformations;
        InitElectronicFormats;
        InitApplicationAreasForSaaS;
        SatisfactionSurveyMgt.ResetCache;
        UpgradeTag.SetAllUpgradeTags();

        OnCompanyInitialize;

        Window.Close;

        Commit;
    end;

    var
        Text000: Label 'Initializing company...';
        SEPACTCodeTxt: Label 'SEPACT', Comment = 'No need to translate - but can be translated at will.';
        SEPACTNameTxt: Label 'SEPA Credit Transfer';
        SEPADDCodeTxt: Label 'SEPADD', Comment = 'No need to translate - but can be translated at will.';
        SEPADDNameTxt: Label 'SEPA Direct Debit';
        Text001: Label 'SALES';
        Text002: Label 'Sales';
        Text003: Label 'PURCHASES';
        Text004: Label 'Purchases';
        Text005: Label 'DELETE';
        Text006: Label 'INVTPCOST';
        Text007: Label 'EXCHRATADJ';
        Text010: Label 'CLSINCOME';
        Text011: Label 'CONSOLID';
        Text012: Label 'Consolidation';
        Text013: Label 'GENJNL';
        Text014: Label 'SALESJNL';
        Text015: Label 'PURCHJNL';
        Text016: Label 'CASHRECJNL';
        Text017: Label 'PAYMENTJNL';
        Text018: Label 'ITEMJNL';
        Text020: Label 'PHYSINVJNL';
        Text022: Label 'RESJNL';
        Text023: Label 'JOBJNL';
        Text024: Label 'SALESAPPL';
        Text025: Label 'Sales Entry Application';
        PaymentReconJnlTok: Label 'PAYMTRECON', Comment = 'Payment Reconciliation Journal Code';
        Text026: Label 'PURCHAPPL';
        Text027: Label 'Purchase Entry Application';
        EmployeeEntryApplicationCodeTxt: Label 'EMPLAPPL', Comment = 'EMPL stands for employee, APPL stands for application';
        EmployeeEntryApplicationTxt: Label 'Employee Entry Application';
        Text028: Label 'VATSTMT';
        Text029: Label 'COMPRGL';
        Text030: Label 'COMPRVAT';
        Text031: Label 'COMPRCUST';
        Text032: Label 'COMPRVEND';
        Text035: Label 'COMPRRES';
        Text036: Label 'COMPRJOB';
        Text037: Label 'COMPRBANK';
        Text038: Label 'COMPRCHECK';
        Text039: Label 'FINVOIDCHK';
        Text040: Label 'Financially Voided Check';
        Text041: Label 'REMINDER';
        Text042: Label 'Reminder';
        Text043: Label 'FINCHRG';
        Text044: Label 'Finance Charge Memo';
        Text045: Label 'FAGLJNL';
        Text046: Label 'FAJNL';
        Text047: Label 'INSJNL';
        Text048: Label 'COMPRFA';
        Text049: Label 'COMPRMAINT';
        Text050: Label 'COMPRINS';
        Text051: Label 'ADJADDCURR';
        Text052: Label 'MD';
        Text053: Label 'Monthly Depreciation';
        Text054: Label 'SC';
        Text055: Label 'Shipping Charge';
        Text056: Label 'SUC';
        Text057: Label 'Sale under Contract';
        Text058: Label 'TE';
        Text059: Label 'Travel Expenses';
        Text063: Label 'TRANSFER';
        Text064: Label 'Transfer';
        Text065: Label 'RECLASSJNL';
        Text066: Label 'REVALJNL';
        Text067: Label 'CONSUMPJNL';
        Text068: Label 'INVTADJMT';
        Text069: Label 'POINOUTJNL';
        Text070: Label 'CAPACITJNL';
        Text071: Label 'WHITEM';
        Text072: Label 'WHPHYSINVT';
        Text073: Label 'WHRCLSSJNL';
        Text074: Label 'SERVICE';
        Text075: Label 'Service Management';
        Text076: Label 'BANKREC';
        Text077: Label 'WHPUTAWAY';
        Text078: Label 'WHPICK';
        Text079: Label 'WHMOVEMENT';
        Text080: Label 'Whse. Put-away';
        Text081: Label 'Whse. Pick';
        Text082: Label 'Whse. Movement';
        Text083: Label 'COMPRWHSE';
        Text084: Label 'INTERCOMP';
        Text085: Label 'Intercompany';
        Text086: Label 'UNAPPSALES';
        Text087: Label 'Unapplied Sales Entry Application';
        UnappliedEmplEntryApplnCodeTxt: Label 'UNAPPEMPL', Comment = 'EMPL stands for employee, UNAPP stands for unapply';
        UnappliedEmplEntryApplnTxt: Label 'Unapplied Employee Entry Application';
        Text088: Label 'UNAPPPURCH';
        Text089: Label 'Unapplied Purchase Entry Application';
        Text090: Label 'REVERSAL';
        Text091: Label 'Reversal Entry ';
        Text092: Label 'PRODORDER';
        Text99000004: Label 'FLUSHING';
        Text99000005: Label 'Flushing';
        Text096: Label 'JOBGLJNL';
        Text097: Label 'JOBGLWIP';
        Text098: Label 'WIP Entry';
        Text099: Label 'Date Compress Job Ledge';
        Text100: Label 'COMPRIBUDG', Locked = true;
        Text101: Label 'Completed Contract';
        Text102: Label 'Cost of Sales';
        Text103: Label 'Cost Value';
        Text104: Label 'Sales Value';
        Text105: Label 'Percentage of Completion';
        Text106: Label 'POC';
        Text109: Label 'CFWKSH', Comment = 'Uppercase of the translation of cash flow work sheet with a max of 10 char';
        Text110: Label 'Cash Flow Worksheet';
        Text107: Label 'ASSEMBLY', Comment = 'Uppercase of the translation of assembly with a max of 10 char';
        Text108: Label 'Assembly';
        Text111: Label 'GL';
        Text112: Label 'G/L Entry to Cost Accounting';
        Text113: Label 'CAJOUR', Comment = 'Uppercase of the translation of cost accounting journal with a max of 10 char';
        Text114: Label 'Cost Journal';
        Text115: Label 'ALLOC', Comment = 'Uppercase of the translation of allocation with a max of 10 char';
        Text116: Label 'Cost Allocation';
        Text117: Label 'TRABUD', Comment = 'Uppercase of the translation of Transfer Budget to Actual with a max of 10 char';
        Text118: Label 'Transfer Budget to Actual';
        InvtOrderTxt: Label 'INVTORDER', Comment = 'INVENTORY ORDERS';
        PEPPOL21_ElectronicFormatTxt: Label 'PEPPOL 2.1', Locked = true;
        PEPPOL21_ElectronicFormatDescriptionTxt: Label 'PEPPOL 2.1 Format (Pan-European Public Procurement Online)';
        PEPPOL20_ElectronicFormatTxt: Label 'PEPPOL 2.0', Locked = true;
        PEPPOL20_ElectronicFormatDescriptionTxt: Label 'PEPPOL 2.0 Format (Pan-European Public Procurement Online)';
        PEPPOLBIS3_ElectronicFormatTxt: Label 'PEPPOL BIS3', Locked = true;
        PEPPOLBIS3_ElectronicFormatDescriptionTxt: Label 'PEPPOL BIS3 Format (Pan-European Public Procurement Online)';

    procedure InitSetupTables()
    var
        GLSetup: Record "General Ledger Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        InvtSetup: Record "Inventory Setup";
        ResourcesSetup: Record "Resources Setup";
        JobsSetup: Record "Jobs Setup";
        HumanResourcesSetup: Record "Human Resources Setup";
        MarketingSetup: Record "Marketing Setup";
        InteractionTemplateSetup: Record "Interaction Template Setup";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        NonstockItemSetup: Record "Nonstock Item Setup";
        FASetup: Record "FA Setup";
        CashFlowSetup: Record "Cash Flow Setup";
        CostAccSetup: Record "Cost Accounting Setup";
        WhseSetup: Record "Warehouse Setup";
        AssemblySetup: Record "Assembly Setup";
        VATReportSetup: Record "VAT Report Setup";
        TaxSetup: Record "Tax Setup";
        ConfigSetup: Record "Config. Setup";
        DataMigrationSetup: Record "Data Migration Setup";
        IncomingDocumentsSetup: Record "Incoming Documents Setup";
        CompanyInfo: Record "Company Information";
        SocialListeningSetup: Record "Social Listening Setup";
    begin
        with GLSetup do
            if not FindFirst then begin
                Init;
                Insert;
            end;

        with SalesSetup do
            if not FindFirst then begin
                Init;
                Insert;
            end;

        with MarketingSetup do
            if not FindFirst then begin
                Init;
                Insert;
            end;

        with InteractionTemplateSetup do
            if not FindFirst then begin
                Init;
                Insert;
            end;

        with ServiceMgtSetup do
            if not FindFirst then begin
                Init;
                Insert;
            end;

        with SocialListeningSetup do
            if not FindFirst then begin
                Init;
                Insert(true);
            end;

        with PurchSetup do
            if not FindFirst then begin
                Init;
                Insert;
            end;

        with InvtSetup do
            if not FindFirst then begin
                Init;
                Insert;
            end;

        with ResourcesSetup do
            if not FindFirst then begin
                Init;
                Insert;
            end;

        with JobsSetup do
            if not FindFirst then begin
                Init;
                Insert;
            end;

        with FASetup do
            if not FindFirst then begin
                Init;
                Insert;
            end;

        with HumanResourcesSetup do
            if not FindFirst then begin
                Init;
                Insert;
            end;

        with WhseSetup do
            if not FindFirst then begin
                Init;
                Insert;
            end;

        with NonstockItemSetup do
            if not FindFirst then begin
                Init;
                Insert;
            end;

        with CashFlowSetup do
            if not FindFirst then begin
                Init;
                Insert;
            end;

        with CostAccSetup do
            if WritePermission then
                if not FindFirst then begin
                    Init;
                    Insert;
                end;

        with AssemblySetup do
            if not FindFirst then begin
                Init;
                Insert;
            end;

        with VATReportSetup do
            if not FindFirst then begin
                Init;
                Insert;
            end;

        with TaxSetup do
            if not FindFirst then begin
                Init;
                Insert;
            end;

        with ConfigSetup do
            if not FindFirst then begin
                Init;
                Insert;
            end;

        with DataMigrationSetup do
            if not FindFirst then begin
                Init;
                Insert;
            end;

        with IncomingDocumentsSetup do
            if not FindFirst then begin
                Init;
                Insert;
            end;

        with CompanyInfo do
            if not FindFirst then begin
                Init;
                "Created DateTime" := CurrentDateTime;
                Insert;
            end;
    end;

    local procedure InitSourceCodeSetup()
    var
        SourceCode: Record "Source Code";
        SourceCodeSetup: Record "Source Code Setup";
    begin
        if not (SourceCodeSetup.FindFirst or SourceCode.FindFirst) then
            with SourceCodeSetup do begin
                Init;
                InsertSourceCode(Sales, Text001, Text002);
                InsertSourceCode(Purchases, Text003, Text004);
                InsertSourceCode("Deleted Document", Text005, CopyStr(FieldCaption("Deleted Document"), 1, 30));
                InsertSourceCode("Inventory Post Cost", Text006, ReportName(REPORT::"Post Inventory Cost to G/L"));
                InsertSourceCode("Exchange Rate Adjmt.", Text007, ReportName(REPORT::"Adjust Exchange Rates"));
                InsertSourceCode("Close Income Statement", Text010, ReportName(REPORT::"Close Income Statement"));
                InsertSourceCode(Consolidation, Text011, Text012);
                InsertSourceCode("General Journal", Text013, PageName(PAGE::"General Journal"));
                InsertSourceCode("Sales Journal", Text014, PageName(PAGE::"Sales Journal"));
                InsertSourceCode("Purchase Journal", Text015, PageName(PAGE::"Purchase Journal"));
                InsertSourceCode("Cash Receipt Journal", Text016, PageName(PAGE::"Cash Receipt Journal"));
                InsertSourceCode("Payment Journal", Text017, PageName(PAGE::"Payment Journal"));
                InsertSourceCode("Payment Reconciliation Journal", PaymentReconJnlTok, PageName(PAGE::"Payment Reconciliation Journal"));
                InsertSourceCode("Item Journal", Text018, PageName(PAGE::"Item Journal"));
                InsertSourceCode(Transfer, Text063, Text064);
                InsertSourceCode("Item Reclass. Journal", Text065, PageName(PAGE::"Item Reclass. Journal"));
                InsertSourceCode("Phys. Inventory Journal", Text020, PageName(PAGE::"Phys. Inventory Journal"));
                InsertSourceCode("Revaluation Journal", Text066, PageName(PAGE::"Revaluation Journal"));
                InsertSourceCode("Consumption Journal", Text067, PageName(PAGE::"Consumption Journal"));
                InsertSourceCode("Output Journal", Text069, PageName(PAGE::"Output Journal"));
                InsertSourceCode("Production Journal", Text092, PageName(PAGE::"Production Journal"));
                InsertSourceCode("Capacity Journal", Text070, PageName(PAGE::"Capacity Journal"));
                InsertSourceCode("Resource Journal", Text022, PageName(PAGE::"Resource Journal"));
                InsertSourceCode("Job Journal", Text023, PageName(PAGE::"Job Journal"));
                InsertSourceCode("Job G/L Journal", Text096, PageName(PAGE::"Job G/L Journal"));
                InsertSourceCode("Job G/L WIP", Text097, Text098);
                InsertSourceCode("Sales Entry Application", Text024, Text025);
                InsertSourceCode("Unapplied Sales Entry Appln.", Text086, Text087);
                InsertSourceCode("Unapplied Purch. Entry Appln.", Text088, Text089);
                InsertSourceCode("Unapplied Empl. Entry Appln.", UnappliedEmplEntryApplnCodeTxt, UnappliedEmplEntryApplnTxt);
                InsertSourceCode(Reversal, Text090, Text091);
                InsertSourceCode("Purchase Entry Application", Text026, Text027);
                InsertSourceCode("Employee Entry Application", EmployeeEntryApplicationCodeTxt, EmployeeEntryApplicationTxt);
                InsertSourceCode("VAT Settlement", Text028, ReportName(REPORT::"Calc. and Post VAT Settlement"));
                InsertSourceCode("Compress G/L", Text029, ReportName(REPORT::"Date Compress General Ledger"));
                InsertSourceCode("Compress VAT Entries", Text030, ReportName(REPORT::"Date Compress VAT Entries"));
                InsertSourceCode("Compress Cust. Ledger", Text031, ReportName(REPORT::"Date Compress Customer Ledger"));
                InsertSourceCode("Compress Vend. Ledger", Text032, ReportName(REPORT::"Date Compress Vendor Ledger"));
                InsertSourceCode("Compress Res. Ledger", Text035, ReportName(REPORT::"Date Compress Resource Ledger"));
                InsertSourceCode("Compress Job Ledger", Text036, Text099);
                InsertSourceCode("Compress Bank Acc. Ledger", Text037, ReportName(REPORT::"Date Compress Bank Acc. Ledger"));
                InsertSourceCode("Compress Check Ledger", Text038, ReportName(REPORT::"Delete Check Ledger Entries"));
                InsertSourceCode("Financially Voided Check", Text039, Text040);
                InsertSourceCode(Reminder, Text041, Text042);
                InsertSourceCode("Finance Charge Memo", Text043, Text044);
                InsertSourceCode("Trans. Bank Rec. to Gen. Jnl.", Text076, ReportName(REPORT::"Trans. Bank Rec. to Gen. Jnl."));
                InsertSourceCode("Fixed Asset G/L Journal", Text045, PageName(PAGE::"Fixed Asset G/L Journal"));
                InsertSourceCode("Fixed Asset Journal", Text046, PageName(PAGE::"Fixed Asset Journal"));
                InsertSourceCode("Insurance Journal", Text047, PageName(PAGE::"Insurance Journal"));
                InsertSourceCode("Compress FA Ledger", Text048, ReportName(REPORT::"Date Compress FA Ledger"));
                InsertSourceCode("Compress Maintenance Ledger", Text049, ReportName(REPORT::"Date Compress Maint. Ledger"));
                InsertSourceCode("Compress Insurance Ledger", Text050, ReportName(REPORT::"Date Compress Insurance Ledger"));
                InsertSourceCode("Adjust Add. Reporting Currency", Text051, ReportName(REPORT::"Adjust Add. Reporting Currency"));
                InsertSourceCode(Flushing, Text99000004, Text99000005);
                InsertSourceCode("Adjust Cost", Text068, ReportName(REPORT::"Adjust Cost - Item Entries"));
                InsertSourceCode("Compress Item Budget", Text100, ReportName(REPORT::"Date Comp. Item Budget Entries"));
                InsertSourceCode("Whse. Item Journal", Text071, PageName(PAGE::"Whse. Item Journal"));
                InsertSourceCode("Whse. Phys. Invt. Journal", Text072, PageName(PAGE::"Whse. Phys. Invt. Journal"));
                InsertSourceCode("Whse. Reclassification Journal", Text073, PageName(PAGE::"Whse. Reclassification Journal"));
                InsertSourceCode("Compress Whse. Entries", Text083, ReportName(REPORT::"Date Compress Whse. Entries"));
                InsertSourceCode("Whse. Put-away", Text077, Text080);
                InsertSourceCode("Whse. Pick", Text078, Text081);
                InsertSourceCode("Whse. Movement", Text079, Text082);
                InsertSourceCode("Service Management", Text074, Text075);
                InsertSourceCode("IC General Journal", Text084, Text085);
                InsertSourceCode("Cash Flow Worksheet", Text109, Text110);
                InsertSourceCode(Assembly, Text107, Text108);
                InsertSourceCode("G/L Entry to CA", Text111, Text112);
                InsertSourceCode("Cost Journal", Text113, Text114);
                InsertSourceCode("Cost Allocation", Text115, Text116);
                InsertSourceCode("Transfer Budget to Actual", Text117, Text118);
                InsertSourceCode("Phys. Invt. Orders", InvtOrderTxt, PageName(PAGE::"Physical Inventory Order"));
                Insert;
            end;
    end;

    local procedure InitStandardTexts()
    var
        StandardText: Record "Standard Text";
    begin
        if not StandardText.FindFirst then begin
            InsertStandardText(Text052, Text053);
            InsertStandardText(Text054, Text055);
            InsertStandardText(Text056, Text057);
            InsertStandardText(Text058, Text059);
        end;
    end;

    local procedure InitReportSelection()
    var
        ReportSelections: Record "Report Selections";
        ReportSelectionMgt: Codeunit "Report Selection Mgt.";
    begin
        if not ReportSelections.WritePermission then
            exit;
        ReportSelectionMgt.InitReportSelectionSales;
        ReportSelectionMgt.InitReportSelectionPurch;
        ReportSelectionMgt.InitReportSelectionBank;
        ReportSelectionMgt.InitReportSelectionCust;
        ReportSelectionMgt.InitReportSelectionInvt;
        ReportSelectionMgt.InitReportSelectionProd;
        ReportSelectionMgt.InitReportSelectionServ;
        ReportSelectionMgt.InitReportSelectionWhse;
    end;

    local procedure InitJobWIPMethods()
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        if not JobWIPMethod.FindFirst then begin
            InsertJobWIPMethod(Text101, Text101, JobWIPMethod."Recognized Costs"::"At Completion",
              JobWIPMethod."Recognized Sales"::"At Completion", 4);
            InsertJobWIPMethod(Text102, Text102, JobWIPMethod."Recognized Costs"::"Cost of Sales",
              JobWIPMethod."Recognized Sales"::"Contract (Invoiced Price)", 2);
            InsertJobWIPMethod(Text103, Text103, JobWIPMethod."Recognized Costs"::"Cost Value",
              JobWIPMethod."Recognized Sales"::"Contract (Invoiced Price)", 0);
            InsertJobWIPMethod(Text104, Text104, JobWIPMethod."Recognized Costs"::"Usage (Total Cost)",
              JobWIPMethod."Recognized Sales"::"Sales Value", 1);
            InsertJobWIPMethod(Text106, Text105, JobWIPMethod."Recognized Costs"::"Usage (Total Cost)",
              JobWIPMethod."Recognized Sales"::"Percentage of Completion", 3);
        end;
    end;

    local procedure InitBankExportImportSetup()
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        if not BankExportImportSetup.FindFirst then begin
            InsertBankExportImportSetup(SEPACTCodeTxt, SEPACTNameTxt, BankExportImportSetup.Direction::Export,
              CODEUNIT::"SEPA CT-Export File", XMLPORT::"SEPA CT pain.001.001.03", CODEUNIT::"SEPA CT-Check Line");
            InsertBankExportImportSetup(SEPADDCodeTxt, SEPADDNameTxt, BankExportImportSetup.Direction::Export,
              CODEUNIT::"SEPA DD-Export File", XMLPORT::"SEPA DD pain.008.001.02", CODEUNIT::"SEPA DD-Check Line");
        end;
    end;

    local procedure InitDocExchServiceSetup()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        with DocExchServiceSetup do
            if not Get then begin
                Init;
                SetURLsToDefault;
                Insert;
            end;
    end;

    local procedure InitElectronicFormats()
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        ElectronicDocumentFormat.InsertElectronicFormat(
          PEPPOL21_ElectronicFormatTxt, PEPPOL21_ElectronicFormatDescriptionTxt,
          CODEUNIT::"Export Sales Inv. - PEPPOL 2.1", 0, ElectronicDocumentFormat.Usage::"Sales Invoice");

        ElectronicDocumentFormat.InsertElectronicFormat(
          PEPPOL21_ElectronicFormatTxt, PEPPOL21_ElectronicFormatDescriptionTxt,
          CODEUNIT::"Export Sales Cr.M. - PEPPOL2.1", 0, ElectronicDocumentFormat.Usage::"Sales Credit Memo");

        ElectronicDocumentFormat.InsertElectronicFormat(
          PEPPOL21_ElectronicFormatTxt, PEPPOL21_ElectronicFormatDescriptionTxt,
          CODEUNIT::"Export Serv. Inv. - PEPPOL 2.1", 0, ElectronicDocumentFormat.Usage::"Service Invoice");

        ElectronicDocumentFormat.InsertElectronicFormat(
          PEPPOL21_ElectronicFormatTxt, PEPPOL21_ElectronicFormatDescriptionTxt,
          CODEUNIT::"Exp. Service Cr.M. - PEPPOL2.1", 0, ElectronicDocumentFormat.Usage::"Service Credit Memo");

        ElectronicDocumentFormat.InsertElectronicFormat(
          PEPPOL21_ElectronicFormatTxt, PEPPOL21_ElectronicFormatDescriptionTxt,
          CODEUNIT::"PEPPOL Validation", 0, ElectronicDocumentFormat.Usage::"Sales Validation");

        ElectronicDocumentFormat.InsertElectronicFormat(
          PEPPOL21_ElectronicFormatTxt, PEPPOL21_ElectronicFormatDescriptionTxt,
          CODEUNIT::"PEPPOL Service Validation", 0, ElectronicDocumentFormat.Usage::"Service Validation");

        ElectronicDocumentFormat.InsertElectronicFormat(
          PEPPOL20_ElectronicFormatTxt, PEPPOL20_ElectronicFormatDescriptionTxt,
          CODEUNIT::"Export Sales Inv. - PEPPOL 2.0", 0, ElectronicDocumentFormat.Usage::"Sales Invoice");

        ElectronicDocumentFormat.InsertElectronicFormat(
          PEPPOL20_ElectronicFormatTxt, PEPPOL20_ElectronicFormatDescriptionTxt,
          CODEUNIT::"Export Sales Cr.M. - PEPPOL2.0", 0, ElectronicDocumentFormat.Usage::"Sales Credit Memo");

        ElectronicDocumentFormat.InsertElectronicFormat(
          PEPPOL20_ElectronicFormatTxt, PEPPOL20_ElectronicFormatDescriptionTxt,
          CODEUNIT::"Export Serv. Inv. - PEPPOL 2.0", 0, ElectronicDocumentFormat.Usage::"Service Invoice");

        ElectronicDocumentFormat.InsertElectronicFormat(
          PEPPOL20_ElectronicFormatTxt, PEPPOL20_ElectronicFormatDescriptionTxt,
          CODEUNIT::"Exp. Service Cr.M. - PEPPOL2.0", 0, ElectronicDocumentFormat.Usage::"Service Credit Memo");

        ElectronicDocumentFormat.InsertElectronicFormat(
          PEPPOL20_ElectronicFormatTxt, PEPPOL20_ElectronicFormatDescriptionTxt,
          CODEUNIT::"PEPPOL Validation", 0, ElectronicDocumentFormat.Usage::"Sales Validation");

        ElectronicDocumentFormat.InsertElectronicFormat(
          PEPPOL20_ElectronicFormatTxt, PEPPOL20_ElectronicFormatDescriptionTxt,
          CODEUNIT::"PEPPOL Service Validation", 0, ElectronicDocumentFormat.Usage::"Service Validation");

        ElectronicDocumentFormat.InsertElectronicFormat(
          PEPPOLBIS3_ElectronicFormatTxt, PEPPOLBIS3_ElectronicFormatDescriptionTxt,
          CODEUNIT::"Exp. Sales Inv. PEPPOL BIS3.0", 0, ElectronicDocumentFormat.Usage::"Sales Invoice");

        ElectronicDocumentFormat.InsertElectronicFormat(
          PEPPOLBIS3_ElectronicFormatTxt, PEPPOLBIS3_ElectronicFormatDescriptionTxt,
          CODEUNIT::"Exp. Sales CrM. PEPPOL BIS3.0", 0, ElectronicDocumentFormat.Usage::"Sales Credit Memo");

        ElectronicDocumentFormat.InsertElectronicFormat(
          PEPPOLBIS3_ElectronicFormatTxt, PEPPOLBIS3_ElectronicFormatDescriptionTxt,
          CODEUNIT::"Exp. Sales Inv. PEPPOL BIS3.0", 0, ElectronicDocumentFormat.Usage::"Service Invoice");

        ElectronicDocumentFormat.InsertElectronicFormat(
          PEPPOLBIS3_ElectronicFormatTxt, PEPPOLBIS3_ElectronicFormatDescriptionTxt,
          CODEUNIT::"Exp. Sales CrM. PEPPOL BIS3.0", 0, ElectronicDocumentFormat.Usage::"Service Credit Memo");
    end;

    local procedure InsertSourceCode(var SourceCodeDefCode: Code[10]; "Code": Code[10]; Description: Text[50])
    var
        SourceCode: Record "Source Code";
    begin
        SourceCodeDefCode := Code;
        SourceCode.Init;
        SourceCode.Code := Code;
        SourceCode.Description := Description;
        SourceCode.Insert;
    end;

    local procedure InsertStandardText("Code": Code[20]; Description: Text[50])
    var
        StandardText: Record "Standard Text";
    begin
        StandardText.Init;
        StandardText.Code := Code;
        StandardText.Description := Description;
        StandardText.Insert;
    end;

    local procedure PageName(PageID: Integer): Text[50]
    var
        ObjectTranslation: Record "Object Translation";
    begin
        exit(CopyStr(ObjectTranslation.TranslateObject(ObjectTranslation."Object Type"::Page, PageID), 1, 30));
    end;

    local procedure ReportName(ReportID: Integer): Text[50]
    var
        ObjectTranslation: Record "Object Translation";
    begin
        exit(CopyStr(ObjectTranslation.TranslateObject(ObjectTranslation."Object Type"::Report, ReportID), 1, 30));
    end;

    local procedure InsertClientAddIns()
    var
        ClientAddIn: Record "Add-in";
    begin
        InsertClientAddIn(
          'Microsoft.Dynamics.Nav.Client.DynamicsOnlineConnect', '31bf3856ad364e35', '',
          ClientAddIn.Category::"DotNet Control Add-in",
          'Microsoft Dynamics Online Connect control add-in', '');
        InsertClientAddIn(
          'Microsoft.Dynamics.Nav.Client.BusinessChart', '31bf3856ad364e35', '',
          ClientAddIn.Category::"JavaScript Control Add-in",
          'Microsoft Dynamics BusinessChart control add-in',
          ApplicationPath + 'Add-ins\BusinessChart\Microsoft.Dynamics.Nav.Client.BusinessChart.zip');
        InsertClientAddIn(
          'Microsoft.Dynamics.Nav.Client.TimelineVisualization', '31bf3856ad364e35', '',
          ClientAddIn.Category::"DotNet Control Add-in",
          'Interactive visualizion for a timeline of events', '');
        InsertClientAddIn(
          'Microsoft.Dynamics.Nav.Client.PingPong', '31bf3856ad364e35', '',
          ClientAddIn.Category::"DotNet Control Add-in",
          'Microsoft Dynamics PingPong control add-in', '');
        InsertClientAddIn(
          'Microsoft.Dynamics.Nav.Client.VideoPlayer', '31bf3856ad364e35', '',
          ClientAddIn.Category::"JavaScript Control Add-in",
          'Microsoft Dynamics VideoPlayer control add-in',
          ApplicationPath + 'Add-ins\VideoPlayer\Microsoft.Dynamics.Nav.Client.VideoPlayer.zip');
        InsertClientAddIn(
          'Microsoft.Dynamics.Nav.Client.PageReady', '31bf3856ad364e35', '',
          ClientAddIn.Category::"JavaScript Control Add-in",
          'Microsoft Dynamics PageReady control add-in',
          ApplicationPath + 'Add-ins\PageReady\Microsoft.Dynamics.Nav.Client.PageReady.zip');
        InsertClientAddIn(
          'Microsoft.Dynamics.Nav.Client.SocialListening', '31bf3856ad364e35', '',
          ClientAddIn.Category::"JavaScript Control Add-in",
          'Microsoft Social Listening control add-in',
          ApplicationPath + 'Add-ins\SocialListening\Microsoft.Dynamics.Nav.Client.SocialListening.zip');
        InsertClientAddIn(
          'Microsoft.Dynamics.Nav.Client.WebPageViewer', '31bf3856ad364e35', '',
          ClientAddIn.Category::"JavaScript Control Add-in",
          'Microsoft Web Page Viewer control add-in',
          ApplicationPath + 'Add-ins\WebPageViewer\Microsoft.Dynamics.Nav.Client.WebPageViewer.zip');
        InsertClientAddIn(
          'Microsoft.Dynamics.Nav.Client.OAuthIntegration', '31bf3856ad364e35', '',
          ClientAddIn.Category::"JavaScript Control Add-in",
          'Microsoft OAuth Integration control add-in',
          ApplicationPath + 'Add-ins\OAuthIntegration\Microsoft.Dynamics.Nav.Client.OAuthIntegration.zip');
        InsertClientAddIn(
          'Microsoft.Dynamics.Nav.Client.FlowIntegration', '31bf3856ad364e35', '',
          ClientAddIn.Category::"JavaScript Control Add-in",
          'Microsoft Flow Integration control add-in',
          ApplicationPath + 'Add-ins\FlowIntegration\Microsoft.Dynamics.Nav.Client.FlowIntegration.zip');
        InsertClientAddIn(
          'Microsoft.Dynamics.Nav.Client.RoleCenterSelector', '31bf3856ad364e35', '',
          ClientAddIn.Category::"JavaScript Control Add-in",
          'Microsoft Role Center Selector control add-in',
          ApplicationPath + 'Add-ins\RoleCenterSelector\Microsoft.Dynamics.Nav.Client.RoleCenterSelector.zip');
        InsertClientAddIn(
          'Microsoft.Dynamics.Nav.Client.WelcomeWizard', '31bf3856ad364e35', '',
          ClientAddIn.Category::"JavaScript Control Add-in",
          'Microsoft Welcome Wizard control add-in',
          ApplicationPath + 'Add-ins\WelcomeWizard\Microsoft.Dynamics.Nav.Client.WelcomeWizard.zip');
        InsertClientAddIn(
          'Microsoft.Dynamics.Nav.Client.PowerBIManagement', '31bf3856ad364e35', '',
          ClientAddIn.Category::"JavaScript Control Add-in",
          'Microsoft Power BI Management control add-in',
          ApplicationPath + 'Add-ins\PowerBIManagement\Microsoft.Dynamics.Nav.Client.PowerBIManagement.zip');
    end;

    local procedure InsertClientAddIn(ControlAddInName: Text[220]; PublicKeyToken: Text[20]; Version: Text[25]; Category: Option; Description: Text[250]; ResourceFilePath: Text[250])
    var
        ClientAddIn: Record "Add-in";
    begin
        if ClientAddIn.Get(ControlAddInName, PublicKeyToken, Version) then
            exit;

        ClientAddIn.Init;
        ClientAddIn."Add-in Name" := ControlAddInName;
        ClientAddIn."Public Key Token" := PublicKeyToken;
        ClientAddIn.Version := Version;
        ClientAddIn.Category := Category;
        ClientAddIn.Description := Description;
        if Exists(ResourceFilePath) then
            ClientAddIn.Resource.Import(ResourceFilePath);
        if ClientAddIn.Insert then;
    end;

    local procedure InsertJobWIPMethod("Code": Code[20]; Description: Text[50]; RecognizedCosts: Option; RecognizedSales: Option; SystemDefinedIndex: Integer)
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        JobWIPMethod.Init;
        JobWIPMethod.Code := Code;
        JobWIPMethod.Description := Description;
        JobWIPMethod."WIP Cost" := true;
        JobWIPMethod."WIP Sales" := true;
        JobWIPMethod."Recognized Costs" := RecognizedCosts;
        JobWIPMethod."Recognized Sales" := RecognizedSales;
        JobWIPMethod.Valid := true;
        JobWIPMethod."System Defined" := true;
        JobWIPMethod."System-Defined Index" := SystemDefinedIndex;
        JobWIPMethod.Insert;
    end;

    local procedure InsertBankExportImportSetup(CodeTxt: Text[20]; NameTxt: Text[100]; DirectionOpt: Option; CodeunitID: Integer; XMLPortID: Integer; CheckCodeunitID: Integer)
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        with BankExportImportSetup do begin
            Init;
            Code := CodeTxt;
            Name := NameTxt;
            Direction := DirectionOpt;
            "Processing Codeunit ID" := CodeunitID;
            "Processing XMLport ID" := XMLPortID;
            "Check Export Codeunit" := CheckCodeunitID;
            "Preserve Non-Latin Characters" := false;
            Insert;
        end;
    end;

    local procedure InitApplicationAreasForSaaS()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        Company: Record Company;
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        EnvironmentInfo: Codeunit "Environment Information";
        ExperienceTier: Text;
    begin
        ApplicationAreaMgmtFacade.SetHideApplicationAreaError(true);
        if not ApplicationAreaMgmtFacade.GetExperienceTierCurrentCompany(ExperienceTier) then
            if EnvironmentInfo.IsSaaS then begin
                Company.Get(CompanyName);

                if not (CompanyInformationMgt.IsDemoCompany or Company."Evaluation Company") then
                    ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential))
                else
                    ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Basic));
                exit;
            end;

        if ExperienceTier <> ExperienceTierSetup.FieldCaption(Custom) then
            ApplicationAreaMgmtFacade.RefreshExperienceTierCurrentCompany;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCompanyInitialize()
    begin
    end;

    [EventSubscriber(ObjectType::Table, 2000000006, 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterCompanyDeleteRemoveReferences(var Rec: Record Company; RunTrigger: Boolean)
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
        UserGroupMember: Record "User Group Member";
        UserGroupAccessControl: Record "User Group Access Control";
        ApplicationAreaSetup: Record "Application Area Setup";
        CustomReportLayout: Record "Custom Report Layout";
        ReportLayoutSelection: Record "Report Layout Selection";
        ExperienceTierSetup: Record "Experience Tier Setup";
    begin
        if Rec.IsTemporary then
            exit;

        AssistedCompanySetupStatus.SetRange("Company Name", Rec.Name);
        AssistedCompanySetupStatus.DeleteAll;
        UserGroupMember.SetRange("Company Name", Rec.Name);
        UserGroupMember.DeleteAll;
        UserGroupAccessControl.SetRange("Company Name", Rec.Name);
        UserGroupAccessControl.DeleteAll;
        ApplicationAreaSetup.SetRange("Company Name", Rec.Name);
        ApplicationAreaSetup.DeleteAll;
        CustomReportLayout.SetRange("Company Name", Rec.Name);
        CustomReportLayout.DeleteAll;
        ReportLayoutSelection.SetRange("Company Name", Rec.Name);
        ReportLayoutSelection.DeleteAll;

        if ExperienceTierSetup.Get(Rec.Name) then
            ExperienceTierSetup.Delete;
    end;
}

