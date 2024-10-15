codeunit 148095 "Swiss QR-Bill Test IncomingDoc"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Swiss QR-Bill]
    end;

    var
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        Library: Codeunit "Swiss QR-Bill Test Library";
        ReferenceType: Enum "Swiss QR-Bill Payment Reference Type";
        BlankedImportErr: Label 'There is no data to import.';
        ImportCompletedWithWarningsTxt: Label 'QR-Bill import has been successfully completed with warnings.';
        ImportFailedWithErrorsTxt: Label 'QR-Bill import has been completed, but data parsing has been failed. See error section for more details.';
        ImportCompletedTxt: Label 'QR-Bill import has been successfully completed.';

    [Test]
    [Scope('OnPrem')]
    procedure PageListActions()
    var
        IncomingDocumentsPage: TestPage "Incoming Documents";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 259169] Page "Incoming Documents" actions visibility
        with IncomingDocumentsPage do begin
            OpenEdit();
            Assert.IsTrue("Swiss QR-Bill Scan".Visible(), '');
            Assert.IsTrue("Swiss QR-Bill Scan".Enabled(), '');
            Assert.IsTrue("Swiss QR-Bill Import".Visible(), '');
            Assert.IsTrue("Swiss QR-Bill Import".Enabled(), '');
            Close();
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PageCardActions_QRBill()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentPage: TestPage "Incoming Document";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 259169] Page "Incoming Document" actions visibility, QR-Bill record
        MockIncomingDoc(IncomingDocument, true);

        with IncomingDocumentPage do begin
            Trap();
            Page.Run(Page::"Incoming Document", IncomingDocument);
            Assert.IsTrue("Swiss QR-Bill Scan".Visible(), '');
            Assert.IsTrue("Swiss QR-Bill Scan".Enabled(), '');
            Assert.IsTrue("Swiss QR-Bill Import".Visible(), '');
            Assert.IsTrue("Swiss QR-Bill Import".Enabled(), '');

            Assert.IsTrue("Swiss QR-Bill Create Journal".Visible(), '');
            Assert.IsTrue("Swiss QR-Bill Create Journal".Enabled(), '');
            Assert.IsTrue("Swiss QR-Bill Create Purchase Invoice".Visible(), '');
            Assert.IsTrue("Swiss QR-Bill Create Purchase Invoice".Enabled(), '');
            Close();
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PageCardActions_NotQRBill()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentPage: TestPage "Incoming Document";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 259169] Page "Incoming Document" actions visibility, not a QR-Bill record
        MockIncomingDoc(IncomingDocument, false);

        with IncomingDocumentPage do begin
            Trap();
            Page.Run(Page::"Incoming Document", IncomingDocument);
            Assert.IsTrue("Swiss QR-Bill Scan".Visible(), '');
            Assert.IsTrue("Swiss QR-Bill Import".Visible(), '');
            Assert.IsTrue("Swiss QR-Bill Scan".Enabled(), '');
            Assert.IsTrue("Swiss QR-Bill Import".Enabled(), '');

            Assert.IsFalse("Swiss QR-Bill Create Journal".Visible(), '');
            Assert.IsFalse("Swiss QR-Bill Create Journal".Enabled(), '');
            Assert.IsFalse("Swiss QR-Bill Create Purchase Invoice".Visible(), '');
            Assert.IsFalse("Swiss QR-Bill Create Purchase Invoice".Enabled(), '');
            Close();
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PageCardFields_QRBill()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentPage: TestPage "Incoming Document";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 259169] Page "Incoming Document" fields visibility, QR-Bill record
        MockIncomingDoc(IncomingDocument, true);

        with IncomingDocumentPage do begin
            Trap();
            Page.Run(Page::"Incoming Document", IncomingDocument);
            // general group
            Assert.IsTrue("Swiss QR-Bill Description".Visible(), '');
            Assert.IsTrue("Swiss QR-Bill Description".Editable(), '');
            Assert.IsFalse(Description.Visible(), '');
            Assert.IsTrue("Swiss QR-Bill Status".Visible(), '');
            Assert.IsFalse(StatusField.Visible(), '');

            // status group
            Assert.IsTrue("Swiss QR-Bill Posted".Visible(), '');
            Assert.IsFalse("Swiss QR-Bill Posted".Editable(), '');
            Assert.IsFalse(Posted.Visible(), '');

            // payment details group
            Assert.IsTrue("Swiss QR-Bill Amount Incl VAT".Visible(), '');
            Assert.IsFalse("Swiss QR-Bill Amount Incl VAT".Editable(), '');
            Assert.IsFalse("Amount Incl. VAT".Visible(), '');
            Assert.IsTrue("Swiss QR-Bill Billing Info".Visible(), '');
            Assert.IsFalse("Swiss QR-Bill Billing Info".Editable(), '');

            // creditor details group
            Assert.IsTrue("Swiss QR-Bill Vendor IBAN".Visible(), '');
            Assert.IsFalse("Swiss QR-Bill Vendor IBAN".Editable(), '');
            Assert.IsTrue("Swiss QR-Bill Creditor Name".Visible(), '');
            Assert.IsFalse("Swiss QR-Bill Creditor Name".Editable(), '');
            Assert.IsFalse("Vendor IBAN".Visible(), '');
            Assert.IsFalse("Vendor Name".Visible(), '');

            // debitor details group
            Assert.IsTrue("Swiss QR-Bill Debitor Name".Visible(), '');
            Assert.IsFalse("Swiss QR-Bill Debitor Name".Editable(), '');

            // matching details group
            Assert.IsTrue("Swiss QR-Bill Vendor No.".Visible(), '');
            Assert.IsTrue("Swiss QR-Bill Vendor No.".Editable(), '');
            Assert.IsTrue("Swiss QR-Bill Vendor Bank Account No.".Visible(), '');
            Assert.IsTrue("Swiss QR-Bill Vendor Bank Account No.".Editable(), '');
            Assert.IsTrue("Swiss QR-Bill Vendor IBAN Match".Visible(), '');
            Assert.IsFalse("Swiss QR-Bill Vendor IBAN Match".Editable(), '');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PageCardFields_NotQRBill()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentPage: TestPage "Incoming Document";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 259169] Page "Incoming Document" fields visibility, not a QR-Bill record
        MockIncomingDoc(IncomingDocument, false);

        with IncomingDocumentPage do begin
            Trap();
            Page.Run(Page::"Incoming Document", IncomingDocument);
            // general group
            Assert.IsTrue(Description.Visible(), '');
            Assert.IsTrue(Description.Editable(), '');
            Assert.IsFalse("Swiss QR-Bill Description".Visible(), '');
            Assert.IsTrue(StatusField.Visible(), '');
            Assert.IsFalse("Swiss QR-Bill Status".Visible(), '');

            // status group
            Assert.IsTrue(Posted.Visible(), '');
            Assert.IsFalse(Posted.Editable(), '');
            Assert.IsFalse("Swiss QR-Bill Posted".Visible(), '');

            // payment details group
            Assert.IsTrue("Amount Incl. VAT".Visible(), '');
            Assert.IsFalse("Amount Incl. VAT".Editable(), '');
            Assert.IsFalse("Swiss QR-Bill Amount Incl VAT".Visible(), '');
            Assert.IsFalse("Swiss QR-Bill Billing Info".Visible(), '');

            // creditor details group
            Assert.IsTrue("Vendor IBAN".Visible(), '');
            Assert.IsFalse("Vendor IBAN".Editable(), '');
            Assert.IsTrue("Vendor Name".Visible(), '');
            Assert.IsFalse("Vendor Name".Editable(), '');
            Assert.IsFalse("Swiss QR-Bill Vendor IBAN".Visible(), '');
            Assert.IsFalse("Swiss QR-Bill Creditor Name".Visible(), '');

            // debitor details group
            Assert.IsFalse("Swiss QR-Bill Debitor Name".Visible(), '');

            // matching details group
            Assert.IsFalse("Swiss QR-Bill Vendor No.".Visible(), '');
            Assert.IsFalse("Swiss QR-Bill Vendor Bank Account No.".Visible(), '');
            Assert.IsFalse("Swiss QR-Bill Vendor IBAN Match".Visible(), '');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('QRBillScanMPH')]
    procedure ScanFromPageList_Blanked()
    var
        QRCodeText: Text;
    begin
        // [FEATURE] [UI] [Scan]
        // [SCENARIO 259169] Page "Incoming Documents"."Scan QR-Bill" action in case of a blanked input
        Initialize();
        QRCodeText := '';

        LibraryVariableStorage.Enqueue(QRCodeText);
        asserterror InvokeScanFromPageList();

        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(BlankedImportErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('QRBillScanMPH,MessageHandler')]
    procedure ScanFromPageList_Failed()
    var
        QRCodeText: Text;
    begin
        // [FEATURE] [UI] [Scan]
        // [SCENARIO 259169] Page "Incoming Documents"."Scan QR-Bill" action in case of a wrong input
        Initialize();
        QRCodeText := 'wrong';

        PerformScanFromPageList(QRCodeText, false);

        Assert.ExpectedMessage(ImportFailedWithErrorsTxt, LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('QRBillScanMPH,MessageHandler')]
    procedure ScanFromPageList_IBANNotMatch()
    var
        IncomingDocument: Record "Incoming Document";
        QRCodeText: Text;
        BillInfo: Text;
        PaymentReference: Code[50];
        IBAN: Code[50];
    begin
        // [FEATURE] [UI] [Scan]
        // [SCENARIO 259169] Page "Incoming Documents"."Scan QR-Bill" action in case of not matched IBAN, QR-Reference, billing info
        Initialize();
        BillInfo := 'S1/10/DOCNO123/30/VATNO123';
        IBAN := Library.GetRandomIBAN();
        PaymentReference := Library.GetRandomQRPaymentReference();
        QRCodeText :=
            'SPC\0200\1\' + IBAN + '\S\CR Name\CR A1\CR A2\CR POST\CR CITY\C1\\\\\\\\123.45\CHF\' +
            'S\UD Name\UD A1\UD A2\UD POST\UD CITY\C3\QRR\' + PaymentReference + '\Unstr Msg\EPD\' + BillInfo;

        PerformScanFromPageList(QRCodeText, false);

        with IncomingDocument do begin
            FindLast();
            TestField("Swiss QR-Bill", true);
            TestField(Description, 'QR-Bill');
            TestField("Vendor Name", 'CR Name');
            TestField("Vendor IBAN", Library.FormatIBAN(IBAN));
            TestField("Vendor Invoice No.", 'DOCNO123');
            TestField("Vendor VAT Registration No.", 'VATNO123');
            TestField("Vendor No.", '');
            TestField("Vendor Bank Account No.", '');

            TestField("Swiss QR-Bill Vendor Address 1", 'CR A1');
            TestField("Swiss QR-Bill Vendor Address 2", 'CR A2');
            TestField("Swiss QR-Bill Vendor Post Code", 'CR POST');
            TestField("Swiss QR-Bill Vendor City", 'CR CITY');
            TestField("Swiss QR-Bill Vendor Country", 'C1');

            TestField("Swiss QR-Bill Debitor Name", 'UD Name');
            TestField("Swiss QR-Bill Debitor Address1", 'UD A1');
            TestField("Swiss QR-Bill Debitor Address2", 'UD A2');
            TestField("Swiss QR-Bill Debitor PostCode", 'UD POST');
            TestField("Swiss QR-Bill Debitor City", 'UD CITY');
            TestField("Swiss QR-Bill Debitor Country", 'C3');

            TestField("Amount Incl. VAT", 123.45);
            TestField("Currency Code", 'CHF');
            TestField("Swiss QR-Bill Reference Type", ReferenceType::"QR Reference");
            TestField("Swiss QR-Bill Reference No.", Library.FormatPaymentReference(ReferenceType::"QR Reference", PaymentReference));
            TestField("Swiss QR-Bill Unstr. Message", 'Unstr Msg');
            TestField("Swiss QR-Bill Bill Info", BillInfo);
        end;

        Assert.ExpectedMessage(ImportCompletedWithWarningsTxt, LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('QRBillScanMPH,MessageHandler')]
    procedure ScanFromPageList_IBANMatch()
    var
        IncomingDocument: Record "Incoming Document";
        VendorNo: Code[20];
        VendorBankAccountNo: Code[20];
        QRCodeText: Text;
        IBAN: Code[50];
    begin
        // [FEATURE] [UI] [Scan]
        // [SCENARIO 259169] Page "Incoming Documents"."Scan QR-Bill" action in case of matched IBAN
        Initialize();
        IBAN := Library.GetRandomIBAN();
        CreateVendorWithBankAccount(VendorNo, VendorBankAccountNo, IBAN);
        QRCodeText :=
            'SPC\0200\1\' + IBAN + '\S\CR Name\\\\\\\\\\\\\\CHF\\\\\\\\NON\\\EPD';

        PerformScanFromPageList(QRCodeText, true);

        with IncomingDocument do begin
            FindLast();
            TestField("Vendor No.", VendorNo);
            TestField("Vendor Bank Account No.", VendorBankAccountNo);
        end;

        Assert.ExpectedMessage(ImportCompletedWithWarningsTxt, LibraryVariableStorage.DequeueText());

        LibraryVariableStorage.AssertEmpty();
        ClearVendor(VendorNo);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('QRBillScanMPH,MessageHandler')]
    procedure ScanFromPageList_FullMatch()
    var
        IncomingDocument: Record "Incoming Document";
        CompanyInfo: Record "Company Information";
        Vendor: Record Vendor;
        VendorBankAccountNo: Code[20];
        QRCodeText: Text;
        IBAN: Code[50];
    begin
        // [FEATURE] [UI] [Scan]
        // [SCENARIO 259169] Page "Incoming Documents"."Scan QR-Bill" action in case of full match
        Initialize();
        CompanyInfo.Get();
        IBAN := Library.GetFixedIBAN();
        CreateVendorWithBankAccount(Vendor."No.", VendorBankAccountNo, IBAN);
        Vendor.Find();
        QRCodeText :=
            'SPC\0200\1\' + IBAN + '\S\' + Vendor.Name + '\\\\\\\\\\\\\\CHF\S\' + CompanyInfo.Name + '\' +
            CompanyInfo.Address + '\' + CompanyInfo."Address 2" + '\' + CompanyInfo."Post Code" + '\' +
            CompanyInfo.City + '\' + CompanyInfo."Country/Region Code" + '\NON\\\EPD';

        PerformScanFromPageList(QRCodeText, true);

        with IncomingDocument do begin
            FindLast();
            TestField("Vendor No.", Vendor."No.");
            TestField("Vendor Bank Account No.", VendorBankAccountNo);
        end;

        Assert.ExpectedMessage(ImportCompletedTxt, LibraryVariableStorage.DequeueText());

        LibraryVariableStorage.AssertEmpty();
        ClearVendor(Vendor."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('QRBillScanMPH,MessageHandler')]
    procedure ScanFromPageList_IBANMatch_CreateJournal()
    var
        JournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
        VendorBankAccountNo: Code[20];
        QRCodeText: Text;
        PaymentReference: Code[50];
        IBAN: Code[50];
        BillInfo: Text;
        PmtAmount: Decimal;
    begin
        // [FEATURE] [UI] [Scan]
        // [SCENARIO 259169] Create Journal action in case of matched IBAN, QR-Reference, billing info
        Initialize();
        BillInfo := 'S1/10/DOCNO123/30/VATNO123';
        IBAN := Library.GetRandomIBAN();
        PmtAmount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        PaymentReference := Library.GetRandomQRPaymentReference();
        CreateVendorWithBankAccount(VendorNo, VendorBankAccountNo, IBAN);
        QRCodeText :=
            'SPC\0200\1\' + IBAN + '\S\CR Name\\\\\\\\\\\\\' + Library.FormatAmount(PmtAmount) +
            '\CHF\\\\\\\\QRR\' + PaymentReference + '\Unstr Msg\EPD\' + BillInfo;

        PerformScanFromPageListAndCreateJournal(QRCodeText);

        FindLatestPurchaseJournalRecord(JournalLine);
        with JournalLine do begin
            TestField("Document Type", "Document Type"::Invoice);
            TestField("Account Type", "Account Type"::Vendor);
            TestField("Account No.", VendorNo);
            TestField("Recipient Bank Account", VendorBankAccountNo);
            TestField("Currency Code", '');
            TestField(Amount, -PmtAmount);
            TestField("External Document No.", 'DOCNO123');
            TestField("Payment Reference", PaymentReference);
            TestField(Description, 'QR-Bill');
            TestField("Message to Recipient", 'Unstr Msg');
            TestField("Transaction Information", BillInfo);
        end;
        Assert.ExpectedMessage(ImportCompletedWithWarningsTxt, LibraryVariableStorage.DequeueText());

        LibraryVariableStorage.AssertEmpty();
        ClearVendor(VendorNo);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('QRBillScanMPH,MessageHandler')]
    procedure ScanFromPageList_IBANMatch_CreateInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
        VendorBankAccountNo: Code[20];
        QRCodeText: Text;
        PaymentReference: Code[50];
        IBAN: Code[50];
        BillInfo: Text;
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [UI] [Scan]
        // [SCENARIO 259169] Create Purchase Invoice action in case of matched IBAN, QR-Reference, billing info
        Initialize();
        BillInfo := 'S1/10/DOCNO123/30/VATNO123';
        IBAN := Library.GetRandomIBAN();
        PaymentReference := Library.GetRandomQRPaymentReference();
        CreateVendorWithBankAccount(VendorNo, VendorBankAccountNo, IBAN);
        QRCodeText :=
            'SPC\0200\1\' + IBAN + '\S\CR Name\\\\\\\\\\\\\123.45\CHF\\\\\\\\QRR\' + PaymentReference + '\Unstr Msg\EPD\' + BillInfo;

        InvoiceNo := PerformScanFromPageListAndCreatePurchInv(QRCodeText);
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Invoice, InvoiceNo);

        with PurchaseHeader do begin
            TestField("Buy-from Vendor No.", VendorNo);
            TestField("Currency Code", '');
            TestField("Vendor Invoice No.", 'DOCNO123');
            TestField("Payment Reference", PaymentReference);
            TestField("Posting Description", 'Unstr Msg');
        end;
        Assert.ExpectedMessage(ImportCompletedWithWarningsTxt, LibraryVariableStorage.DequeueText());

        LibraryVariableStorage.AssertEmpty();
        ClearVendor(VendorNo);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        ClearJournalRecords();
    end;

    local procedure PerformScanFromPageList(QRCodeText: Text; ExpectedIBANMatch: Boolean)
    var
        IncomingDocumentPage: TestPage "Incoming Document";
    begin
        QRCodeText := Library.ReplaceBackSlashWithLineBreak(QRCodeText);
        LibraryVariableStorage.Enqueue(QRCodeText);
        IncomingDocumentPage.Trap();
        InvokeScanFromPageList();
        IncomingDocumentPage."Swiss QR-Bill Vendor IBAN Match".AssertEquals(ExpectedIBANMatch);
        IncomingDocumentPage.Close();
    end;

    local procedure PerformScanFromPageListAndCreateJournal(QRCodeText: Text)
    var
        IncomingDocumentPage: TestPage "Incoming Document";
        PurchaseJournalPage: TestPage "Purchase Journal";
    begin
        QRCodeText := Library.ReplaceBackSlashWithLineBreak(QRCodeText);
        LibraryVariableStorage.Enqueue(QRCodeText);
        IncomingDocumentPage.Trap();
        InvokeScanFromPageList();
        PurchaseJournalPage.Trap();
        IncomingDocumentPage."Swiss QR-Bill Create Journal".Invoke();
        PurchaseJournalPage.Close();
        IncomingDocumentPage.Close();
    end;

    local procedure PerformScanFromPageListAndCreatePurchInv(QRCodeText: Text) InvoiceNo: Code[20]
    var
        IncomingDocumentPage: TestPage "Incoming Document";
        PurchaseInvoicePage: TestPage "Purchase Invoice";
    begin
        QRCodeText := Library.ReplaceBackSlashWithLineBreak(QRCodeText);
        LibraryVariableStorage.Enqueue(QRCodeText);
        IncomingDocumentPage.Trap();
        InvokeScanFromPageList();
        PurchaseInvoicePage.Trap();
        IncomingDocumentPage."Swiss QR-Bill Create Purchase Invoice".Invoke();
        InvoiceNo := CopyStr(PurchaseInvoicePage."No.".Value(), 1, 20);
        PurchaseInvoicePage.Close();
        IncomingDocumentPage.Close();
    end;

    local procedure InvokeScanFromPageList()
    var
        IncomingDocumentsPage: TestPage "Incoming Documents";
    begin
        with IncomingDocumentsPage do begin
            OpenEdit();
            "Swiss QR-Bill Scan".Invoke();
            Close();
        end;
    end;

    local procedure InvokeScanFromPageCard(var IncomingDocument: Record "Incoming Document")
    var
        IncomingDocumentPage: TestPage "Incoming Document";
    begin
        with IncomingDocumentPage do begin
            Trap();
            Page.Run(Page::"Incoming Document", IncomingDocument);
            "Swiss QR-Bill Scan".Invoke();
            Close();
        end;
    end;

    local procedure FindLatestPurchaseJournalRecord(var JournalLine: Record "Gen. Journal Line")
    var
        QRBillSetup: Record "Swiss QR-Bill Setup";
    begin
        QRBillSetup.Get();
        with JournalLine do begin
            SetRange("Journal Template Name", QRBillSetup."Journal Template");
            SetRange("Journal Batch Name", QRBillSetup."Journal Batch");
            FindLast();
        end;
    end;

    local procedure ClearJournalRecords()
    var
        JournalLine: Record "Gen. Journal Line";
        QRBillSetup: Record "Swiss QR-Bill Setup";
    begin
        QRBillSetup.Get();
        with JournalLine do begin
            SetRange("Journal Template Name", QRBillSetup."Journal Template");
            SetRange("Journal Batch Name", QRBillSetup."Journal Batch");
            DeleteAll();
        end;
    end;

    local procedure ClearVendor(VendorNo: Code[20])
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        VendorBankAccount.SetRange("Vendor No.", VendorNo);
        VendorBankAccount.DeleteAll();
        if Vendor.Get(VendorNo) then
            Vendor.Delete();
    end;

    local procedure CreateVendorWithBankAccount(var VendorNo: Code[20]; var VendorBankaccountNo: Code[20]; IBAN: Code[50])
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        VendorNo := LibraryPurchase.CreateVendorNo();
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, VendorNo);
        VendorBankAccount.IBAN := IBAN;
        VendorBankAccount.Modify();
        VendorBankaccountNo := VendorBankAccount.Code;
    end;

    local procedure MockIncomingDoc(var IncomingDocument: Record "Incoming Document"; QRBill: Boolean)
    begin
        with IncomingDocument do begin
            "Entry No." := LibraryUtility.GetNewRecNo(IncomingDocument, FieldNo("Entry No."));
            "Swiss QR-Bill" := QRBill;
            Insert();
        end;
    end;

    [ModalPageHandler]
    procedure QRBillScanMPH(var QRBillScanPage: TestPage "Swiss QR-Bill Scan")
    begin
        QRBillScanPage.QRCodeTextField.SetValue(LibraryVariableStorage.DequeueText());
        QRBillScanPage.OK().Invoke();
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;
}
