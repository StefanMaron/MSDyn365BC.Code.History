namespace Microsoft.eServices.EDocument.IO.Peppol;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Formats;
using Microsoft.Peppol;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Peppol;
using Microsoft.Service.Document;
using Microsoft.Service.History;

codeunit 13921 "EDoc PEPPOL Validation DE"
{
    EventSubscriberInstance = Manual;

    var
        ValidationSalesHeader: Record "Sales Header";
        ValidationSourceTableNo: Integer;
        SkipVATRegNoCheck: Boolean;
        ScopeToDocument: Boolean;
        HasValidationDocument: Boolean;

    internal procedure Check(var SourceDocumentHeader: RecordRef; EDocumentService: Record "E-Document Service"; EDocumentProcessingPhase: Enum "E-Document Processing Phase")
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        EDocPEPPOLBIS30: Codeunit "EDoc PEPPOL BIS 3.0";
        ScopedValidation: Codeunit "EDoc PEPPOL Validation DE";
        PEPPOLValidation: Codeunit "PEPPOL Validation";
        PEPPOLServiceValidation: Codeunit "PEPPOL Service Validation";
    begin
        ScopedValidation.SetValidationContext(SourceDocumentHeader);
        BindSubscription(ScopedValidation);
        if not UsesDefaultValidation(SourceDocumentHeader.Number()) then begin
            EDocPEPPOLBIS30.Check(SourceDocumentHeader, EDocumentService, EDocumentProcessingPhase);
            exit;
        end;

        case SourceDocumentHeader.Number() of
            Database::"Sales Header":
                begin
                    SourceDocumentHeader.SetTable(SalesHeader);
                    PEPPOLValidation.Run(SalesHeader);
                end;
            Database::"Sales Invoice Header":
                begin
                    SourceDocumentHeader.SetTable(SalesInvoiceHeader);
                    PEPPOLValidation.CheckSalesInvoice(SalesInvoiceHeader);
                end;
            Database::"Sales Cr.Memo Header":
                begin
                    SourceDocumentHeader.SetTable(SalesCrMemoHeader);
                    PEPPOLValidation.CheckSalesCreditMemo(SalesCrMemoHeader);
                end;
            Database::"Service Header":
                begin
                    SourceDocumentHeader.SetTable(ServiceHeader);
                    PEPPOLServiceValidation.CheckServiceHeader(ServiceHeader);
                end;
            Database::"Service Invoice Header":
                begin
                    SourceDocumentHeader.SetTable(ServiceInvoiceHeader);
                    PEPPOLServiceValidation.CheckServiceInvoice(ServiceInvoiceHeader);
                end;
            Database::"Service Cr.Memo Header":
                begin
                    SourceDocumentHeader.SetTable(ServiceCrMemoHeader);
                    PEPPOLServiceValidation.CheckServiceCreditMemo(ServiceCrMemoHeader);
                end;
        end;
    end;

    local procedure UsesDefaultValidation(SourceTableNo: Integer): Boolean
    var
        PEPPOL30Setup: Record "PEPPOL 3.0 Setup";
    begin
        case SourceTableNo of
            Database::"Sales Header", Database::"Sales Invoice Header", Database::"Sales Cr.Memo Header":
                begin
                    PEPPOL30Setup.GetSetup();
                    exit(PEPPOL30Setup."PEPPOL 3.0 Sales Format" = PEPPOL30Setup."PEPPOL 3.0 Sales Format"::"PEPPOL 3.0 - Sales");
                end;
            Database::"Service Header", Database::"Service Invoice Header", Database::"Service Cr.Memo Header":
                begin
                    PEPPOL30Setup.GetSetup();
                    exit(PEPPOL30Setup."PEPPOL 3.0 Service Format" = PEPPOL30Setup."PEPPOL 3.0 Service Format"::"PEPPOL 3.0 - Service");
                end;
        end;
        exit(false);
    end;

    internal procedure SetValidationContext(SourceDocumentHeader: RecordRef)
    var
        EDocumentDEHelper: Codeunit "E-Document DE Helper";
    begin
        ScopeToDocument := true;
        ValidationSourceTableNo := SourceDocumentHeader.Number();
        HasValidationDocument := GetSalesHeader(SourceDocumentHeader, ValidationSalesHeader);
        SkipVATRegNoCheck := EDocumentDEHelper.HasRoutingNo(SourceDocumentHeader);
    end;

    local procedure GetSalesHeader(SourceDocumentHeader: RecordRef; var SalesHeader: Record "Sales Header"): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        PEPPOL30: Codeunit "PEPPOL30";
    begin
        Clear(SalesHeader);
        case SourceDocumentHeader.Number() of
            Database::"Sales Header":
                SourceDocumentHeader.SetTable(SalesHeader);
            Database::"Sales Invoice Header":
                begin
                    SourceDocumentHeader.SetTable(SalesInvoiceHeader);
                    SalesHeader.TransferFields(SalesInvoiceHeader);
                    SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
                end;
            Database::"Sales Cr.Memo Header":
                begin
                    SourceDocumentHeader.SetTable(SalesCrMemoHeader);
                    SalesHeader.TransferFields(SalesCrMemoHeader);
                    SalesHeader."Document Type" := SalesHeader."Document Type"::"Credit Memo";
                end;
            Database::"Service Header":
                begin
                    SourceDocumentHeader.SetTable(ServiceHeader);
                    PEPPOL30.TransferHeaderToSalesHeader(ServiceHeader, SalesHeader);
                    SalesHeader."Shipment Date" := SalesHeader."Posting Date";
                    SalesHeader."Sell-to E-Mail" := ServiceHeader."E-Mail";
                end;
            Database::"Service Invoice Header":
                begin
                    SourceDocumentHeader.SetTable(ServiceInvoiceHeader);
                    PEPPOL30.TransferHeaderToSalesHeader(ServiceInvoiceHeader, SalesHeader);
                    SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
                    SalesHeader."Shipment Date" := SalesHeader."Posting Date";
                    SalesHeader."Sell-to E-Mail" := ServiceInvoiceHeader."E-Mail";
                end;
            Database::"Service Cr.Memo Header":
                begin
                    SourceDocumentHeader.SetTable(ServiceCrMemoHeader);
                    PEPPOL30.TransferHeaderToSalesHeader(ServiceCrMemoHeader, SalesHeader);
                    SalesHeader."Document Type" := SalesHeader."Document Type"::"Credit Memo";
                    SalesHeader."Shipment Date" := SalesHeader."Posting Date";
                    SalesHeader."Sell-to E-Mail" := ServiceCrMemoHeader."E-Mail";
                end;
            else
                exit(false);
        end;
        exit(true);
    end;

    local procedure IsValidationDocument(SalesHeader: Record "Sales Header"): Boolean
    begin
        if not ScopeToDocument then
            exit(true);
        exit(HasValidationDocument and
            (SalesHeader."Document Type" = ValidationSalesHeader."Document Type") and
            (SalesHeader."No." = ValidationSalesHeader."No.") and
            (SalesHeader."Bill-to Customer No." = ValidationSalesHeader."Bill-to Customer No."));
    end;

#if not CLEAN29
#pragma warning disable AL0432
    var
        BuyerReference: Enum "E-Document Buyer Reference";

    [Obsolete('Use SetSkipVATRegNoCheck procedure instead.', '29.0')]
    procedure SetBuyerReference(NewBuyerReference: Enum "E-Document Buyer Reference")
    begin
        BuyerReference := NewBuyerReference;
    end;
#pragma warning restore AL0432
#endif

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"PEPPOL Management", 'OnAfterRecRefTransferFieldsOnTransferHeaderToSalesHeader', '', false, false)]
    local procedure TransferPostedServiceEmail(FromRecord: Variant; var ToRecord: Variant)
    var
        SourceSalesHeader: Record "Sales Header";
        SalesHeader: Record "Sales Header";
        SourceDocumentHeader: RecordRef;
    begin
        if not ScopeToDocument then
            exit;
        SourceDocumentHeader.GetTable(FromRecord);
        if SourceDocumentHeader.Number() <> ValidationSourceTableNo then
            exit;
        if not (SourceDocumentHeader.Number() in [Database::"Service Invoice Header", Database::"Service Cr.Memo Header"]) then
            exit;
        if not GetSalesHeader(SourceDocumentHeader, SourceSalesHeader) then
            exit;
        if not IsValidationDocument(SourceSalesHeader) then
            exit;

        // Service E-Mail and Sales Sell-to E-Mail have different field numbers.
        SalesHeader := ToRecord;
        SalesHeader."Sell-to E-Mail" := SourceSalesHeader."Sell-to E-Mail";
        ToRecord := SalesHeader;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"PEPPOL Validation", 'OnCheckSalesDocumentOnBeforeCheckCustomerVATRegNo', '', false, false)]
    local procedure SkipCustomerVATRegNoCheck(SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
        if not IsValidationDocument(SalesHeader) then
            exit;
        if SkipVATRegNoCheck then
            IsHandled := true;
#if not CLEAN29
#pragma warning disable AL0432
        if BuyerReference = BuyerReference::"Customer Reference" then
            IsHandled := true;
#pragma warning restore AL0432
#endif
    end;

    internal procedure SetSkipVATRegNoCheck(NewSkipVATRegNoCheck: Boolean)
    begin
        SkipVATRegNoCheck := NewSkipVATRegNoCheck;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"PEPPOL Validation", 'OnCheckSalesDocumentOnBeforeCheckYourReference', '', false, false)]
    local procedure SkipCheckOnCheckSalesDocumentOnBeforeCheckYourReference(SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
        if IsValidationDocument(SalesHeader) then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"PEPPOL Validation", 'OnAfterCheckSalesDocument', '', false, false)]
    local procedure OnAfterCheckSalesDocument(SalesHeader: Record "Sales Header")
    begin
        if IsValidationDocument(SalesHeader) then
            SalesHeader.TestField("Sell-to E-Mail");
    end;
}