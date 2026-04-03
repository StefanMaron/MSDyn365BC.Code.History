// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

using Microsoft.EServices.EDocument;

#pragma warning disable AL0659
enum 135 "Attachment Entity Buffer Document Type" implements IPdfDocumentHandler
#pragma warning restore AL0659
{
    Extensible = true;
    DefaultImplementation = IPdfDocumentHandler = "Default PDF Doc.Handler";

    value(0; " ") { Caption = ' '; }
    value(1; "Journal") { Caption = 'Journal'; }
    value(2; "Sales Order") { Caption = 'Sales Order'; Implementation = IPdfDocumentHandler = "Sales Order PDF Doc.Handler"; }
    value(3; "Sales Quote") { Caption = 'Sales Quote'; Implementation = IPdfDocumentHandler = "Sales Quote PDF Doc.Handler"; }
    value(4; "Sales Credit Memo") { Caption = 'Sales Credit Memo'; Implementation = IPdfDocumentHandler = "Sales Cr.Memo PDF Doc.Handler"; }
    value(5; "Sales Invoice") { Caption = 'Sales Invoice'; Implementation = IPdfDocumentHandler = "Sales Invoice PDF Doc.Handler"; }
    value(6; "Purchase Invoice") { Caption = 'Purchase Invoice'; Implementation = IPdfDocumentHandler = "Purch. Invoice PDF Doc.Handler"; }
    value(7; "Purchase Order") { Caption = 'Purchase Order'; Implementation = IPdfDocumentHandler = "Purch. Order PDF Doc.Handler"; }
    value(9; "Employee") { Caption = 'Employee'; }
    value(10; "Job") { Caption = 'Project'; Implementation = IPdfDocumentHandler = "Project PDF Doc.Handler"; }
    value(11; "Item") { Caption = 'Item'; }
    value(12; "Customer") { Caption = 'Customer'; }
    value(13; "Vendor") { Caption = 'Vendor'; }
    value(14; "Purchase Credit Memo") { Caption = 'Purchase Credit Memo'; Implementation = IPdfDocumentHandler = "Purch. Cr.Memo PDF Doc.Handler"; }
    value(15; "Customer Statement") { Caption = 'Customer Statement'; Implementation = IPdfDocumentHandler = "Cust. St. PDF Doc.Handler"; }
}