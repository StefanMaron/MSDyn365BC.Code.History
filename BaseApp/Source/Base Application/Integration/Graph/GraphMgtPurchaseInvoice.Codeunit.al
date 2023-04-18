codeunit 5527 "Graph Mgt - Purchase Invoice"
{
    Permissions = TableData "Purch. Inv. Header" = rimd;

    trigger OnRun()
    begin
    end;

    procedure ProcessComplexTypes(var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate"; BuyFromAddressJSON: Text)
    begin
        ParseBuyFromVendorAddressFromJSON(BuyFromAddressJSON, PurchInvEntityAggregate);
    end;

    procedure ParseBuyFromVendorAddressFromJSON(BuyFromAddressJSON: Text; var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate")
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        RecRef: RecordRef;
    begin
        if BuyFromAddressJSON <> '' then
            with PurchInvEntityAggregate do begin
                RecRef.GetTable(PurchInvEntityAggregate);
                GraphMgtComplexTypes.ApplyPostalAddressFromJSON(BuyFromAddressJSON, RecRef,
                  FieldNo("Buy-from Address"), FieldNo("Buy-from Address 2"), FieldNo("Buy-from City"), FieldNo("Buy-from County"),
                  FieldNo("Buy-from Country/Region Code"), FieldNo("Buy-from Post Code"));
                RecRef.SetTable(PurchInvEntityAggregate);
            end;
    end;

    procedure ParsePayToVendorAddressFromJSON(PayToAddressJSON: Text; var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate")
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        RecRef: RecordRef;
    begin
        if PayToAddressJSON <> '' then
            with PurchInvEntityAggregate do begin
                RecRef.GetTable(PurchInvEntityAggregate);
                GraphMgtComplexTypes.ApplyPostalAddressFromJSON(PayToAddressJSON, RecRef,
                  FieldNo("Pay-to Address"), FieldNo("Pay-to Address 2"), FieldNo("Pay-to City"), FieldNo("Pay-to County"),
                  FieldNo("Pay-to Country/Region Code"), FieldNo("Pay-to Post Code"));
                RecRef.SetTable(PurchInvEntityAggregate);
            end;
    end;

    procedure ParseShipToVendorAddressFromJSON(ShipToAddressJSON: Text; var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate")
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        RecRef: RecordRef;
    begin
        if ShipToAddressJSON <> '' then
            with PurchInvEntityAggregate do begin
                RecRef.GetTable(PurchInvEntityAggregate);
                GraphMgtComplexTypes.ApplyPostalAddressFromJSON(ShipToAddressJSON, RecRef,
                  FieldNo("Ship-to Address"), FieldNo("Ship-to Address 2"), FieldNo("Ship-to City"), FieldNo("Ship-to County"),
                  FieldNo("Ship-to Country/Region Code"), FieldNo("Ship-to Post Code"));
                RecRef.SetTable(PurchInvEntityAggregate);
            end;
    end;

    procedure BuyFromVendorAddressToJSON(var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate") JSON: Text
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        with PurchInvEntityAggregate do
            GraphMgtComplexTypes.GetPostalAddressJSON("Buy-from Address", "Buy-from Address 2",
              "Buy-from City", "Buy-from County", "Buy-from Country/Region Code", "Buy-from Post Code", JSON);
    end;

    procedure PayToVendorAddressToJSON(var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate") JSON: Text
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        with PurchInvEntityAggregate do
            GraphMgtComplexTypes.GetPostalAddressJSON("Pay-to Address", "Pay-to Address 2",
              "Pay-to City", "Pay-to County", "Pay-to Country/Region Code", "Pay-to Post Code", JSON);
    end;

    procedure ShipToVendorAddressToJSON(var PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate") JSON: Text
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        with PurchInvEntityAggregate do
            GraphMgtComplexTypes.GetPostalAddressJSON("Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to County", "Ship-to Country/Region Code", "Ship-to Post Code", JSON);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mgt - General Tools", 'ApiSetup', '', false, false)]
    [Scope('OnPrem')]
    procedure HandleApiSetup()
    var
        PurchInvAggregator: Codeunit "Purch. Inv. Aggregator";
    begin
        PurchInvAggregator.UpdateAggregateTableRecords();
    end;
}

