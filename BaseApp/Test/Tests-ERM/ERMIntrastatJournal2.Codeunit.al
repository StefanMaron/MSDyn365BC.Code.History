#if not CLEAN22
codeunit 134166 "ERM Intrastat Journal 2"
{
    Subtype = Test;
    TestPermissions = Disabled;
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';
    ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';

    trigger OnRun()
    begin
        // [FEATURE] [Intrastat]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('IntrastatJnlTemplateListPageHandler,GetItemLedgerEntriesReportHandler')]
    [Scope('OnPrem')]
    procedure E2EErrorHandlingOfIntrastatJournalFiltertoErrors()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        SalesLine: Record "Sales Line";
        //        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntrastatJournalPage: TestPage "Intrastat Journal";
        InvoiceDate: Date;
    begin
        // [FEATURE] [Intrastat Journal] [Error handling]
        // [GIVEN] 2 Posted Sales Order for intrastat
        // [GIVEN] Journal Template and Batch
        Initialize();
        //      IntrastatJnlLine.DeleteAll();
        InvoiceDate := CalcDate('<-7Y>');
        CreateAndPostSalesOrder(SalesLine, InvoiceDate);
        CreateAndPostSalesOrder(SalesLine, InvoiceDate);
        LibraryERM.CreateIntrastatJnlTemplateAndBatch(IntrastatJnlBatch, InvoiceDate);
        Commit();

        // [GIVEN] A Intrastat Journal
        OpenIntrastatJournalAndGetEntries(IntrastatJournalPage, IntrastatJnlBatch."Journal Template Name");

        // [WHEN] Running Checklist + Filter to errors
        IntrastatJournalPage.ChecklistReport.Invoke();
        IntrastatJournalPage."Toggle Error Filter".Invoke();

        // [THEN] List should hold 2 line + 1 draft line
        Assert.IsTrue(IntrastatJournalPage.First(), 'Line 1');
        Assert.IsTrue(IntrastatJournalPage.Next(), 'Line 2');
        Assert.IsTrue(IntrastatJournalPage.Next(), 'Draft line');
        Assert.IsFalse(IntrastatJournalPage.Next(), 'No More lines');

        IntrastatJournalPage.Close();
    end;

    local procedure Initialize()
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IntrastatSetup: Record "Intrastat Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Intrastat Journal");
        LibraryVariableStorage.Clear();
        IntrastatSetup.DeleteAll();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Intrastat Journal");
        UpdateIntrastatCodeInCountryRegion();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERM.CreateIntrastatJnlTemplateAndBatch(IntrastatJnlBatch, WorkDate());
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Intrastat Journal");
    end;

    local procedure OpenIntrastatJournalAndGetEntries(var IntrastatJournalPage: TestPage "Intrastat Journal"; JournalTemplateName: Code[10])
    begin
        LibraryVariableStorage.Enqueue(JournalTemplateName);
        IntrastatJournalPage.OpenEdit();
        LibraryVariableStorage.Enqueue(false); // Do Not Show Item Charge entries
        IntrastatJournalPage.GetEntries.Invoke();
        IntrastatJournalPage.First();
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", GetCountryRegionCode());
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItemWithTariffNo(Item, LibraryUtility.CreateCodeRecord(DATABASE::"Tariff Number"));
        exit(Item."No.");
    end;

    local procedure CreateAndPostSalesOrder(var SalesLine: Record "Sales Line"; PostingDate: Date): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        exit(
          CreateAndPostSalesDocumentMultiLine(
            SalesLine, SalesHeader."Document Type"::Order, PostingDate, CreateItem(), 1));
    end;

    local procedure CreateAndPostSalesDocumentMultiLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; PostingDate: Date; ItemNo: Code[20]; NoOfSalesLines: Integer): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDocument(SalesLine, PostingDate, DocumentType, SalesLine.Type::Item, ItemNo, NoOfSalesLines);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Exercise.
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, false));
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; PostingDate: Date; DocumentType: Enum "Sales Document Type"; Type: Enum "Sales Line Type"; No: Code[20]; NoOfLines: Integer)
    var
        SalesHeader: Record "Sales Header";
        i: Integer;
    begin
        // Create Sales Order with Random Quantity and Unit Price.
        CreateSalesHeader(SalesHeader, CreateCustomer(), PostingDate, DocumentType);
        for i := 1 to NoOfLines do begin
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, LibraryRandom.RandDec(10, 2));
            SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
            SalesLine.Modify(true);
        end;
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; PostingDate: Date; DocumentType: Enum "Sales Document Type")
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
    end;

    local procedure GetCountryRegionCode(): Code[10]
    var
        CountryRegion: Record "Country/Region";
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CountryRegion.SetFilter(Code, '<>%1', CompanyInformation."Country/Region Code");
        CountryRegion.SetFilter("Intrastat Code", '<>''''');
        CountryRegion.FindFirst();
        exit(CountryRegion.Code);
    end;

    local procedure UpdateIntrastatCodeInCountryRegion()
    var
        CompanyInformation: Record "Company Information";
        CountryRegion: Record "Country/Region";
    begin
        CompanyInformation.Get();
        CompanyInformation."Bank Account No." := '';
        CompanyInformation.Modify();
        CountryRegion.Get(CompanyInformation."Country/Region Code");
        if CountryRegion."Intrastat Code" = '' then begin
            CountryRegion.Validate("Intrastat Code", CountryRegion.Code);
            CountryRegion.Modify(true);
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure IntrastatJnlTemplateListPageHandler(var IntrastatJnlTemplateList: TestPage "Intrastat Jnl. Template List")
    var
        NameVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(NameVar);
        IntrastatJnlTemplateList.FILTER.SetFilter(Name, NameVar);
        IntrastatJnlTemplateList.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GetItemLedgerEntriesReportHandler(var GetItemLedgerEntries: TestRequestPage "Get Item Ledger Entries")
    begin
        GetItemLedgerEntries.ShowingItemCharges.SetValue(LibraryVariableStorage.DequeueBoolean());
        GetItemLedgerEntries.OK().Invoke();
    end;
}
#endif