codeunit 137551 "Tax Document GL Posting Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [TaxEngine] [Tax Document GL Posting] [UT]
    end;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure TestTransferTransactionValue()
    var
        SalesLine: Record "Sales Line";
        SalesInvLine: Record "Sales Invoice Line";
        SalesHeader: Record "Sales Header";
        TaxTransactionValue: Record "Tax Transaction Value";
        TempTransactionValue: Record "Tax Transaction Value" temporary;
        LibraryTaxTypeTests: Codeunit "Library - Tax Type Tests";
        LibraryUseCaseTests: Codeunit "Library - Use Case Tests";
        TaxDocumentGLPosting: Codeunit "Tax Document GL Posting";
        TaxPostingBufferMgmt: Codeunit "Tax Posting Buffer Mgmt.";
        LibrarySales: Codeunit "Library - Sales";
        FromRecID: RecordId;
        Type: Option Option,Text,Integer,Decimal,Boolean,Date;
        CaseID, TaxID, EmptyGuid : Guid;
        PostedDocumentNo: Code[20];
        AttributeID, ComponentID : Integer;
    begin
        // [SCENARIO] To check system is transfering transaction value from one RecordID to another RecordID

        // [GIVEN] There should be record in transaction value table 
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetFilter("Qty. to Invoice", '<>%1', 0);
        SalesLine.FindFirst();
        FromRecID := SalesLine.RecordId();

        SalesHeader.get(SalesLine."Document Type", SalesLine."Document No.");

        CaseID := CreateGuid();
        TaxID := CreateGuid();
        LibraryTaxTypeTests.CreateTaxType('VAT', 'VAT');
        AttributeID := LibraryTaxTypeTests.CreateTaxAttribute('VAT', 'VATBusPostingGrp', Type::Text, Database::"Sales Header", SalesLine.FieldNo("VAT Bus. Posting Group"), 0, false);
        ComponentID := LibraryTaxTypeTests.CreateComponent('VAT', 'VAT', "Rounding Direction"::Nearest, 0.1, false);
        LibraryUseCaseTests.CreateUseCase('VAT', CaseID, Database::"Sales Line", 'Test Use Case', EmptyGuid);
        LibraryUseCaseTests.CreateTransactionValue(CaseID, AttributeID, "Transaction Value Type"::ATTRIBUTE, SalesLine."VAT Bus. Posting Group", 0, 0, SalesLine.RecordId, 'VAT');
        LibraryUseCaseTests.CreateTransactionValue(CaseID, ComponentID, "Transaction Value Type"::COMPONENT, '', 10000, 10, SalesLine.RecordId, 'VAT');

        // [WHEN] PrepareTransactionValueToPost function is called
        TaxDocumentGLPosting.PrepareTransactionValueToPost(
            SalesLine.RecordId,
            SalesLine.Quantity,
            SalesLine.Quantity,
            SalesHeader."Currency Code",
            SalesHeader."Currency Factor",
            TempTransactionValue);

        SalesLine.Next();

        TaxDocumentGLPosting.TransferTransactionValue(
            FromRecID,
            SalesLine.RecordId(),
            TempTransactionValue);

        // [THEN] it should create records in transaction value for new Sales Line record
        TaxTransactionValue.SetRange("Tax Record ID", SalesLine.RecordId());
        Assert.RecordIsNotEmpty(TaxTransactionValue);
    end;
}