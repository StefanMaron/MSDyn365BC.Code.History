codeunit 136864 "Use Case Mgmt. Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    var
        Assert: Codeunit Assert;
        LibraryUseCase: Codeunit "Library - Use Case Tests";
        LibraryTaxType: Codeunit "Library - Tax Type Tests";
        LibraryUseCaseTests: Codeunit "Library - Use Case Tests";
        LibraryTaxTypeTests: Codeunit "Library - Tax Type Tests";

    [Test]
    [HandlerFunctions('TableLinkingDialogHandler')]
    procedure TestOpenTableLinkingDialog()
    var
        UseCaseMgmt: Codeunit "Use Case Mgmt.";
        UseCaseEntityMgmt: Codeunit "Use Case Entity Mgmt.";
        CaseID, ID : Guid;
    begin
        // [SCENARIO] To check if Table Linking Dialog is opening

        // [GIVEN] There should be a record in Table linking
        ID := UseCaseEntityMgmt.CreateTableLinking(CaseID, Database::"Sales Line", Database::"Sales Header");

        // [WHEN] Then function OpenTableLinkingDialog is called
        UseCaseMgmt.OpenTableLinkingDialog(CaseID, ID);

        // [THEN] it should open Table Linking dialog
    end;

    [Test]
    [HandlerFunctions('TableRelationDialogHandler')]
    procedure TestOpenTableRelationDialog()
    var
        UseCaseMgmt: Codeunit "Use Case Mgmt.";
        UseCaseEntityMgmt: Codeunit "Use Case Entity Mgmt.";
        CaseID, EmptyGuid, ID : Guid;
    begin
        // [SCENARIO] To check if Table Relation Dialog is opening

        // [GIVEN] There should be a record in Table Relation
        CaseID := CreateGuid();
        LibraryTaxType.CreateTaxType('VAT', 'VAT');
        LibraryUseCase.CreateUseCase('VAT', CaseID, Database::"Sales Line", 'Test Use Case', EmptyGuid);
        ID := UseCaseEntityMgmt.CreateTableRelation(CaseID);

        // [WHEN] Then function OpenTableRelationDialog is called
        UseCaseMgmt.OpenTableRelationDialog(CaseID, ID);

        // [THEN] it should open Table Relation dialog
    end;

    [Test]
    [HandlerFunctions('ComponentExpreDialogHandler')]
    procedure TestOpenComponentExprDialog()
    var
        UseCaseMgmt: Codeunit "Use Case Mgmt.";
        UseCaseEntityMgmt: Codeunit "Use Case Entity Mgmt.";
        CaseID, ID, EmptyGuid : Guid;
        ComponentID: Integer;
    begin
        // [SCENARIO] To check if ComponentExprDialog Dialog is opening

        // [GIVEN] There should be a record in ComponentExpr Dialog
        CaseID := CreateGuid();
        LibraryTaxType.CreateTaxType('VAT', 'VAT');
        LibraryUseCase.CreateUseCase('VAT', CaseID, Database::"Sales Line", 'Test Use Case', EmptyGuid);
        ComponentID := LibraryTaxType.CreateComponent('VAT', 'VAT', "Rounding Direction"::Nearest, 0.1, false);
        ID := UseCaseEntityMgmt.CreateComponentExpression(CaseID, ComponentID);

        // [WHEN] Then function OpenComponentExprDialog is called
        UseCaseMgmt.OpenComponentExprDialog(CaseID, ID);

        // [THEN] it should open Component Expression Dialog
    end;


    [Test]
    procedure TestApplyTableLinkFilters()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        UseCaseMgmt: Codeunit "Use Case Mgmt.";
        UseCaseEntityMgmt: Codeunit "Use Case Entity Mgmt.";
        RecRef, LookupRecRef : RecordRef;
        CaseID, ID : Guid;
        ComponentID: Integer;
    begin
        // [SCENARIO] To check if ApplyTableLinkFilters function is applying filters on record

        // [GIVEN] There should be a record in Table Linking created
        CaseID := CreateGuid();
        LibraryTaxTypeTests.CreateTaxType('VAT', 'VAT');
        id := UseCaseEntityMgmt.CreateTableLinking(CaseID, Database::"Sales Header", Database::"Sales Line");
        LibraryUseCaseTests.AddTableFieldLink(CaseID, ID, Database::"Sales Header", Database::"Sales Line", SalesHeader.FieldNo("No."), SalesLine.FieldNo("Document No."));

        // [WHEN] Then function ApplyTableLinkFilters is called
        SalesLine.FindFirst();
        LookupRecRef.GetTable(SalesLine);
        RecRef.Open(Database::"Sales Header");
        UseCaseMgmt.ApplyTableLinkFilters(RecRef, CaseID, ID, LookupRecRef);

        // [THEN] it should open Component Expression Dialog
        Assert.RecordIsNotEmpty(RecRef);
    end;

    [Test]
    [HandlerFunctions('TaxUseCaseCardHandler')]
    procedure TestCreateAndOpenChildUseCaseCard()
    var
        TaxUseCase: Record "Tax Use Case";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        UseCaseMgmt: Codeunit "Use Case Mgmt.";
        UseCaseEntityMgmt: Codeunit "Use Case Entity Mgmt.";
        RecRef, LookupRecRef : RecordRef;
        CaseID, EmptyGuid : Guid;
        Type: Option Option,Text,Integer,Decimal,Boolean,Date;
        AttributeID: Integer;
    begin
        // [SCENARIO] To check if CreateAndOpenChildUseCaseCard function is creating child use 

        // [GIVEN] There should be a record in Tax Use Case
        CaseID := CreateGuid();
        LibraryTaxTypeTests.CreateTaxType('VAT', 'VAT');
        LibraryUseCase.CreateUseCase('VAT', CaseID, Database::"Sales Line", 'Test Use Case', EmptyGuid);
        AttributeID := LibraryTaxTypeTests.CreateTaxAttribute('VAT', 'VatBusPostingGrp', Type::Text, Database::"Sales Line", SalesLine.FieldNo("VAT Bus. Posting Group"), 0, false);
        LibraryUseCase.CreateAttributeMapping('VAT', CaseID, AttributeID);
        // [WHEN] Then function ApplyTableLinkFilters is called
        TaxUseCase.Get(CaseID);
        UseCaseMgmt.CreateAndOpenChildUseCaseCard(TaxUseCase);

        // [THEN] it should open Component Expression Dialog
        TaxUseCase.SetRange("Parent Use Case ID", CaseID);
        Assert.RecordIsNotEmpty(TaxUseCase);
    end;



    [Test]
    procedure TestIndentUseCases()
    begin
    end;

    [ModalPageHandler]
    procedure TableLinkingDialogHandler(var TableLinkingDialog: TestPage "Use Case Table Link Dialog")
    begin
        TableLinkingDialog.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure TableRelationDialogHandler(var TableRelationDialog: TestPage "Tax Table Relation Dialog")
    begin
        TableRelationDialog.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ComponentExpreDialogHandler(var ComponentExprDialog: TestPage "Tax Component Expr. Dialog")
    begin
        ComponentExprDialog.OK().Invoke();
    end;

    [PageHandler]
    procedure TaxUseCaseCardHandler(var TaxUseCaseCard: TestPage "Use Case Card")
    begin
        TaxUseCaseCard.OK().Invoke();
    end;
}