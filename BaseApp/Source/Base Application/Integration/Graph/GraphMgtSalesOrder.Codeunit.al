codeunit 5495 "Graph Mgt - Sales Order"
{
    Permissions = TableData "Sales Invoice Header" = rimd;

    trigger OnRun()
    begin
    end;

    procedure ProcessComplexTypes(var SalesOrderEntityBuffer: Record "Sales Order Entity Buffer"; SellToAddressJSON: Text)
    begin
        ParseSellToCustomerAddressFromJSON(SellToAddressJSON, SalesOrderEntityBuffer);
    end;

    procedure ParseSellToCustomerAddressFromJSON(SellToAddressJSON: Text; var SalesOrderEntityBuffer: Record "Sales Order Entity Buffer")
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        RecRef: RecordRef;
    begin
        if SellToAddressJSON <> '' then
            with SalesOrderEntityBuffer do begin
                RecRef.GetTable(SalesOrderEntityBuffer);
                GraphMgtComplexTypes.ApplyPostalAddressFromJSON(SellToAddressJSON, RecRef,
                  FieldNo("Sell-to Address"), FieldNo("Sell-to Address 2"), FieldNo("Sell-to City"), FieldNo("Sell-to County"),
                  FieldNo("Sell-to Country/Region Code"), FieldNo("Sell-to Post Code"));
                RecRef.SetTable(SalesOrderEntityBuffer);
            end;
    end;

    procedure ParseBillToCustomerAddressFromJSON(BillToAddressJSON: Text; var SalesOrderEntityBuffer: Record "Sales Order Entity Buffer")
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        RecRef: RecordRef;
    begin
        if BillToAddressJSON <> '' then
            with SalesOrderEntityBuffer do begin
                RecRef.GetTable(SalesOrderEntityBuffer);
                GraphMgtComplexTypes.ApplyPostalAddressFromJSON(BillToAddressJSON, RecRef,
                  FieldNo("Bill-to Address"), FieldNo("Bill-to Address 2"), FieldNo("Bill-to City"), FieldNo("Bill-to County"),
                  FieldNo("Bill-to Country/Region Code"), FieldNo("Bill-to Post Code"));
                RecRef.SetTable(SalesOrderEntityBuffer);
            end;
    end;

    procedure ParseShipToCustomerAddressFromJSON(ShipToAddressJSON: Text; var SalesOrderEntityBuffer: Record "Sales Order Entity Buffer")
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        RecRef: RecordRef;
    begin
        if ShipToAddressJSON <> '' then
            with SalesOrderEntityBuffer do begin
                RecRef.GetTable(SalesOrderEntityBuffer);
                GraphMgtComplexTypes.ApplyPostalAddressFromJSON(ShipToAddressJSON, RecRef,
                  FieldNo("Ship-to Address"), FieldNo("Ship-to Address 2"), FieldNo("Ship-to City"), FieldNo("Ship-to County"),
                  FieldNo("Ship-to Country/Region Code"), FieldNo("Ship-to Post Code"));
                RecRef.SetTable(SalesOrderEntityBuffer);
            end;
    end;

    procedure SellToCustomerAddressToJSON(var SalesOrderEntityBuffer: Record "Sales Order Entity Buffer") JSON: Text
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        with SalesOrderEntityBuffer do
            GraphMgtComplexTypes.GetPostalAddressJSON("Sell-to Address", "Sell-to Address 2",
              "Sell-to City", "Sell-to County", "Sell-to Country/Region Code", "Sell-to Post Code", JSON);
    end;

    procedure BillToCustomerAddressToJSON(var SalesOrderEntityBuffer: Record "Sales Order Entity Buffer") JSON: Text
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        with SalesOrderEntityBuffer do
            GraphMgtComplexTypes.GetPostalAddressJSON("Bill-to Address", "Bill-to Address 2",
              "Bill-to City", "Bill-to County", "Bill-to Country/Region Code", "Bill-to Post Code", JSON);
    end;

    procedure ShipToCustomerAddressToJSON(var SalesOrderEntityBuffer: Record "Sales Order Entity Buffer") JSON: Text
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        with SalesOrderEntityBuffer do
            GraphMgtComplexTypes.GetPostalAddressJSON("Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to County", "Ship-to Country/Region Code", "Ship-to Post Code", JSON);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mgt - General Tools", 'ApiSetup', '', false, false)]
    [Scope('OnPrem')]
    procedure HandleApiSetup()
    var
        GraphMgtSalesOrderBuffer: Codeunit "Graph Mgt - Sales Order Buffer";
    begin
        GraphMgtSalesOrderBuffer.UpdateBufferTableRecords();
    end;
}

