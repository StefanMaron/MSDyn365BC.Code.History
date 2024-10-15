// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Attachment;

using Microsoft.Finance.VAT.Reporting;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.HumanResources.Employee;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;

page 1174 "Document Attachment Factbox"
{
    Caption = 'Documents Attached';
    PageType = CardPart;
    SourceTable = "Document Attachment";

    layout
    {
        area(content)
        {
            group(Control2)
            {
                ShowCaption = false;
                field(Documents; NumberOfRecords)
                {
                    ApplicationArea = All;
                    Caption = 'Documents';
                    StyleExpr = true;
                    ToolTip = 'Specifies the number of attachments.';

                    trigger OnDrillDown()
                    var
                        Customer: Record Customer;
                        Vendor: Record Vendor;
                        Item: Record Item;
                        Employee: Record Employee;
                        FixedAsset: Record "Fixed Asset";
                        Resource: Record Resource;
                        SalesHeader: Record "Sales Header";
                        PurchaseHeader: Record "Purchase Header";
                        Job: Record Job;
                        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
                        SalesInvoiceHeader: Record "Sales Invoice Header";
                        PurchInvHeader: Record "Purch. Inv. Header";
                        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
                        VATReportHeader: Record "VAT Report Header";
                        ServiceItem: Record "Service Item";
                        ServiceHeader: Record "Service Header";
                        ServiceLine: Record "Service Line";
                        ServiceInvoiceHeader: Record "Service Invoice Header";
                        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
                        ServiceContractHeader: Record "Service Contract Header";
                        DocumentAttachmentDetails: Page "Document Attachment Details";
                        RecRef: RecordRef;
                    begin
                        case Rec."Table ID" of
                            0:
                                exit;
                            Database::Customer:
                                begin
                                    RecRef.Open(Database::Customer);
                                    if Customer.Get(Rec."No.") then
                                        RecRef.GetTable(Customer);
                                end;
                            Database::Vendor:
                                begin
                                    RecRef.Open(Database::Vendor);
                                    if Vendor.Get(Rec."No.") then
                                        RecRef.GetTable(Vendor);
                                end;
                            Database::Item:
                                begin
                                    RecRef.Open(Database::Item);
                                    if Item.Get(Rec."No.") then
                                        RecRef.GetTable(Item);
                                end;
                            Database::Employee:
                                begin
                                    RecRef.Open(Database::Employee);
                                    if Employee.Get(Rec."No.") then
                                        RecRef.GetTable(Employee);
                                end;
                            Database::"Fixed Asset":
                                begin
                                    RecRef.Open(Database::"Fixed Asset");
                                    if FixedAsset.Get(Rec."No.") then
                                        RecRef.GetTable(FixedAsset);
                                end;
                            Database::Resource:
                                begin
                                    RecRef.Open(Database::Resource);
                                    if Resource.Get(Rec."No.") then
                                        RecRef.GetTable(Resource);
                                end;
                            Database::Job:
                                begin
                                    RecRef.Open(Database::Job);
                                    if Job.Get(Rec."No.") then
                                        RecRef.GetTable(Job);
                                end;
                            Database::"Sales Header":
                                begin
                                    RecRef.Open(Database::"Sales Header");
                                    if SalesHeader.Get(Rec."Document Type", Rec."No.") then
                                        RecRef.GetTable(SalesHeader);
                                end;
                            Database::"Sales Invoice Header":
                                begin
                                    RecRef.Open(Database::"Sales Invoice Header");
                                    if SalesInvoiceHeader.Get(Rec."No.") then
                                        RecRef.GetTable(SalesInvoiceHeader);
                                end;
                            Database::"Sales Cr.Memo Header":
                                begin
                                    RecRef.Open(Database::"Sales Cr.Memo Header");
                                    if SalesCrMemoHeader.Get(Rec."No.") then
                                        RecRef.GetTable(SalesCrMemoHeader);
                                end;
                            Database::"Purchase Header":
                                begin
                                    RecRef.Open(Database::"Purchase Header");
                                    if PurchaseHeader.Get(Rec."Document Type", Rec."No.") then
                                        RecRef.GetTable(PurchaseHeader);
                                end;
                            Database::"Purch. Inv. Header":
                                begin
                                    RecRef.Open(Database::"Purch. Inv. Header");
                                    if PurchInvHeader.Get(Rec."No.") then
                                        RecRef.GetTable(PurchInvHeader);
                                end;
                            Database::"Purch. Cr. Memo Hdr.":
                                begin
                                    RecRef.Open(Database::"Purch. Cr. Memo Hdr.");
                                    if PurchCrMemoHdr.Get(Rec."No.") then
                                        RecRef.GetTable(PurchCrMemoHdr);
                                end;
                            Database::"VAT Report Header":
                                begin
                                    RecRef.Open(Database::"VAT Report Header");
                                    if VATReportHeader.Get(Rec."VAT Report Config. Code", Rec."No.") then
                                        RecRef.GetTable(VATReportHeader);
                                end;
                            Database::"Service Item":
                                begin
                                    RecRef.Open(Database::"Service Item");
                                    if ServiceItem.Get(Rec."No.") then
                                        RecRef.GetTable(ServiceItem);
                                end;
                            Database::"Service Header":
                                begin
                                    RecRef.Open(Database::"Service Header");
                                    if ServiceHeader.Get(Rec."Document Type", Rec."No.") then
                                        RecRef.GetTable(ServiceHeader);
                                end;
                            Database::"Service Line":
                                begin
                                    RecRef.Open(Database::"Service Line");
                                    if ServiceLine.Get(Rec."Document Type", Rec."No.", Rec."Line No.") then
                                        RecRef.GetTable(ServiceLine);
                                end;
                            Database::"Service Invoice Header":
                                begin
                                    RecRef.Open(Database::"Service Invoice Header");
                                    if ServiceInvoiceHeader.Get(Rec."No.") then
                                        RecRef.GetTable(ServiceInvoiceHeader);
                                end;
                            Database::"Service Cr.Memo Header":
                                begin
                                    RecRef.Open(Database::"Service Cr.Memo Header");
                                    if ServiceCrMemoHeader.Get(Rec."No.") then
                                        RecRef.GetTable(ServiceCrMemoHeader);
                                end;
                            Database::"Service Contract Header":
                                begin
                                    RecRef.Open(Database::"Service Contract Header");
                                    case Rec."Document Type" of
                                        Rec."Document Type"::"Service Contract":
                                            ServiceContractHeader."Contract Type" := ServiceContractHeader."Contract Type"::Contract;
                                        Rec."Document Type"::"Service Contract Quote":
                                            ServiceContractHeader."Contract Type" := ServiceContractHeader."Contract Type"::Quote;
                                    end;
                                    if ServiceContractHeader.Get(ServiceContractHeader."Contract Type", Rec."No.") then
                                        RecRef.GetTable(ServiceContractHeader);
                                end;
                            else
                                OnBeforeDrillDown(Rec, RecRef);
                        end;

                        DocumentAttachmentDetails.OpenForRecRef(RecRef);
                        OnBeforeDocumentAttachmentDetailsRunModal(Rec, RecRef, DocumentAttachmentDetails);
                        DocumentAttachmentDetails.RunModal();
                    end;
                }
            }
        }
    }

    actions
    {
    }

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDrillDown(DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeDocumentAttachmentDetailsRunModal(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef; var DocumentAttachmentDetails: Page "Document Attachment Details")
    begin
    end;

    trigger OnAfterGetCurrRecord()
    var
        CurrentFilterGroup: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnAfterGetCurrRecord(Rec, NumberOfRecords, IsHandled);
        if IsHandled then
            exit;
        CurrentFilterGroup := Rec.FilterGroup;
        Rec.FilterGroup := 4;

        NumberOfRecords := 0;
        if Rec.GetFilters() <> '' then begin
            if Evaluate(Rec."VAT Report Config. Code", Rec.GetFilter("VAT Report Config. Code")) then;
            NumberOfRecords := Rec.Count();
        end;
        Rec.FilterGroup := CurrentFilterGroup;
    end;

    var
        NumberOfRecords: Integer;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnAfterGetCurrRecord(var DocumentAttachment: Record "Document Attachment"; var AttachmentCount: Integer; var IsHandled: Boolean)
    begin
    end;
}

