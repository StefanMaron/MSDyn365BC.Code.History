codeunit 144005 "EHF Reminder"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [EHF] [Reminder]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        EInvoiceReminderHelper: Codeunit "E-Invoice Reminder Helper";
        EInvoiceFinChMemoHelper: Codeunit "E-Invoice Fin. Ch. Memo Helper";
        isInitialized: Boolean;
        CustomizationIDTxt: Label 'urn:cen.eu:en16931:2017#compliant#urn:fdc:peppol.eu:2017:poacc:billing:3.0#conformant#urn:fdc:anskaffelser.no:2019:ehf:reminder:3.0', Comment = 'Locked';
        ProfileIDTxt: Label 'urn:fdc:anskaffelser.no:2019:ehf:postaward:g3:06:1.0', Comment = 'Locked';

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnIssuedReminderWithYourReferenceBlankAndEInvoiceYes()
    var
        ReminderHeader: Record "Reminder Header";
        IssuedReminderHeader: Record "Issued Reminder Header";
    begin
        // [SCENARIO 361936] Issue reminder when Your Reference is not filled in and E-Invoice is set to Yes
        Initialize;

        // [GIVEN] Reminder with "Your Reference" := '' and E-Invoice = Yes
        EInvoiceReminderHelper.CreateReminderDoc(ReminderHeader);
        UpdateReminderEInvoiceFields(ReminderHeader, '', true);

        // [WHEN] Issue the reminder
        IssuedReminderHeader.Get(EInvoiceReminderHelper.IssueReminder(ReminderHeader."No."));

        // [THEN] The Issued Reminder has Your Reference = blank
        IssuedReminderHeader.TestField("Your Reference", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnIssuedFinChargeMemoWithYourReferenceBlankAndEInvoiceYes()
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
    begin
        // [SCENARIO 361936] Issue finance charge memo when Your Reference is not filled in and E-Invoice is set to Yes
        Initialize;

        // [GIVEN] Finance Charge Memo with "Your Reference" := '' and E-Invoice = Yes
        EInvoiceFinChMemoHelper.CreateFinChMemoDoc(FinanceChargeMemoHeader);
        UpdateFinChargeMemoEInvoiceFields(FinanceChargeMemoHeader, '', true);

        // [WHEN] Issue the finance charge memo
        IssuedFinChargeMemoHeader.Get(EInvoiceFinChMemoHelper.IssueFinanceChargeMemo(FinanceChargeMemoHeader."No."));

        // [THEN] The Issued Fin. Charge Memo has Your Reference = blank
        IssuedFinChargeMemoHeader.TestField("Your Reference", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoErrorOnIssuedReminderWithYourReferenceBlankAndEInvoiceNo()
    var
        ReminderHeader: Record "Reminder Header";
        IssuedReminderHeader: Record "Issued Reminder Header";
    begin
        // [SCENARIO 336613] Issued reminder is created when Your Reference is not filled in and E-Invoice is set to No
        Initialize;

        // [GIVEN] Reminder with "Your Reference" := '' and E-Invoice = No
        EInvoiceReminderHelper.CreateReminderDoc(ReminderHeader);
        UpdateReminderEInvoiceFields(ReminderHeader, '', false);

        // [WHEN] Issue the reminder
        IssuedReminderHeader.Get(EInvoiceReminderHelper.IssueReminder(ReminderHeader."No."));

        // [THEN] 'Your Reference' is blank in Issued Reminder
        IssuedReminderHeader.TestField("Your Reference", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoErrorOnIssuedFinChargeMemoWithYourReferenceBlankAndEInvoiceNo()
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
    begin
        // [SCENARIO 336613] Issued finance charge memo is created when Your Reference is not filled in and E-Invoice is set to No
        Initialize;

        // [GIVEN] Finance Charge Memo with "Your Reference" := '' and E-Invoice = No
        EInvoiceFinChMemoHelper.CreateFinChMemoDoc(FinanceChargeMemoHeader);
        UpdateFinChargeMemoEInvoiceFields(FinanceChargeMemoHeader, '', false);

        // [WHEN] Issue the finance charge memo
        IssuedFinChargeMemoHeader.Get(EInvoiceFinChMemoHelper.IssueFinanceChargeMemo(FinanceChargeMemoHeader."No."));

        // [THEN] 'Your Reference' is blank in Issued Finance Charge Memo
        IssuedFinChargeMemoHeader.TestField("Your Reference", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportIssuedReminderGeneralInfo()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        IssuedReminderLine: Record "Issued Reminder Line";
        ExportEHFReminder: Codeunit "Export EHF Reminder";
        FileName: Text;
        i: Integer;
    begin
        // [SCENARIO 336613] Electronic document for issued reminder general information
        Initialize;

        // [GIVEN] KID Setup is set to "Document Type+Document No." in Sales Setup
        UpdateSalesSetupKID();

        // [GIVEN] Issued Reminder
        IssuedReminderHeader.Get(EInvoiceReminderHelper.CreateReminder);

        // [WHEN] Export Issued Reminder
        FileName := ExportEHFReminder.GenerateXMLFile(IssuedReminderHeader);

        IssuedReminderHeader.CalcFields("Interest Amount", "Additional Fee", "VAT Amount");

        // [THEN] 'CustomizationID' and 'ProfileID' exported according to EFH 3.0 version
        // [THEN] 'ID' tag contains number of the reminder
        // [THEN] 'BuyerReference' tag contains 'Your Reference' value
        InitXMLData(FileName);
        VerifyXMLGeneralInfo(IssuedReminderHeader, IssuedReminderHeader."Your Reference");
        VerifyXmlTotalAmounts(
          IssuedReminderHeader."Interest Amount" + IssuedReminderHeader."Additional Fee",
          IssuedReminderHeader."VAT Amount", LibraryERM.GetCurrencyCode(IssuedReminderHeader."Currency Code"));
        // [THEN] 'InvoiceLine' is exported with 'InvoicedQuantity' and 'LineExtensionAmount' = 0, 'PriceAmount' is taked from line amount
        IssuedReminderLine.SetRange("Reminder No.", IssuedReminderHeader."No.");
        IssuedReminderLine.FindSet();
        repeat
            VerifyXmlLine(IssuedReminderLine, i);
            i += 1;
        until IssuedReminderLine.Next = 0;
        // [THEN] 'PaymentID' is exported with Giro KID value of the reminder (TFS 362900)
        LibraryXPathXMLReader.VerifyNodeValue('//cbc:PaymentID', GetGiroKID(3, IssuedReminderHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportIssuedFinChargeMemoGeneralInfo()
    var
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        IssuedReminderHeader: Record "Issued Reminder Header";
        IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line";
        IssuedReminderLine: Record "Issued Reminder Line";
        ExportEHFReminder: Codeunit "Export EHF Reminder";
        FileName: Text;
        i: Integer;
    begin
        // [SCENARIO 336613] Electronic document for issued finance charge memo general information
        Initialize;

        // [GIVEN] KID Setup is set to "Document Type+Document No." in Sales Setup
        UpdateSalesSetupKID();

        // [GIVEN] Issued Finance Charge Memo
        IssuedFinChargeMemoHeader.Get(EInvoiceFinChMemoHelper.CreateFinChMemo);

        // [WHEN] Export Issued Reminder
        FileName := ExportEHFReminder.GenerateXMLFile(IssuedFinChargeMemoHeader);

        IssuedFinChargeMemoHeader.CalcFields("Interest Amount", "Additional Fee", "VAT Amount");
        // [THEN] 'CustomizationID' and 'ProfileID' exported according to EFH 3.0 version
        // [THEN] 'ID' tag contains number of the finance charge memo
        // [THEN] 'BuyerReference' tag contains 'Your Reference' value
        IssuedReminderHeader.TransferFields(IssuedFinChargeMemoHeader);
        InitXMLData(FileName);
        VerifyXMLGeneralInfo(IssuedReminderHeader, IssuedFinChargeMemoHeader."Your Reference");
        VerifyXmlTotalAmounts(
          IssuedFinChargeMemoHeader."Interest Amount" + IssuedFinChargeMemoHeader."Additional Fee",
          IssuedFinChargeMemoHeader."VAT Amount", LibraryERM.GetCurrencyCode(IssuedFinChargeMemoHeader."Currency Code"));
        // [THEN] 'InvoiceLine' is exported with 'InvoicedQuantity' and 'LineExtensionAmount' = 0, 'PriceAmount' is taked from line amount
        IssuedFinChargeMemoLine.SetRange("Finance Charge Memo No.", IssuedFinChargeMemoHeader."No.");
        IssuedFinChargeMemoLine.FindSet();
        repeat
            IssuedReminderLine.TransferFields(IssuedFinChargeMemoLine);
            VerifyXmlLine(IssuedReminderLine, i);
            i += 1;
        until IssuedFinChargeMemoLine.Next = 0;
        // [THEN] 'PaymentID' is exported with Giro KID value of the finance charge memo (TFS 362900)
        LibraryXPathXMLReader.VerifyNodeValue('//cbc:PaymentID', GetGiroKID(2, IssuedFinChargeMemoHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportIssuedReminderGeneralInfoYourReferenceBlank()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        ExportEHFReminder: Codeunit "Export EHF Reminder";
        FileName: Text;
    begin
        // [SCENARIO 361936] Electronic document for issued reminder with blank Your Reference
        Initialize;

        // [GIVEN] Issued Reminder with blank 'Your Reference'
        IssuedReminderHeader.Get(EInvoiceReminderHelper.CreateReminder);
        IssuedReminderHeader."Your Reference" := '';
        IssuedReminderHeader.Modify;

        // [WHEN] Export Issued Reminder
        FileName := ExportEHFReminder.GenerateXMLFile(IssuedReminderHeader);

        // [THEN] 'BuyerReference' tag contains 'Your Reference' with number of the Issued Reminder
        InitXMLData(FileName);
        VerifyXMLGeneralInfo(IssuedReminderHeader, IssuedReminderHeader."No.");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        LibraryERMCountryData.CreateGeneralPostingSetupData;
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        isInitialized := true;
    end;

    local procedure InitXMLData(FileName: Text)
    begin
        LibraryXPathXMLReader.Initialize(FileName, '');
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('cbc', 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2');
        LibraryXPathXMLReader.AddAdditionalNamespace('cac', 'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2');
    end;

    local procedure GetGiroKID(DocumentType: Integer; DocumentNo: Code[20]): Code[30]
    var
        DocumentTools: Codeunit DocumentTools;
        GiroAmountKr: Text[20];
        GiroAmountkre: Text[2];
        CheckDigit: Text[1];
        GiroKID: Text[25];
        KIDError: Boolean;
    begin
        DocumentTools.SetupGiro(
          true, DocumentType, DocumentNo, '', 0, '',
          GiroAmountKr, GiroAmountkre, CheckDigit, GiroKID, KIDError);
        exit(GiroKID);
    end;

    local procedure UpdateSalesSetupKID()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("KID Setup", SalesReceivablesSetup."KID Setup"::"Document Type+Document No.");
        SalesReceivablesSetup.Validate("Use KID on Fin. Charge Memo", true);
        SalesReceivablesSetup.Validate("Use KID on Reminder", true);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateReminderEInvoiceFields(var ReminderHeader: Record "Reminder Header"; YourReference: Text[35]; Einvoice: Boolean)
    begin
        ReminderHeader."Your Reference" := YourReference;
        ReminderHeader."E-Invoice" := Einvoice;
        ReminderHeader.Modify;
    end;

    local procedure UpdateFinChargeMemoEInvoiceFields(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; YourReference: Text[35]; Einvoice: Boolean)
    begin
        FinanceChargeMemoHeader."Your Reference" := YourReference;
        FinanceChargeMemoHeader."E-Invoice" := Einvoice;
        FinanceChargeMemoHeader.Modify;
    end;

    local procedure VerifyXMLGeneralInfo(IssuedReminderHeader: Record "Issued Reminder Header"; YourReference: Text[35])
    begin
        LibraryXPathXMLReader.VerifyNodeValue('//cbc:CustomizationID', CustomizationIDTxt);
        LibraryXPathXMLReader.VerifyNodeValue('//cbc:ProfileID', ProfileIDTxt);
        LibraryXPathXMLReader.VerifyNodeValue('//cbc:ID', IssuedReminderHeader."No.");
        LibraryXPathXMLReader.VerifyNodeValue('//cbc:BuyerReference', YourReference);
    end;

    local procedure VerifyXmlTotalAmounts(ChargeAmount: Decimal; TaxAmount: Decimal; CurrencyCode: Code[10])
    begin
        // AllowanceCharge
        LibraryXPathXMLReader.VerifyNodeValue('//cac:AllowanceCharge/cbc:ChargeIndicator', 'true');
        LibraryXPathXMLReader.VerifyNodeValue('//cac:AllowanceCharge/cbc:AllowanceChargeReason', 'REM');
        LibraryXPathXMLReader.VerifyNodeValue('//cac:AllowanceCharge/cbc:Amount', Format(ChargeAmount, 0, 9));
        LibraryXPathXMLReader.VerifyAttributeValue('cac:AllowanceCharge/cbc:Amount', 'currencyID', CurrencyCode);

        // TaxTotal
        LibraryXPathXMLReader.VerifyNodeValue('//cac:TaxTotal/cbc:TaxAmount', Format(TaxAmount, 0, 9));

        // LegalMonetaryTotal
        LibraryXPathXMLReader.VerifyNodeValue('//cac:LegalMonetaryTotal/cbc:LineExtensionAmount', '0');
        LibraryXPathXMLReader.VerifyNodeValue('//cac:LegalMonetaryTotal/cbc:TaxExclusiveAmount', Format(ChargeAmount, 0, 9));
        LibraryXPathXMLReader.VerifyNodeValue('//cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount', Format(ChargeAmount + TaxAmount, 0, 9));
        LibraryXPathXMLReader.VerifyNodeValue('//cac:LegalMonetaryTotal/cbc:AllowanceTotalAmount', '0');
        LibraryXPathXMLReader.VerifyNodeValue('//cac:LegalMonetaryTotal/cbc:ChargeTotalAmount', Format(ChargeAmount, 0, 9));
        LibraryXPathXMLReader.VerifyNodeValue('//cac:LegalMonetaryTotal/cbc:PayableAmount', Format(ChargeAmount + TaxAmount, 0, 9));
    end;

    local procedure VerifyXmlLine(IssuedReminderLine: Record "Issued Reminder Line"; Index: Integer)
    begin
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex('//cac:InvoiceLine/cbc:ID', Format(IssuedReminderLine."Line No."), Index);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex('//cac:InvoiceLine/cbc:InvoicedQuantity', '0', Index);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex('//cac:InvoiceLine/cbc:LineExtensionAmount', '0', Index);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(
          '//cac:InvoiceLine/cac:Item/cbc:Name', IssuedReminderLine.Description, Index);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(
          '//cac:InvoiceLine/cac:Price/cbc:PriceAmount', Format(IssuedReminderLine.Amount, 0, 9), Index);
    end;
}

