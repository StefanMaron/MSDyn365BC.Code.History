codeunit 5475 "Graph Mgt - Sales Invoice"
{
    Permissions = TableData "Sales Invoice Header" = rimd;

    trigger OnRun()
    begin
    end;

    procedure ProcessComplexTypes(var SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate"; SellToAddressJSON: Text)
    begin
        ParseSellToCustomerAddressFromJSON(SellToAddressJSON, SalesInvoiceEntityAggregate);
    end;

    procedure ParseSellToCustomerAddressFromJSON(SellToAddressJSON: Text; var SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate")
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        RecRef: RecordRef;
    begin
        if SellToAddressJSON <> '' then
            with SalesInvoiceEntityAggregate do begin
                RecRef.GetTable(SalesInvoiceEntityAggregate);
                GraphMgtComplexTypes.ApplyPostalAddressFromJSON(SellToAddressJSON, RecRef,
                  FieldNo("Sell-to Address"), FieldNo("Sell-to Address 2"), FieldNo("Sell-to City"), FieldNo("Sell-to County"),
                  FieldNo("Sell-to Country/Region Code"), FieldNo("Sell-to Post Code"));
                RecRef.SetTable(SalesInvoiceEntityAggregate);
            end;
    end;

    procedure ParseBillToCustomerAddressFromJSON(BillToAddressJSON: Text; var SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate")
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        RecRef: RecordRef;
    begin
        if BillToAddressJSON <> '' then
            with SalesInvoiceEntityAggregate do begin
                RecRef.GetTable(SalesInvoiceEntityAggregate);
                GraphMgtComplexTypes.ApplyPostalAddressFromJSON(BillToAddressJSON, RecRef,
                  FieldNo("Bill-to Address"), FieldNo("Bill-to Address 2"), FieldNo("Bill-to City"), FieldNo("Bill-to County"),
                  FieldNo("Bill-to Country/Region Code"), FieldNo("Bill-to Post Code"));
                RecRef.SetTable(SalesInvoiceEntityAggregate);
            end;
    end;

    procedure ParseShipToCustomerAddressFromJSON(ShipToAddressJSON: Text; var SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate")
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        RecRef: RecordRef;
    begin
        if ShipToAddressJSON <> '' then
            with SalesInvoiceEntityAggregate do begin
                RecRef.GetTable(SalesInvoiceEntityAggregate);
                GraphMgtComplexTypes.ApplyPostalAddressFromJSON(ShipToAddressJSON, RecRef,
                  FieldNo("Ship-to Address"), FieldNo("Ship-to Address 2"), FieldNo("Ship-to City"), FieldNo("Ship-to County"),
                  FieldNo("Ship-to Country/Region Code"), FieldNo("Ship-to Post Code"));
                RecRef.SetTable(SalesInvoiceEntityAggregate);
            end;
    end;

    procedure SellToCustomerAddressToJSON(SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate") JSON: Text
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        with SalesInvoiceEntityAggregate do
            GraphMgtComplexTypes.GetPostalAddressJSON("Sell-to Address", "Sell-to Address 2",
              "Sell-to City", "Sell-to County", "Sell-to Country/Region Code", "Sell-to Post Code", JSON);
    end;

    procedure BillToCustomerAddressToJSON(SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate") JSON: Text
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        with SalesInvoiceEntityAggregate do
            GraphMgtComplexTypes.GetPostalAddressJSON("Bill-to Address", "Bill-to Address 2",
              "Bill-to City", "Bill-to County", "Bill-to Country/Region Code", "Bill-to Post Code", JSON);
    end;

    procedure ShipToCustomerAddressToJSON(SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate") JSON: Text
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        with SalesInvoiceEntityAggregate do
            GraphMgtComplexTypes.GetPostalAddressJSON("Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to County", "Ship-to Country/Region Code", "Ship-to Post Code", JSON);
    end;

    procedure UpdateIntegrationRecordIds(OnlyRecordsWithoutID: Boolean)
    var
        DummySalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
        DummyCustomer: Record Customer;
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        SalesInvoiceHeaderRecordRef: RecordRef;
        SalesHeaderRecordRef: RecordRef;
        CustomerRecordRef: RecordRef;
    begin
        CustomerRecordRef.Open(DATABASE::Customer);
        GraphMgtGeneralTools.UpdateIntegrationRecords(
          CustomerRecordRef, DummyCustomer.FieldNo(Id), true);

        SalesHeaderRecordRef.Open(DATABASE::"Sales Header");
        GraphMgtGeneralTools.UpdateIntegrationRecords(
          SalesHeaderRecordRef, DummySalesInvoiceEntityAggregate.FieldNo(Id), OnlyRecordsWithoutID);

        SalesInvoiceHeaderRecordRef.Open(DATABASE::"Sales Invoice Header");
        GraphMgtGeneralTools.UpdateIntegrationRecords(
          SalesInvoiceHeaderRecordRef, DummySalesInvoiceEntityAggregate.FieldNo(Id), OnlyRecordsWithoutID);
    end;

    [EventSubscriber(ObjectType::Codeunit, 5465, 'ApiSetup', '', false, false)]
    [Scope('OnPrem')]
    procedure HandleApiSetup()
    var
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
    begin
        UpdateIntegrationRecordIds(false);
        SalesInvoiceAggregator.UpdateAggregateTableRecords;
    end;
}

