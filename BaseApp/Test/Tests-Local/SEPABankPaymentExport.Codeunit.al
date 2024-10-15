codeunit 144026 "SEPA Bank Payment Export"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        CountryRegion: Record "Country/Region";
        TempBlobGlobal: Codeunit "Temp Blob";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        IsInitialized: Boolean;
        FullPathErr: Label 'File full path ''%1'' exceeds length (%3) of field ''%2'' ', Comment = '.';
        SEPAXmlDocNamespaceTxt: Label 'urn:iso:std:iso:20022:tech:xsd:pain.001.001.02', Locked = true;

    [Test]
    [HandlerFunctions('RPHSuggestBankPayments,MessageHandler')]
    [Scope('OnPrem')]
    procedure SEPAV2PaymentCanBeExported()
    var
        PurchaseHeader: Record "Purchase Header";
        RefPaymentExported: Record "Ref. Payment - Exported";
        RefFileSetup: Record "Reference File Setup";
        BankAccountNo: Code[20];
        VendorNo: Code[20];
    begin
        // Initialize
        Initialize();
        BankAccountNo := CreateBankAccount(CountryRegion.Code, 'FI9780RBOS16173241116737', 'SEPACT V02', '');
        CreateBankAccountReferenceFileSetup(RefFileSetup, BankAccountNo);
        VendorNo := CreateVendor(CountryRegion.Code, 'FI9780RBOS16173241116737', true, 1);

        CreateReferancePaymentExportLines(BankAccountNo, VendorNo, PurchaseHeader);

        // Excercise
        RefPaymentExported.SetRange(Transferred, false);
        RefPaymentExported.SetRange("Applied Payments", false);
        RefPaymentExported.SetRange("SEPA Payment", true);
        RefPaymentExported.FindFirst();
        RefPaymentExported.ExportToFile();

        // Verify
        // No erros occur!
    end;

    [Test]
    [HandlerFunctions('RPHSuggestBankPayments')]
    procedure ProcessSEPAPaymentsWorksOnWebclient()
    var
        PurchaseHeader: Record "Purchase Header";
        RefPaymentExported: Record "Ref. Payment - Exported";
        ReferenceFileSetup: Record "Reference File Setup";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        SEPABankPaymentExport: Codeunit "SEPA Bank Payment Export";
        TempBlob: Codeunit "Temp Blob";
        BlobInStream: InStream;
        XmlFirstByte: Byte;
        BOMFirstByte: Byte;
        BankAccountNo: Code[20];
        VendorNo: Code[20];
        ValidIBANCode: Code[50];
    begin
        // [SCENARIO 278682] Process SEPA payments action works on webclient
        // [SCENARIO 494956] Exported XML file does not contain UTF-8 BOM characters.
        Initialize();

        // [GIVEN] Client type was webclient
        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        // [GIVEN] Full setup was available for SEPA Payment report to run
        ValidIBANCode := 'FI9780RBOS16173241116737';
        BankAccountNo := CreateBankAccount(CountryRegion.Code, ValidIBANCode, 'SEPACT V02', '');
        CreateBankAccountReferenceFileSetup(ReferenceFileSetup, BankAccountNo);
        VendorNo := CreateVendor(CountryRegion.Code, ValidIBANCode, true, 1);
        CreateReferancePaymentExportLines(BankAccountNo, VendorNo, PurchaseHeader);

        // [WHEN] Run Process SEPA payments report
        BindSubscription(SEPABankPaymentExport);
        RefPaymentExported.FindFirst();
        RefPaymentExported.ExportToFile();
        // RequestPage handled by RPHSuggestBankPayments handler

        // [THEN] The report runs with no errors
        SEPABankPaymentExport.GetBlobWithXmlDocContent(TempBlob);
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, SEPAXmlDocNamespaceTxt);
        LibraryXPathXMLReader.VerifyNodeValueByXPath('/Document/pain.001.001.02/PmtInf/DbtrAcct/Id/IBAN', ValidIBANCode);

        // [THEN] The exported XML file does not contain UTF-8 BOM characters.
        BOMFirstByte := 239;    // 0xEF
        TempBlob.CreateInStream(BlobInStream);
        BlobInStream.Read(XmlFirstByte, 1);
        Assert.AreNotEqual(BOMFirstByte, XmlFirstByte, 'The exported XML file contains UTF-8 BOM characters.');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SEPA Bank Payment Export");
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SEPA Bank Payment Export");

        IsInitialized := true;

        CountryRegion.Get('FI');
        InitCompanyInformation(CountryRegion.Code);
        SetupNoSeries(true, false, false, '', '');
        InitGeneralLedgerSetup('EUR');
        InitCountryRegion(CountryRegion.Code, true);
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SEPA Bank Payment Export");
    end;

    local procedure InitCompanyInformation(CountryCode: Code[10])
    var
        CompanyInformation: Record "Company Information";
    begin
        with CompanyInformation do begin
            Get();
            "Country/Region Code" := CountryCode;
            Modify();
        end;
    end;

    local procedure InitGeneralLedgerSetup(LCYCode: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        with GeneralLedgerSetup do begin
            Get();
            "LCY Code" := LCYCode;
            Modify();
        end;
    end;

    local procedure InitCountryRegion(CountryCode: Code[10]; SepaAllowed: Boolean)
    var
        CountryRegion: Record "Country/Region";
    begin
        with CountryRegion do begin
            Get(CountryCode);
            "SEPA Allowed" := SepaAllowed;
            Modify();
        end;
    end;

    local procedure SetupNoSeries(Default: Boolean; Manual: Boolean; DateOrder: Boolean; StartingNo: Code[20]; EndingNo: Code[20])
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, Default, Manual, DateOrder);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, StartingNo, EndingNo);

        with PurchasesPayablesSetup do begin
            Get();
            "Bank Batch Nos." := NoSeries.Code;
            Modify();
        end;
    end;

    local procedure CreateBankAccount(CountryCode: Code[10]; IBANCode: Code[50]; PmtExpFormat: Code[20]; SEPACTNoSeries: Code[20]): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        with BankAccount do begin
            Init();
            "No." := LibraryUtility.GenerateRandomCode(FieldNo("No."), DATABASE::"Bank Account");
            Name := LibraryUtility.GenerateRandomCode(FieldNo(Name), DATABASE::"Bank Account");
            "SWIFT Code" := LibraryUtility.GenerateRandomCode(FieldNo("SWIFT Code"), DATABASE::"Bank Account");
            "Country/Region Code" := CountryCode;
            Validate("Post Code", FindPostCode(CountryCode));
            "Bank Branch No." := LibraryUtility.GenerateRandomCode(FieldNo("Bank Branch No."), DATABASE::"Bank Account");
            "Bank Account No." := CreateGLAccount();
            "Bank Acc. Posting Group" := CreateBankAccountPostingGroup();
            "Transit No." := LibraryUtility.GenerateRandomCode(FieldNo("Transit No."), DATABASE::"Bank Account");
            Validate(IBAN, IBANCode);
            "Payment Export Format" := PmtExpFormat;
            "Credit Transfer Msg. Nos." := SEPACTNoSeries;
            Insert();
            exit("No.");
        end
    end;

    local procedure FindPostCode(CountryCode: Code[10]): Code[20]
    var
        PostCode: Record "Post Code";
    begin
        with PostCode do begin
            SetRange("Country/Region Code", CountryCode);
            FindFirst();
            exit(Code);
        end;
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure CreateBankAccountPostingGroup(): Code[20]
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
    begin
        with BankAccountPostingGroup do begin
            Init();
            Code := LibraryUtility.GenerateRandomCode(FieldNo(Code), DATABASE::"Bank Account Posting Group");
            "G/L Account No." := CreateGLAccount();
            Insert();
            exit(Code);
        end;
    end;

    local procedure CreateBankAccountReferenceFileSetup(var ReferenceFileSetup: Record "Reference File Setup"; BankAccountNo: Code[20])
    var
        FieldLength: Integer;
    begin
        with ReferenceFileSetup do begin
            Init();
            "No." := BankAccountNo;
            Validate("Bank Party ID", LibraryUtility.GenerateRandomCode(FieldNo("Bank Party ID"), DATABASE::"Reference File Setup"));
            "File Name" :=
              CopyStr(GenerateFileName(FieldNo("File Name"), DATABASE::"Reference File Setup", 'xml', FieldLength), 1, FieldLength);
            Insert();
        end;
    end;

    local procedure GenerateFileName(FieldNo: Integer; TableNo: Integer; Extension: Text; var FieldLength: Integer): Text
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        FullPath: Text;
    begin
        RecRef.Open(TableNo);
        FieldRef := RecRef.Field(FieldNo);
        FieldLength := FieldRef.Length;
        FullPath := TemporaryPath + LibraryUtility.GenerateRandomCode(FieldNo, TableNo) + '.' + Extension;

        Assert.IsTrue(
          FieldLength >= StrLen(FullPath),
          StrSubstNo(FullPathErr, FullPath, FieldRef.Caption, FieldLength));

        exit(FullPath);
    end;

    local procedure CreateVendor(CountryCode: Code[10]; IBANCode: Code[50]; SEPAPayment: Boolean; VendorPriority: Integer): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        with Vendor do begin
            "Country/Region Code" := CountryCode;
            Validate("Post Code", FindPostCode(CountryCode));
            "Business Identity Code" :=
              LibraryUtility.GenerateRandomCode(FieldNo("Business Identity Code"), DATABASE::Vendor);
            "Our Account No." := CreateGLAccount();
            Priority := VendorPriority;
            "Preferred Bank Account Code" := CreateVendorBankAccount("No.", CountryCode, IBANCode, SEPAPayment);
            Modify(true);
            exit("No.");
        end;
    end;

    local procedure CreateVendorBankAccount(VendorNo: Code[20]; CountryCode: Code[10]; IBANCode: Code[50]; SEPAPayment: Boolean): Code[10]
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        with VendorBankAccount do begin
            Init();
            "Vendor No." := VendorNo;
            Code := LibraryUtility.GenerateRandomCode(FieldNo(Code), DATABASE::"Vendor Bank Account");
            Name := LibraryUtility.GenerateRandomCode(FieldNo(Name), DATABASE::"Vendor Bank Account");
            "SWIFT Code" := LibraryUtility.GenerateRandomCode(FieldNo("SWIFT Code"), DATABASE::"Vendor Bank Account");
            "Country/Region Code" := CountryCode;
            "Post Code" := FindPostCode(CountryCode);
            "Bank Branch No." := LibraryUtility.GenerateRandomCode(FieldNo("Bank Branch No."), DATABASE::"Vendor Bank Account");
            "Bank Account No." := CreateGLAccount();
            "Transit No." := LibraryUtility.GenerateRandomCode(FieldNo("Transit No."), DATABASE::"Vendor Bank Account");
            IBAN := IBANCode;
            "SEPA Payment" := SEPAPayment;
            "Clearing Code" := LibraryUtility.GenerateRandomCode(FieldNo("Clearing Code"), DATABASE::"Vendor Bank Account");
            Insert();
            exit(Code);
        end;
    end;

    local procedure CreateReferancePaymentExportLines(BankAccountNo: Code[20]; VendorNo: Code[20]; var PurchaseHeader: Record "Purchase Header"): Code[20]
    var
        RefPaymentExported: Record "Ref. Payment - Exported";
        SuggestBankPayments: Report "Suggest Bank Payments";
        DocNo: Code[20];
    begin
        LibraryVariableStorage.Enqueue(BankAccountNo);
        LibraryVariableStorage.Enqueue(VendorNo);
        DocNo :=
          CreateAndPostPurchaseDocumentWithRandomAmounts(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo, false, true);
        RefPaymentExported.DeleteAll();
        Commit();
        SuggestBankPayments.InitializeRequest(CalcDate('<30D>', PurchaseHeader."Posting Date"), false, 0);
        SuggestBankPayments.RunModal();

        exit(DocNo);
    end;

    local procedure CreateAndPostPurchaseDocumentWithRandomAmounts(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; ToShipReceive: Boolean; ToInvoice: Boolean) DocumentNo: Code[20]
    var
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        Precision: Integer;
        InvoiceMessage: Text[250];
        InvoiceMessage2: Text[250];
    begin
        Precision := LibraryRandom.RandIntInRange(2, 5);
        with PurchaseHeader do begin
            InvoiceMessage :=
              LibraryUtility.GenerateRandomCode(FieldNo("Invoice Message"), DATABASE::"Purchase Header");
            InvoiceMessage2 :=
              LibraryUtility.GenerateRandomCode(FieldNo("Invoice Message 2"), DATABASE::"Purchase Header");
            LibraryInventory.CreateItem(Item);

            DocumentNo :=
              CreateAndPostPurchaseDocument(
                PurchaseHeader, DocumentType, VendorNo,
                PurchaseLine.Type::Item, Item."No.",
                LibraryRandom.RandDec(1000, Precision), LibraryRandom.RandDec(1000, Precision),
                ToShipReceive, ToInvoice,
                InvoiceMessage, InvoiceMessage2);
        end;

        exit(DocumentNo);
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; LineType: Enum "Purchase Line Type"; No: Code[20]; Quantity: Decimal; Cost: Decimal; ToShipReceive: Boolean; ToInvoice: Boolean; InvoiceMessage: Text[250]; InvoiceMessage2: Text[250]): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        with PurchaseHeader do begin
            Validate("Invoice Message", InvoiceMessage);
            Validate("Invoice Message 2", InvoiceMessage2);
            Modify(true);
        end;
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, LineType, No, Quantity);
        with PurchaseLine do begin
            Validate("Direct Unit Cost", Cost);
            Modify(true);
        end;
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, ToShipReceive, ToInvoice));
    end;

    procedure GetBlobWithXmlDocContent(var TempBlob: Codeunit "Temp Blob")
    begin
        TempBlob := TempBlobGlobal;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RPHSuggestBankPayments(var RequestPage: TestRequestPage "Suggest Bank Payments")
    var
        Vendor: Record Vendor;
        BankAccountNo: Variant;
        VendorNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccountNo);
        LibraryVariableStorage.Dequeue(VendorNo);
        Vendor.Get(VendorNo);

        RequestPage."Payment Account".SetValue(BankAccountNo);
        RequestPage.Vendor.SetFilter("No.", VendorNo);
        RequestPage.Vendor.SetFilter("Payment Method Code", Vendor."Payment Method Code");
        RequestPage.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Dummy message handler.
    end;

    [EventSubscriber(ObjectType::Report, Report::"Export SEPA Payment File", 'OnBeforeDownloadFromBlob', '', false, false)]
    local procedure CancelDownloadOnBeforeDownloadFromBlob(var TempBlob: Codeunit "Temp Blob"; var CancelDownload: Boolean)
    begin
        CancelDownload := true;
        TempBlobGlobal := TempBlob;
    end;
}

