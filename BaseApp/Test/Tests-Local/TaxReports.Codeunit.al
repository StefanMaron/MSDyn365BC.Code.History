codeunit 144210 "Tax Reports"
{
    Subtype = Test;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryTax: Codeunit "Library - Tax";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        isInitialized: Boolean;

    local procedure Initialize()
    begin
        LibraryRandom.SetSeed(1);  // Use Random Number Generator to generate the seed for RANDOM function.
        LibraryVariableStorage.Clear;

        if isInitialized then
            exit;

        isInitialized := true;
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,RequestPageDocumentationForVATHandler,RequestPageCreateVATPeriodHandler')]
    [Scope('OnPrem')]
    procedure PrintingDocumentationForVATOutVATDate()
    begin
        PrintingDocumentationForVAT(true);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,RequestPageDocumentationForVATHandler,RequestPageCreateVATPeriodHandler')]
    [Scope('OnPrem')]
    procedure PrintingDocumentationForVATInVATDate()
    begin
        PrintingDocumentationForVAT(false);
    end;

    local procedure PrintingDocumentationForVAT(OutVATDate: Boolean)
    var
        PurchHdr: Record "Purchase Header";
        PurchLn: Record "Purchase Line";
        PostedDocumentNo: Code[20];
    begin
        // 1. Setup
        Initialize;

        LibraryTax.SetUseVATDate(true);
        DeleteVATPeriod;
        RunCreateVATPeriod;

        CreatePurchInvoice(PurchHdr, PurchLn);
        PurchHdr.Validate("VAT Date", CalcDate('<+1M>', PurchHdr."Posting Date"));
        PurchHdr.Validate("Original Document VAT Date", PurchHdr."VAT Date");
        PurchHdr.Modify();

        PostedDocumentNo := PostPurchaseDocument(PurchHdr);

        // 2. Exercise
        if OutVATDate then
            LibraryVariableStorage.Enqueue(CalcDate('<-CM>', PurchHdr."Posting Date"))
        else
            LibraryVariableStorage.Enqueue(CalcDate('<-CM>', PurchHdr."VAT Date"));
        LibraryVariableStorage.Enqueue(0);
        LibraryVariableStorage.Enqueue(true);
        LibraryTax.PrintDocumentationForVAT(true);

        // 3. Verify
        LibraryReportDataset.LoadDataSetFile;
        if OutVATDate then
            LibraryReportDataset.AssertElementWithValueNotExist('DocumentNo_VATEntry', PostedDocumentNo)
        else
            LibraryReportDataset.AssertElementWithValueExists('DocumentNo_VATEntry', PostedDocumentNo);
    end;

    local procedure CreatePurchDocument(var PurchHdr: Record "Purchase Header"; var PurchLn: Record "Purchase Line"; DocumentType: Option; Amount: Decimal)
    var
        Vend: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vend);
        LibraryPurchase.CreatePurchHeader(PurchHdr, DocumentType, Vend."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchLn, PurchHdr, PurchLn.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup, 1);
        PurchLn.Validate("Direct Unit Cost", Amount);
        PurchLn.Modify(true);
    end;

    local procedure CreatePurchInvoice(var PurchHdr: Record "Purchase Header"; var PurchLn: Record "Purchase Line")
    begin
        CreatePurchDocument(PurchHdr, PurchLn, PurchHdr."Document Type"::Invoice, LibraryRandom.RandDec(10000, 2));
    end;

    local procedure DeleteVATPeriod()
    var
        VATPeriod: Record "VAT Period";
    begin
        VATPeriod.DeleteAll();
    end;

    local procedure PostPurchaseDocument(var PurchHdr: Record "Purchase Header"): Code[20]
    begin
        exit(LibraryPurchase.PostPurchaseDocument(PurchHdr, true, true));
    end;

    local procedure RunCreateVATPeriod()
    begin
        LibraryVariableStorage.Enqueue(CalcDate('<-CY>', WorkDate));
        LibraryVariableStorage.Enqueue(12);
        LibraryVariableStorage.Enqueue('1M');
        LibraryTax.RunCreateVATPeriod;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageCreateVATPeriodHandler(var CreateVATPeriod: TestRequestPage "Create VAT Period")
    var
        FieldValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(FieldValue);
        CreateVATPeriod.VATPeriodStartDate.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        CreateVATPeriod.NoOfPeriods.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        CreateVATPeriod.PeriodLength.SetValue(Format(FieldValue));
        CreateVATPeriod.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageDocumentationForVATHandler(var DocumentationforVAT: TestRequestPage "Documentation for VAT")
    var
        FieldValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(FieldValue);
        DocumentationforVAT.StartDateReq.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        DocumentationforVAT.Selection.SetValue(FieldValue);
        LibraryVariableStorage.Dequeue(FieldValue);
        DocumentationforVAT.PrintVATEntries.SetValue(FieldValue);
        DocumentationforVAT.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure YesConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

