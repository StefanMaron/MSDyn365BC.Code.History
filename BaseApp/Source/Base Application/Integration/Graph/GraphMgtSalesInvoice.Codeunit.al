// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

using Microsoft.Integration.Entity;
using Microsoft.Sales.History;

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

    procedure SellToCustomerAddressToJSON(var SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate") JSON: Text
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        with SalesInvoiceEntityAggregate do
            GraphMgtComplexTypes.GetPostalAddressJSON("Sell-to Address", "Sell-to Address 2",
              "Sell-to City", "Sell-to County", "Sell-to Country/Region Code", "Sell-to Post Code", JSON);
    end;

    procedure BillToCustomerAddressToJSON(var SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate") JSON: Text
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        with SalesInvoiceEntityAggregate do
            GraphMgtComplexTypes.GetPostalAddressJSON("Bill-to Address", "Bill-to Address 2",
              "Bill-to City", "Bill-to County", "Bill-to Country/Region Code", "Bill-to Post Code", JSON);
    end;

    procedure ShipToCustomerAddressToJSON(var SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate") JSON: Text
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
    begin
        with SalesInvoiceEntityAggregate do
            GraphMgtComplexTypes.GetPostalAddressJSON("Ship-to Address", "Ship-to Address 2",
              "Ship-to City", "Ship-to County", "Ship-to Country/Region Code", "Ship-to Post Code", JSON);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mgt - General Tools", 'ApiSetup', '', false, false)]
    [Scope('OnPrem')]
    procedure HandleApiSetup()
    var
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
    begin
        SalesInvoiceAggregator.UpdateAggregateTableRecords();
    end;
}

