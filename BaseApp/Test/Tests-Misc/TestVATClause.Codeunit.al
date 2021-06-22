codeunit 134067 "Test VAT Clause"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [VAT Clause]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        VATClauseDoesNotExistErr: Label 'Unexpected XML Element VAT Clause. Expected result:XML Element VAT Clause doesn''t exist.';

    [Test]
    [HandlerFunctions('SalesInvoiceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure TestVatClauseTranslation()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Invoice Header";
        VATClause: Record "VAT Clause";
        VATPostingSetup: Record "VAT Posting Setup";
        VATClauseTranslation: Record "VAT Clause Translation";
    begin
        // acc. criteria 4 -When a VAT Clause is translated, then these translations will be used when a report in a particular language is printed
        Initialize;

        // set up
        CreateVATPostingSetupAndAssignVATClause(VATPostingSetup, VATClause);
        CreateVATClauseTranslation(VATClauseTranslation, VATClause);

        CreateSalesDoc(SalesHeader, VATPostingSetup, VATClauseTranslation."Language Code", SalesHeader."Document Type"::Invoice);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // exercise: Save-Invoice Report as XML
        Commit;
        REPORT.Run(REPORT::"Sales - Invoice", true, false, SalesInvHeader);

        // verify
        VerifySalesInvoiceVATClause(VATClauseTranslation."VAT Clause Code",
          VATClauseTranslation.Description, VATClauseTranslation."Description 2");
    end;

    [Test]
    [HandlerFunctions('SalesCrMemoRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure TestVatClauseSalesCreditMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        VATClause: Record "VAT Clause";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // acc. criteria 9 - When a Sales Cr. Memo report is generated, then the VAT Clauses are printed on the reports
        Initialize;

        // set up
        CreateVATPostingSetupAndAssignVATClause(VATPostingSetup, VATClause);

        CreateSalesDoc(SalesHeader, VATPostingSetup, '', SalesHeader."Document Type"::"Credit Memo"); // LanguageCode = ''
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // exercise: Save-Invoice Report as XML
        Commit;
        REPORT.Run(REPORT::"Sales - Credit Memo", true, false, SalesCrMemoHeader);

        // verify
        VerifySalesInvoiceVATClause(VATClause.Code, VATClause.Description, VATClause."Description 2");
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure TestVatClauseTranslationBlankValues()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Invoice Header";
        VATClause: Record "VAT Clause";
        VATClauseTranslation: Record "VAT Clause Translation";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // acc. criteria 4 - When a VAT Clause is translated, then these translations will be used when a report in a particular language is printed
        Initialize;

        // set up
        CreateVATPostingSetupAndAssignVATClause(VATPostingSetup, VATClause);

        CreateVATClauseTranslation(VATClauseTranslation, VATClause);
        UpdateVATClauseTranslation(VATClauseTranslation, '', '');

        CreateSalesDoc(SalesHeader, VATPostingSetup, VATClauseTranslation."Language Code", SalesHeader."Document Type"::Invoice);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // exercise: Save-Invoice Report as XML
        Commit;
        REPORT.Run(REPORT::"Sales - Invoice", true, false, SalesInvHeader);

        // verify
        VerifySalesInvoiceVATClause(VATClauseTranslation."VAT Clause Code", VATClause.Description, VATClause."Description 2");
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure TestUpdateVatClause()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Invoice Header";
        VATClause: Record "VAT Clause";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // acc. criteria 5 - When a VAT Clause is modified, then these modifications will be reflected in the report, when it's generated
        Initialize;

        // set up
        CreateVATPostingSetupAndAssignVATClause(VATPostingSetup, VATClause);

        UpdateVATClause(VATClause, '', '');

        CreateSalesDoc(SalesHeader, VATPostingSetup, '', SalesHeader."Document Type"::Invoice); // LanguageCode = ''
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        UpdateVATClause(VATClause, GenerateVATClauseDescription, GenerateVATClauseDescription);

        // exercise: Save-Invoice Report as XML
        Commit;
        REPORT.Run(REPORT::"Sales - Invoice", true, false, SalesInvHeader);

        // verify
        VerifySalesInvoiceVATClause(VATClause.Code, VATClause.Description, VATClause."Description 2");
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure TestDeletedVatClause()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Invoice Header";
        VATClause: Record "VAT Clause";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // acc. criteria 5 - When a VAT Clause is deleted, then report won't contain VAT Clause section
        Initialize;

        // set up
        CreateVATPostingSetupAndAssignVATClause(VATPostingSetup, VATClause);

        CreateSalesDoc(SalesHeader, VATPostingSetup, '', SalesHeader."Document Type"::Invoice); // LanguageCode = ''
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        VATClause.Delete(true);

        // exercise: Save-Invoice Report as XML
        Commit;
        REPORT.Run(REPORT::"Sales - Invoice", true, false, SalesInvHeader);

        // verify
        VerifySalesInvoiceVATClauseDoesNotExist(SalesInvHeader."No.");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure TestSalesLineVATClauseDefaultValue()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATClause: Record "VAT Clause";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // acc. criteria 6 - When a Sales Document is created, then the VAT Clause is defaulted to the correct value on the Sales Line.
        Initialize;

        // set up
        CreateVATPostingSetupAndAssignVATClause(VATPostingSetup, VATClause);

        // exercise
        CreateSalesDoc(SalesHeader, VATPostingSetup, '', SalesHeader."Document Type"::Invoice); // LanguageCode = ''

        // verify
        FindSalesLine(SalesLine, SalesHeader."No.");
        SalesLine.TestField("VAT Clause Code", VATClause.Code);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure TestSalesLineVATClauseVATProdPosGrChanged()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATClause1: Record "VAT Clause";
        VATClause2: Record "VAT Clause";
        VATPostingSetup1: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        VATProdPostingGroup: Record "VAT Product Posting Group";
    begin
        // acc. criteria 7 - When the VAT Prod. Posting Group is changed on a Sales Line, then the VAT Clause is updated correctly.
        Initialize;

        // set up
        CreateVATPostingSetupAndAssignVATClause(VATPostingSetup1, VATClause1);

        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup2, VATPostingSetup1."VAT Bus. Posting Group", VATProdPostingGroup.Code);
        VATPostingSetup2.Validate("VAT Identifier",
          CopyStr(LibraryERM.CreateRandomVATIdentifierAndGetCode, 1, MaxStrLen(VATPostingSetup2."VAT Identifier")));
        VATPostingSetup2.Modify(true);

        AssignVATClauseToVATPostingSetup(VATPostingSetup2, VATClause2);

        // exercise
        CreateSalesDoc(SalesHeader, VATPostingSetup1, '', SalesHeader."Document Type"::Invoice);
        FindSalesLine(SalesLine, SalesHeader."No.");
        SalesLine.Validate("VAT Prod. Posting Group", VATPostingSetup2."VAT Prod. Posting Group");
        SalesLine.Modify(true);

        // verify
        SalesLine.TestField("VAT Clause Code", VATClause2.Code);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure TestSalesLineVATClauseVATBusPosGrChanged()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATClause1: Record "VAT Clause";
        VATClause2: Record "VAT Clause";
        VATPostingSetup1: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        // acc. criteria 7 - When the VAT Bus. Posting group is changed on a Sales Line, then the VAT Clause is updated correctly.
        Initialize;

        // set up
        CreateVATPostingSetupAndAssignVATClause(VATPostingSetup1, VATClause1);

        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup2, VATBusinessPostingGroup.Code, VATPostingSetup1."VAT Prod. Posting Group");
        VATPostingSetup2.Validate("VAT Identifier",
          CopyStr(LibraryERM.CreateRandomVATIdentifierAndGetCode, 1, MaxStrLen(VATPostingSetup2."VAT Identifier")));
        VATPostingSetup2.Modify(true);
        AssignVATClauseToVATPostingSetup(VATPostingSetup2, VATClause2);

        // exercise
        CreateSalesDoc(SalesHeader, VATPostingSetup1, '', SalesHeader."Document Type"::Invoice);  // LanguageCode = ''
        FindSalesLine(SalesLine, SalesHeader."No.");
        SalesLine.Validate("VAT Bus. Posting Group", VATPostingSetup2."VAT Bus. Posting Group");
        SalesLine.Modify(true);

        // verify
        SalesLine.TestField("VAT Clause Code", VATClause2.Code);
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure TestNoVATNoSectionInReport()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Invoice Header";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // acc. criteria 10 - When no VAT Clause is defined for any line on the sales document, then the entire section is omitted when the report is printed.
        Initialize;

        // set up
        CreateVATPostingSetup(VATPostingSetup);
        CreateSalesDoc(SalesHeader, VATPostingSetup, '', SalesHeader."Document Type"::Invoice); // LanguageCode = ''
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // exercise: Save-Invoice Report as XML
        Commit;
        REPORT.Run(REPORT::"Sales - Invoice", true, false, SalesInvHeader);

        // verify
        VerifySalesInvoiceVATClauseDoesNotExist(SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure TestHistoryOfVATClause()
    var
        SalesHeader: Record "Sales Header";
        SalesInvHeader: Record "Sales Invoice Header";
        VATClause: Record "VAT Clause";
        VATClause2: Record "VAT Clause";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // acc. criteria 8 - When a Sales Document is posted, then the VAT Clause is carried through the posting routine to the respective Sales Invoice Line.
        // This means that if the VAT Clause is changed in the VAT Posting Setup, it is not changed

        Initialize;

        // set up
        CreateVATPostingSetupAndAssignVATClause(VATPostingSetup, VATClause);

        CreateSalesDoc(SalesHeader, VATPostingSetup, '', SalesHeader."Document Type"::Invoice); // LanguageCode = ''
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        CreateVATClause(VATClause2);
        AssignVATClauseToVATPostingSetup(VATPostingSetup, VATClause2);

        // exercise: Save-Invoice Report as XML
        Commit;
        REPORT.Run(REPORT::"Sales - Invoice", true, false, SalesInvHeader);

        // verify - the invoice is printed with the original VATClause.
        VerifySalesInvoiceVATClause(VATClause.Code, VATClause.Description, VATClause."Description 2");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATClauseCodeField()
    var
        SalesLine: Record "Sales Line";
        SalesLineArchive: Record "Sales Line Archive";
        ServiceLine: Record "Service Line";
        VATClause: Record "VAT Clause";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 259058] "VAT Clause Code" field has same FIELDNO in "Sales Line", "Service Line" and "Sales Line Archive", and all "VAT Clause Code" fields have length = length of field Code in "VAT Clause"
        Initialize;

        Assert.AreEqual(SalesLine.FieldNo("VAT Clause Code"), SalesLineArchive.FieldNo("VAT Clause Code"), '');
        Assert.AreEqual(SalesLine.FieldNo("VAT Clause Code"), ServiceLine.FieldNo("VAT Clause Code"), '');
        Assert.AreEqual(MaxStrLen(VATClause.Code), MaxStrLen(SalesLine."VAT Clause Code"), '');
        Assert.AreEqual(MaxStrLen(VATClause.Code), MaxStrLen(SalesLineArchive."VAT Clause Code"), '');
        Assert.AreEqual(MaxStrLen(VATClause.Code), MaxStrLen(ServiceLine."VAT Clause Code"), '');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test VAT Clause");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Test VAT Clause");
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        LibrarySales.SetInvoiceRounding(false);
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Test VAT Clause");
    end;

    local procedure AssignVATClauseToVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; var VATClause: Record "VAT Clause")
    begin
        CreateVATClause(VATClause);
        VATPostingSetup.Validate("VAT Clause Code", VATClause.Code);
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateSalesDoc(var SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup"; LanguageCode: Code[10]; DocumentType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType,
          CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group", LanguageCode));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item,
          CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandInt(10));
    end;

    local procedure CreateCustomerWithVATBusPostingGroup(VATBusPostingGroupCode: Code[20]; LanguageCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
        Customer.Validate("Language Code", LanguageCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateVATClause(var VATClause: Record "VAT Clause")
    begin
        VATClause.Init;
        VATClause.Validate(Code, CopyStr(LibraryUtility.GenerateRandomCode(VATClause.FieldNo(Code), DATABASE::"VAT Clause"),
            1, LibraryUtility.GetFieldLength(DATABASE::"VAT Clause", VATClause.FieldNo(Code))));
        VATClause.Validate(Description, GenerateVATClauseDescription);
        VATClause.Validate("Description 2", GenerateVATClauseDescription);
        VATClause.Insert(true);
    end;

    local procedure CreateVATClauseTranslation(var VATClauseTranslation: Record "VAT Clause Translation"; VATClause: Record "VAT Clause")
    begin
        VATClauseTranslation.Init;
        VATClauseTranslation.Validate("VAT Clause Code", VATClause.Code);
        VATClauseTranslation.Validate("Language Code", GetRandomLanguageCode);
        VATClauseTranslation.Validate(Description, GenerateVATClauseDescription);
        VATClauseTranslation.Validate("Description 2", GenerateVATClauseDescription);
        VATClauseTranslation.Insert(true);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusPostingGroup: Record "VAT Business Posting Group";
        VATProdPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup.Code, VATProdPostingGroup.Code);
    end;

    local procedure CreateVATPostingSetupAndAssignVATClause(var VATPostingSetup: Record "VAT Posting Setup"; var VATClause: Record "VAT Clause")
    begin
        CreateVATPostingSetup(VATPostingSetup);
        AssignVATClauseToVATPostingSetup(VATPostingSetup, VATClause);
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; SalesHeaderNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", SalesHeaderNo);
        SalesLine.FindFirst;
    end;

    local procedure GenerateVATClauseDescription(): Text[250]
    var
        VATClause: Record "VAT Clause";
    begin
        exit(CopyStr(LibraryUtility.GenerateRandomCode(VATClause.FieldNo(Description), DATABASE::"VAT Clause"),
            1, LibraryUtility.GetFieldLength(DATABASE::"VAT Clause", VATClause.FieldNo(Description))));
    end;

    local procedure CreateItemWithVATProdPostingGroup(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
        exit(Item."No.")
    end;

    local procedure GetRandomLanguageCode(): Code[10]
    var
        Language: Record Language;
        "count": Integer;
        randomNum: Integer;
    begin
        Language.Init;
        randomNum := LibraryRandom.RandIntInRange(1, Language.Count);
        repeat
            count += 1;
            Language.Next;
        until count < randomNum;
        exit(Language.Code);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceRequestPageHandler(var SalesInvoiceRequestPage: TestRequestPage "Sales - Invoice")
    begin
        SalesInvoiceRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesCrMemoRequestPageHandler(var SalesCrMemoRequestPage: TestRequestPage "Sales - Credit Memo")
    begin
        SalesCrMemoRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    local procedure UpdateVATClause(var VATClause: Record "VAT Clause"; Description: Text; Description2: Text)
    begin
        VATClause.Validate(Description, CopyStr(Description, 1, MaxStrLen(VATClause.Description)));
        VATClause.Validate("Description 2", CopyStr(Description2, 1, MaxStrLen(VATClause."Description 2")));
        VATClause.Modify(true);
    end;

    local procedure UpdateVATClauseTranslation(VATClauseTranslation: Record "VAT Clause Translation"; Description: Text; Description2: Text)
    begin
        VATClauseTranslation.Validate(Description, CopyStr(Description, 1, MaxStrLen(VATClauseTranslation.Description)));
        VATClauseTranslation.Validate("Description 2", CopyStr(Description2, 1, MaxStrLen(VATClauseTranslation."Description 2")));
        VATClauseTranslation.Modify(true);
    end;

    local procedure VerifySalesInvoiceVATClause(VATClauseCode: Code[20]; VATDescription: Code[250]; VATDescription2: Code[250])
    begin
        LibraryReportDataset.LoadDataSetFile;

        if LibraryReportDataset.GetNextRow then begin
            LibraryReportDataset.AssertElementWithValueExists('VATClauseCode', VATClauseCode);
            LibraryReportDataset.AssertElementWithValueExists('VATClauseDescription', VATDescription);
            LibraryReportDataset.AssertElementWithValueExists('VATClauseDescription2', VATDescription2);
        end
    end;

    local procedure VerifySalesInvoiceVATClauseDoesNotExist(SalesInvHdrNo: Code[20])
    begin
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.SetRange('No_SalesInvHdr', SalesInvHdrNo);

        while LibraryReportDataset.GetNextRow do
            Assert.IsFalse(LibraryReportDataset.CurrentRowHasElement('VATClauseCode') or
              LibraryReportDataset.CurrentRowHasElement('VATClauseDescription') or
              LibraryReportDataset.CurrentRowHasElement('VATClauseDescription2'), VATClauseDoesNotExistErr);
    end;
}

