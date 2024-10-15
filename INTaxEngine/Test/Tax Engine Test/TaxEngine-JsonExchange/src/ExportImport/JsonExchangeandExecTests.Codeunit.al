codeunit 137700 "Json Exchange and Exec. Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [TaxEngine] [Json Exchange and Exec. Tests] [UT]
    end;

    var
        Assert: Codeunit Assert;
        TaxConfigTestHelper: Codeunit "Tax Config. Test Helper";
        EmptyGuid: Guid;
        JsonText: text;

    [Test]
    [HandlerFunctions('UseCaseMsgHandler')]
    procedure TestImportTaxTypes()
    var
        TaxType: Record "Tax Type";
        TaxUseCase: Record "Tax Use Case";
        JsonDessrialization: Codeunit "Tax Json Deserialization";
        JArray: JsonArray;
        JText: Text;
    begin
        // [SCENARIO] To check if Tax Types and use cases are getting imported.

        // [GIVEN] There has to be a json file for importing
        TaxType.SetHideDialog(true);
        TaxType.SetRange(Code, 'VAT');
        if TaxType.FindFirst() then
            TaxType.Delete(true);

        JText := TaxConfigTestHelper.GetJsonInText();
        JArray.ReadFrom(JText); // validating if json is valid

        // [WHEN] function ImportTaxTypes is called 
        JsonDessrialization.SetCanImportUseCases(true);
        JsonDessrialization.ImportTaxTypes(JText);

        // [THEN] It should create a record in Tax Type and Use cases.
        TaxType.SetRange(Code, 'VAT');
        Assert.RecordIsNotEmpty(TaxType);

        TaxUseCase.SetRange("Tax Type", 'VAT');
        TaxUseCase.FindFirst();
        Assert.RecordIsNotEmpty(TaxUseCase);
    end;

    [Test]
    [HandlerFunctions('UseCaseMsgHandler')]
    procedure TestExportTaxTypes()
    var
        TaxType: Record "Tax Type";
        TaxUseCase: Record "Tax Use Case";
        JsonDessrialization: Codeunit "Tax Json Deserialization";
        JsonSerialization: Codeunit "Tax Json Serialization";
        UseCaseMgmt: Codeunit "Use Case Mgmt.";
        JArray: JsonArray;
        JText: Text;
    begin
        // [SCENARIO] To check if Tax Types are getting exported.

        // [GIVEN] There has to be a tax type with code as VAT
        TaxType.SetHideDialog(true);
        TaxType.SetRange(Code, 'VAT');
        if TaxType.FindFirst() then begin
            TaxUseCase.SetRange("Tax Type", 'VAT');
            UseCaseMgmt.DisableSelectedUseCases(TaxUseCase);
            TaxType.Delete(true);
        end;

        JText := TaxConfigTestHelper.GetJsonInText();
        JArray.ReadFrom(JText); // validating if json is valid
        JsonDessrialization.SetCanImportUseCases(true);
        JsonDessrialization.ImportTaxTypes(JText);

        // [WHEN] function ImportTaxTypes is called 
        JsonSerialization.ExportTaxTypes(TaxType, JArray);
        JArray.WriteTo(JText);
        // [THEN] It should create a record in Tax Type and Use cases.
        Assert.AreNotEqual('', JText, 'JText should not be blank');
    end;


    [Test]
    [HandlerFunctions('UseCaseMsgHandler')]
    procedure TestUseCaseExecution()
    var
        TaxType: Record "Tax Type";
        TaxUseCase: Record "Tax Use Case";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        TaxTransactionValue: Record "Tax Transaction Value";
        Symbols: Record "Script Symbol Value" temporary;
        JsonDeserialization: Codeunit "Tax Json Deserialization";
        UseCaseMgmt: Codeunit "Use Case Mgmt.";
        UseCaseExecution: Codeunit "Use Case Execution";
        LibrarySales: Codeunit "Library - Sales";
        CalTestMgmt: Codeunit "CAL Test Management";
        RecID: RecordId;
        RecRef: RecordRef;
        Record: Variant;
        JArray: JsonArray;
        JText: Text;
    begin
        // [SCENARIO] To check if Tax Engine is calculating Tax

        // [GIVEN] There has to be a tax type with code as VAT  and use case configured and use cases should be enabled.
        TaxType.SetHideDialog(true);
        TaxType.SetRange(Code, 'VAT');
        if TaxType.FindFirst() then begin
            TaxUseCase.SetRange("Tax Type", 'VAT');
            UseCaseMgmt.DisableSelectedUseCases(TaxUseCase);
            TaxType.Delete(true);
        end;
        JText := TaxConfigTestHelper.GetJsonInText();
        JArray.ReadFrom(JText); // validating if json is valid
        JsonDeserialization.SetCanImportUseCases(true);
        JsonDeserialization.ImportTaxTypes(JText);

        LibrarySales.CreateCustomer(Customer);
        Customer.validate("VAT Bus. Posting Group", 'DOMESTIC');
        Customer.Modify();

        Item.FindFirst();
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Order, Customer."No.");
        CalTestMgmt.SETPUBLISHMODE();
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, "Sales Line Type"::Item, Item."No.", 1);
        CalTestMgmt.SETTESTMODE();

        // [WHEN] function ExecuteUseCaseTree of Tax engine should trigger tax engine for tax calculation
        RecRef.GetTable(SalesLine);
        Record := RecRef;
        TaxUseCase.Reset();
        TaxUseCase.SetRange("Tax Type", 'VAT');
        TaxUseCase.SetRange("Parent Use Case ID", EmptyGuid);
        TaxUseCase.FindFirst();
        UseCaseExecution.ExecuteUseCaseTree(TaxUseCase.ID, Record, Symbols, RecID, SalesHeader."Currency Code", SalesHeader."Currency Factor");

        // [THEN] It should calculate tax and create records in transaction value
        TaxTransactionValue.SetRange("Tax Record ID", SalesLine.RecordId);
        Assert.RecordIsNotEmpty(TaxTransactionValue);
    end;



    [Test]
    [HandlerFunctions('UseCaseMsgHandler')]
    procedure TestUseCasePostingExecution()
    var
        TaxType: Record "Tax Type";
        TaxUseCase: Record "Tax Use Case";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvLine: Record "Sales Invoice Line";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        TaxTransactionValue: Record "Tax Transaction Value";
        Symbols: Record "Script Symbol Value" temporary;
        JsonDeserialization: Codeunit "Tax Json Deserialization";
        UseCaseMgmt: Codeunit "Use Case Mgmt.";
        LibrarySales: Codeunit "Library - Sales";
        CalTestMgmt: Codeunit "CAL Test Management";
        UseCaseExecution: Codeunit "Use Case Execution";
        RecRef: RecordRef;
        RecID: RecordId;
        Record: Variant;
        PostedDocumentNo: Code[20];
        JArray: JsonArray;
        JText: Text;
    begin
        // [SCENARIO] To check if Tax Engine is calculating and posting tax 

        // [GIVEN] There has to be a tax type with code as VAT and use case configured and use cases should be enabled.
        TaxType.SetHideDialog(true);
        TaxType.SetRange(Code, 'VAT');
        if TaxType.FindFirst() then begin
            TaxUseCase.SetRange("Tax Type", 'VAT');
            UseCaseMgmt.DisableSelectedUseCases(TaxUseCase);
            TaxType.Delete(true);
        end;
        JText := TaxConfigTestHelper.GetJsonInText();
        JArray.ReadFrom(JText); // validating if json is valid
        JsonDeserialization.SetCanImportUseCases(true);
        JsonDeserialization.ImportTaxTypes(JText);

        LibrarySales.CreateCustomer(Customer);
        Customer.validate("VAT Bus. Posting Group", 'DOMESTIC');
        Customer.Modify();

        Item.FindFirst();
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Order, Customer."No.");
        CalTestMgmt.SETPUBLISHMODE();
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, "Sales Line Type"::Item, Item."No.", 1);
        CalTestMgmt.SETTESTMODE();

        RecRef.GetTable(SalesLine);
        Record := RecRef;
        TaxUseCase.Reset();
        TaxUseCase.SetRange("Tax Type", 'VAT');
        TaxUseCase.SetRange("Parent Use Case ID", EmptyGuid);
        TaxUseCase.FindFirst();
        UseCaseExecution.ExecuteUseCaseTree(TaxUseCase.ID, Record, Symbols, RecID, SalesHeader."Currency Code", SalesHeader."Currency Factor");

        // [WHEN] A Sales document is posted
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] It should post the tax and transfer records with posted record id's
        SalesInvLine.SetRange("Document No.", PostedDocumentNo);
        SalesInvLine.FindFirst();
        TaxTransactionValue.SetRange("Tax Record ID", SalesInvLine.RecordId);
        Assert.RecordIsNotEmpty(TaxTransactionValue);
    end;

    [MessageHandler]
    procedure UseCaseMsgHandler(Message: Text[1024])
    begin

    end;
}