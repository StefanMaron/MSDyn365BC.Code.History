// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using Microsoft.Sales.Customer;
using Microsoft.Service.Document;
using Microsoft.Service.History;

codeunit 6463 "Serv. Report Distribution Mgt."
{
    var
        ServiceInvoiceDocTypeTxt: Label 'Service Invoice';
        ServiceCrMemoDocTypeTxt: Label 'Service Credit Memo';
        ServiceQuoteDocTypeTxt: Label 'Service Quote';
        ServiceOrderDocTypeTxt: Label 'Service Order';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Report Distribution Management", 'OnGetFullDocumentTypeTextElseCase', '', false, false)]
    local procedure OnGetFullDocumentTypeTextElseCase(DocumentRecordRef: RecordRef; var DocumentTypeText: Text[50])
    var
        ServiceHeader: Record "Service Header";
    begin
        case DocumentRecordRef.Number of
            DATABASE::"Service Invoice Header":
                DocumentTypeText := ServiceInvoiceDocTypeTxt;
            DATABASE::"Service Cr.Memo Header":
                DocumentTypeText := ServiceCrMemoDocTypeTxt;
            DATABASE::"Service Header":
                begin
                    DocumentRecordRef.SetTable(ServiceHeader);
                    case ServiceHeader."Document Type" of
                        ServiceHeader."Document Type"::Invoice:
                            DocumentTypeText := ServiceInvoiceDocTypeTxt;
                        ServiceHeader."Document Type"::"Credit Memo":
                            DocumentTypeText := ServiceCrMemoDocTypeTxt;
                        ServiceHeader."Document Type"::Quote:
                            DocumentTypeText := ServiceQuoteDocTypeTxt;
                        ServiceHeader."Document Type"::Order:
                            DocumentTypeText := ServiceOrderDocTypeTxt;
                    end;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Report Distribution Management", 'OnGetDocumentLanguageCodeCaseElse', '', false, false)]
    local procedure OnGetDocumentLanguageCodeCaseElse(DocumentRecordRef: RecordRef; var LanguageCode: Code[10])
    var
        ServiceHeader: Record "Service Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        case DocumentRecordRef.Number of
            DATABASE::"Service Invoice Header":
                begin
                    DocumentRecordRef.SetTable(ServiceInvoiceHeader);
                    LanguageCode := ServiceInvoiceHeader."Language Code";
                end;
            DATABASE::"Service Cr.Memo Header":
                begin
                    DocumentRecordRef.SetTable(ServiceCrMemoHeader);
                    LanguageCode := ServiceCrMemoHeader."Language Code";
                end;
            DATABASE::"Service Header":
                begin
                    DocumentRecordRef.SetTable(ServiceHeader);
                    LanguageCode := ServiceHeader."Language Code";
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Report Distribution Management", 'OnAfterGetBillToCustomer', '', false, false)]
    local procedure OnAfterGetBillToCustomer(var Customer: Record Customer; DocumentVariant: Variant; DocumentRecordRef: RecordRef)
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceHeader: Record "Service Header";
    begin
        DocumentRecordRef.GetTable(DocumentVariant);
        case DocumentRecordRef.Number of
            DATABASE::"Service Invoice Header":
                begin
                    ServiceInvoiceHeader := DocumentVariant;
                    Customer.Get(ServiceInvoiceHeader."Bill-to Customer No.");
                end;
            DATABASE::"Service Cr.Memo Header":
                begin
                    ServiceCrMemoHeader := DocumentVariant;
                    Customer.Get(ServiceCrMemoHeader."Bill-to Customer No.");
                end;
            DATABASE::"Service Header":
                begin
                    ServiceHeader := DocumentVariant;
                    Customer.Get(ServiceHeader."Bill-to Customer No.");
                end;
        end;
    end;

    procedure RunDefaultCheckServiceElectronicDocument(ServiceHeader: Record "Service Header")
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ReportDistributionManagement: Codeunit "Report Distribution Management";
        ServElectDocumentFormat: Codeunit "Serv. Electr. Doc. Format";
    begin
        ReportDistributionManagement.GetElectronicDocumentFormat(ElectronicDocumentFormat, ServiceHeader);
        ServElectDocumentFormat.ValidateElectronicServiceDocument(ServiceHeader, ElectronicDocumentFormat.Code);
    end;
}
