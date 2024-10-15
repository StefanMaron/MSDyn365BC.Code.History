﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Sales.Comment;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Sales.Setup;

codeunit 10620 "E-Invoice Exp. Sales Cr. Memo"
{
    Permissions = TableData "Sales Cr.Memo Header" = rm;
    TableNo = "Sales Cr.Memo Header";

    trigger OnRun()
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        TempEInvoiceExportHeader: Record "E-Invoice Export Header" temporary;
        TempEInvoiceExportLine: Record "E-Invoice Export Line" temporary;
    begin
        // Check section
        SalesCrMemoLine.SetRange("Document No.", Rec."No.");
        SalesCrMemoLine.SetFilter(Type, '>%1', 0);
        SalesCrMemoLine.SetFilter("No.", '<>%1', ' ');
        if not SalesCrMemoLine.FindSet() then
            exit;

        CODEUNIT.Run(CODEUNIT::"E-Invoice Check Sales Cr. Memo", Rec);

        // Transfer data section
        FillHeaderTableData(TempEInvoiceExportHeader, Rec);
        repeat
            if not IsRoundingLine(SalesCrMemoLine) then
                FillLineTableData(TempEInvoiceExportLine, SalesCrMemoLine);
        until SalesCrMemoLine.Next() = 0;

        // Export section
        ExportToXML(TempEInvoiceExportHeader, TempEInvoiceExportLine);
        ModifySalesCrMemoHeader(Rec."No.");
    end;

    var
        GLSetup: Record "General Ledger Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        TempEInvoiceTransferFile: Record "E-Invoice Transfer File" temporary;

    local procedure ExportToXML(var TempEInvoiceExportHeader: Record "E-Invoice Export Header" temporary; var TempEInvoiceExportLine: Record "E-Invoice Export Line" temporary)
    var
        EInvoiceExportCommon: Codeunit "E-Invoice Export Common";
    begin
        // Initialize
        with EInvoiceExportCommon do begin
            SetEInvoiceCommonTables(TempEInvoiceExportHeader, TempEInvoiceExportLine);

            // Common
            CreateDocAndRootNode();
            AddHeaderCommonContent();
            AddHeaderNote();
            AddHeaderDocumentCurrencyCode();
            AddHeaderTaxCurrencyCode();
            AddHeaderBillingReference();
            AddHeaderAccountingSupplierParty();
            AddHeaderAccountingCustomerParty();
            AddDelivery();
            AddHeaderTaxExchangeRate();
            AddHeaderAllowanceCharge();
            AddHeaderTaxTotal();
            AddHeaderLegalMonetaryTotal();

            // Common for invoice and credit memo header
            TempEInvoiceExportLine.FindSet();

            repeat
                CreateLineNode(TempEInvoiceExportLine);
                AddLineInvCrMemoCommonContent();
                AddDelivery();
                AddLineTaxTotal();
                AddLineItem();
                AddLinePrice();
            until TempEInvoiceExportLine.Next() = 0;

            SetEInvoiceCommonTables(TempEInvoiceExportHeader, TempEInvoiceExportLine);

            // Save file
            SalesReceivablesSetup.Get();
            SaveToXML(TempEInvoiceTransferFile, SalesReceivablesSetup."E-Invoice Sales Cr. Memo Path", TempEInvoiceExportHeader."No.");
        end;
    end;

    local procedure FillHeaderTableData(var TempEInvoiceExportHeader: Record "E-Invoice Export Header" temporary; SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesCommentLine: Record "Sales Comment Line";
        EInvoiceDocumentEncode: Codeunit "E-Invoice Document Encode";
    begin
        with TempEInvoiceExportHeader do begin
            Init();

            // header fields related to the source table
            TransferFields(SalesCrMemoHeader);

            // calculated fields
            if "Currency Code" = '' then begin
                GLSetup.Get();
                "Currency Code" := GLSetup."LCY Code";
            end;

            if SalesCrMemoHeader."Applies-to Doc. Type" = SalesCrMemoHeader."Applies-to Doc. Type"::Invoice then
                "Document No." := SalesCrMemoHeader."Applies-to Doc. No.";

            // header fields not related to the source table
            "Schema Name" := 'CreditNote';
            "Schema Location" := 'urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2 UBL-CreditNote-2.0.xsd';
            xmlns := 'urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2';
            "Customization ID" :=
              'urn:www.cenbii.eu:transaction:biitrns014:ver2.0:extended:' +
              'urn:www.cenbii.eu:profile:biixx:ver2.0:extended:' + 'urn:www.difi.no:ehf:kreditnota:ver2.0';
            "Profile ID" := 'urn:www.cenbii.eu:profile:biixx:ver2.0';
            "Uses Common Aggregate Comp." := true;
            "Uses Common Basic Comp." := true;
            "Uses Common Extension Comp." := false;
            "Quantity Name" := 'CreditedQuantity';

            // header fields related to tax amounts
            FillHeaderTaxAmounts(TempEInvoiceExportHeader);

            // custom
            "Bill-to Country/Region Code" := EInvoiceDocumentEncode.GetEInvoiceCountryRegionCode("Bill-to Country/Region Code");
            if SalesCommentLine.Get(SalesCommentLine."Document Type"::"Posted Credit Memo", SalesCrMemoHeader."No.", 0, 10000) then
                Note := SalesCommentLine.Comment;
            Insert();
        end;
    end;

    local procedure FillHeaderTaxAmounts(var EInvoiceExportHeader: Record "E-Invoice Export Header")
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoLine.SetRange("Document No.", EInvoiceExportHeader."No.");
        if SalesCrMemoLine.FindSet() then begin
            EInvoiceExportHeader."Sales Line Found" := true;
            repeat
                if IsRoundingLine(SalesCrMemoLine) then
                    EInvoiceExportHeader."Total Rounding Amount" += SalesCrMemoLine."Amount Including VAT"
                else begin
                    EInvoiceExportHeader."Total Invoice Discount Amount" +=
                      SalesCrMemoLine."Inv. Discount Amount" + SalesCrMemoLine."Line Discount Amount";
                    EInvoiceExportHeader."Legal Taxable Amount" += SalesCrMemoLine.Amount;
                    EInvoiceExportHeader."Total Amount" += SalesCrMemoLine."Amount Including VAT";
                    EInvoiceExportHeader."Tax Amount" += SalesCrMemoLine."Amount Including VAT" - SalesCrMemoLine.Amount;
                end;
            until SalesCrMemoLine.Next() = 0;
        end;
    end;

    local procedure FillLineTableData(var TempEInvoiceExportLine: Record "E-Invoice Export Line" temporary; SalesCrMemoLine: Record "Sales Cr.Memo Line")
    var
        SalesCommentLine: Record "Sales Comment Line";
        Id: Integer;
    begin
        if TempEInvoiceExportLine.FindLast() then
            Id := TempEInvoiceExportLine.ID + 1;

        TempEInvoiceExportLine.Init();
        TempEInvoiceExportLine.ID := Id;

        TempEInvoiceExportLine.TransferFields(SalesCrMemoLine, true);
        if SalesCommentLine.Get(
             SalesCommentLine."Document Type"::"Posted Credit Memo", SalesCrMemoLine."Document No.", SalesCrMemoLine."Line No.", 10000)
        then
            TempEInvoiceExportLine.Comment := SalesCommentLine.Comment;
        TempEInvoiceExportLine.Insert();
    end;

    local procedure IsRoundingLine(SalesCrMemoLine: Record "Sales Cr.Memo Line"): Boolean
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        if SalesCrMemoLine.Type = SalesCrMemoLine.Type::"G/L Account" then begin
            Customer.Get(SalesCrMemoLine."Bill-to Customer No.");
            CustomerPostingGroup.SetFilter(Code, Customer."Customer Posting Group");
            if CustomerPostingGroup.FindFirst() then
                if SalesCrMemoLine."No." = CustomerPostingGroup."Invoice Rounding Account" then
                    exit(true);
        end;
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure ModifySalesCrMemoHeader(DocumentNo: Code[20])
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader.Get(DocumentNo);
        SalesCrMemoHeader."E-Invoice Created" := true;
        SalesCrMemoHeader.Modify();
    end;

    [Scope('OnPrem')]
    procedure GetExportedFileInfo(var EInvoiceTransferFile: Record "E-Invoice Transfer File")
    begin
        EInvoiceTransferFile := TempEInvoiceTransferFile;
    end;
}

