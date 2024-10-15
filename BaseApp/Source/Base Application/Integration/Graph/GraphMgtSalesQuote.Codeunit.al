// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

using Microsoft.Integration.Entity;

codeunit 5505 "Graph Mgt - Sales Quote"
{

    trigger OnRun()
    begin
    end;

    procedure ProcessComplexTypes(var SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer"; SellToAddressJSON: Text)
    begin
        ParseSellToCustomerAddressFromJSON(SellToAddressJSON, SalesQuoteEntityBuffer);
    end;

    procedure ParseSellToCustomerAddressFromJSON(SellToAddressJSON: Text; var SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer")
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        RecRef: RecordRef;
    begin
        if SellToAddressJSON <> '' then
            with SalesQuoteEntityBuffer do begin
                RecRef.GetTable(SalesQuoteEntityBuffer);
                GraphMgtComplexTypes.ApplyPostalAddressFromJSON(SellToAddressJSON, RecRef,
                  FieldNo("Sell-to Address"), FieldNo("Sell-to Address 2"), FieldNo("Sell-to City"), FieldNo("Sell-to County"),
                  FieldNo("Sell-to Country/Region Code"), FieldNo("Sell-to Post Code"));
                RecRef.SetTable(SalesQuoteEntityBuffer);
            end;
    end;

    procedure ParseBillToCustomerAddressFromJSON(BillToAddressJSON: Text; var SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer")
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        RecRef: RecordRef;
    begin
        if BillToAddressJSON <> '' then
            with SalesQuoteEntityBuffer do begin
                RecRef.GetTable(SalesQuoteEntityBuffer);
                GraphMgtComplexTypes.ApplyPostalAddressFromJSON(BillToAddressJSON, RecRef,
                  FieldNo("Bill-to Address"), FieldNo("Bill-to Address 2"), FieldNo("Bill-to City"), FieldNo("Bill-to County"),
                  FieldNo("Bill-to Country/Region Code"), FieldNo("Bill-to Post Code"));
                RecRef.SetTable(SalesQuoteEntityBuffer);
            end;
    end;

    procedure ParseShipToCustomerAddressFromJSON(ShipToAddressJSON: Text; var SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer")
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        RecRef: RecordRef;
    begin
        if ShipToAddressJSON <> '' then
            with SalesQuoteEntityBuffer do begin
                RecRef.GetTable(SalesQuoteEntityBuffer);
                GraphMgtComplexTypes.ApplyPostalAddressFromJSON(ShipToAddressJSON, RecRef,
                  FieldNo("Ship-to Address"), FieldNo("Ship-to Address 2"), FieldNo("Ship-to City"), FieldNo("Ship-to County"),
                  FieldNo("Ship-to Country/Region Code"), FieldNo("Ship-to Post Code"));
                RecRef.SetTable(SalesQuoteEntityBuffer);
            end;
    end;

    procedure SellToCustomerAddressToJSON(SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer") JSON: Text
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        with SalesQuoteEntityBuffer do
            GraphMgtComplexTypes.GetPostalAddressJSON("Sell-to Address", "Sell-to Address 2",
              "Sell-to City", "Sell-to County", "Sell-to Country/Region Code", "Sell-to Post Code", JSON);
    end;

    procedure BillToCustomerAddressToJSON(SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer") JSON: Text
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        with SalesQuoteEntityBuffer do
            GraphMgtComplexTypes.GetPostalAddressJSON("Bill-to Address", "Bill-to Address 2",
              "Bill-to City", "Bill-to County", "Bill-to Country/Region Code", "Bill-to Post Code", JSON);
    end;

    procedure ShipToCustomerAddressToJSON(SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer") JSON: Text
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        with SalesQuoteEntityBuffer do
            GraphMgtComplexTypes.GetPostalAddressJSON("Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to County", "Ship-to Country/Region Code", "Ship-to Post Code", JSON);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mgt - General Tools", 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    var
        GraphMgtSalesQuoteBuffer: Codeunit "Graph Mgt - Sales Quote Buffer";
    begin
        GraphMgtSalesQuoteBuffer.UpdateBufferTableRecords();
    end;
}

