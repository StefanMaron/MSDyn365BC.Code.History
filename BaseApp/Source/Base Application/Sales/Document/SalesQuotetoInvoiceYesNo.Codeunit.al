﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.CRM.Outlook;

codeunit 1304 "Sales-Quote to Invoice Yes/No"
{
    TableNo = "Sales Header";

    trigger OnRun()
    var
        InvoiceSalesHeader: Record "Sales Header";
        SalesQuoteToInvoice: Codeunit "Sales-Quote to Invoice";
        OfficeManagement: Codeunit "Office Management";
    begin
        Rec.TestField("Document Type", "Sales Document Type"::Quote);
        if GuiAllowed then
            if not Confirm(ConfirmConvertToInvoiceQst, false) then
                exit;

        SalesQuoteToInvoice.Run(Rec);
        SalesQuoteToInvoice.GetSalesInvoiceHeader(InvoiceSalesHeader);

        Commit();

        if GuiAllowed then
            if OfficeManagement.AttachAvailable() then
                ShowInvoice(InvoiceSalesHeader)
            else
                if Confirm(StrSubstNo(OpenNewInvoiceQst, InvoiceSalesHeader."No."), true) then
                    ShowInvoice(InvoiceSalesHeader);
    end;

    var
        ConfirmConvertToInvoiceQst: Label 'Do you want to convert the quote to an invoice?';
        OpenNewInvoiceQst: Label 'The quote has been converted to invoice %1. Do you want to open the new invoice?', Comment = '%1 - invoice number';

    local procedure ShowInvoice(var InvoiceSalesHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowInvoice(InvoiceSalesHeader, IsHandled);
        if IsHandled then
            exit;

        PAGE.Run(PAGE::"Sales Invoice", InvoiceSalesHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowInvoice(var InvoiceSalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;
}

