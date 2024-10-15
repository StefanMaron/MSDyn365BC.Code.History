namespace Microsoft.EServices.EDocument;

using Microsoft.Sales.History;
using Microsoft.Service.History;
using Microsoft.Utilities;
using System.Reflection;

codeunit 1420 "Doc. Exch. Serv.- Doc. Status"
{

    trigger OnRun()
    begin
        CheckPostedInvoices();
        CheckPostedCrMemos();
        CheckPostedServiceInvoices();
        CheckPostedServiceCrMemos();
    end;

    var
        DocExchLinks: Codeunit "Doc. Exch. Links";
        UnSupportedTableTypeErr: Label 'The %1 table is not supported.', Comment = '%1 is the table.';
        CheckLatestQst: Label 'Do you want to check the latest status of the electronic document?', Comment = '%1 is Document Exchange Status';

    local procedure CheckPostedInvoices()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetFilter(
            "Document Exchange Status",
            StrSubstNo('%1|%2',
                SalesInvoiceHeader."Document Exchange Status"::"Sent to Document Exchange Service",
                SalesInvoiceHeader."Document Exchange Status"::"Pending Connection to Recipient"));
        if SalesInvoiceHeader.FindSet() then
            repeat
                DocExchLinks.CheckAndUpdateDocExchInvoiceStatus(SalesInvoiceHeader);
                Commit();
            until SalesInvoiceHeader.Next() = 0;
    end;

    local procedure CheckPostedCrMemos()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader.SetFilter(
            "Document Exchange Status",
            StrSubstNo('%1|%2',
                SalesCrMemoHeader."Document Exchange Status"::"Sent to Document Exchange Service",
                SalesCrMemoHeader."Document Exchange Status"::"Pending Connection to Recipient"));
        if SalesCrMemoHeader.FindSet() then
            repeat
                DocExchLinks.CheckAndUpdateDocExchCrMemoStatus(SalesCrMemoHeader);
                Commit();
            until SalesCrMemoHeader.Next() = 0;
    end;

    local procedure CheckPostedServiceInvoices()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceInvoiceHeader.SetFilter(
            "Document Exchange Status",
            StrSubstNo('%1|%2',
                ServiceInvoiceHeader."Document Exchange Status"::"Sent to Document Exchange Service",
                ServiceInvoiceHeader."Document Exchange Status"::"Pending Connection to Recipient"));
        if ServiceInvoiceHeader.FindSet() then
            repeat
                DocExchLinks.CheckAndUpdateDocExchServiceInvoiceStatus(ServiceInvoiceHeader);
                Commit();
            until ServiceInvoiceHeader.Next() = 0;
    end;

    local procedure CheckPostedServiceCrMemos()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        ServiceCrMemoHeader.SetFilter(
            "Document Exchange Status",
            StrSubstNo('%1|%2',
                ServiceCrMemoHeader."Document Exchange Status"::"Sent to Document Exchange Service",
                ServiceCrMemoHeader."Document Exchange Status"::"Pending Connection to Recipient"));
        if ServiceCrMemoHeader.FindSet() then
            repeat
                DocExchLinks.CheckAndUpdateDocExchServiceCrMemoStatus(ServiceCrMemoHeader);
                Commit();
            until ServiceCrMemoHeader.Next() = 0;
    end;

    local procedure CheckAndUpdateDocExchStatus(DocRecRef: RecordRef)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        DocExchLinks: Codeunit "Doc. Exch. Links";
    begin
        case DocRecRef.Number of
            DATABASE::"Sales Invoice Header":
                begin
                    DocRecRef.SetTable(SalesInvoiceHeader);
                    DocExchLinks.CheckAndUpdateDocExchInvoiceStatus(SalesInvoiceHeader);
                end;
            DATABASE::"Sales Cr.Memo Header":
                begin
                    DocRecRef.SetTable(SalesCrMemoHeader);
                    DocExchLinks.CheckAndUpdateDocExchCrMemoStatus(SalesCrMemoHeader);
                end;
            DATABASE::"Service Invoice Header":
                begin
                    DocRecRef.SetTable(ServiceInvoiceHeader);
                    DocExchLinks.CheckAndUpdateDocExchServiceInvoiceStatus(ServiceInvoiceHeader);
                end;
            DATABASE::"Service Cr.Memo Header":
                begin
                    DocRecRef.SetTable(ServiceCrMemoHeader);
                    DocExchLinks.CheckAndUpdateDocExchServiceCrMemoStatus(ServiceCrMemoHeader);
                end;
            else
                Error(UnSupportedTableTypeErr, DocRecRef.Number);
        end;
    end;

    procedure DocExchStatusDrillDown(DocRecVariant: Variant)
    var
        DataTypeManagement: Codeunit "Data Type Management";
        DocRecRef: RecordRef;
        Handled: Boolean;
    begin
        if not DataTypeManagement.GetRecordRef(DocRecVariant, DocRecRef) then
            exit;
        OnDocExchStatusDrillDown(DocRecRef, Handled);
        if not Handled then
            DefaultDocExchStatusDrillDown(DocRecRef);
    end;

    local procedure DefaultDocExchStatusDrillDown(var DocRecRef: RecordRef)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ActivityLog: Record "Activity Log";
        DataTypeManagement: Codeunit "Data Type Management";
        TypeHelper: Codeunit "Type Helper";
        DocExchServiceMgt: Codeunit "Doc. Exch. Service Mgt.";
        StatusFieldRef: FieldRef;
        IdentifierFieldRef: FieldRef;
        Options: Text;
        DocExchIdentifier: Text;
        DocExchStatus: Integer;
    begin
        if not IsSupportedByDefaultDocExchStatusDrillDown(DocRecRef) then
            exit;
        DataTypeManagement.FindFieldByName(DocRecRef, StatusFieldRef, 'Document Exchange Status');
        Options := StatusFieldRef.OptionMembers;
        DocExchStatus := StatusFieldRef.Value();
        case DocExchStatus of
            TypeHelper.GetOptionNo(Format(SalesInvoiceHeader."Document Exchange Status"::"Not Sent"), Options):
                exit;
            TypeHelper.GetOptionNo(Format(SalesInvoiceHeader."Document Exchange Status"::"Sent to Document Exchange Service"), Options),
          TypeHelper.GetOptionNo(Format(SalesInvoiceHeader."Document Exchange Status"::"Pending Connection to Recipient"), Options):
                if Confirm(CheckLatestQst, true) then
                    CheckAndUpdateDocExchStatus(DocRecRef);
            TypeHelper.GetOptionNo(Format(SalesInvoiceHeader."Document Exchange Status"::"Delivered to Recipient"), Options):
                begin
                    DataTypeManagement.FindFieldByName(DocRecRef, IdentifierFieldRef, 'Document Exchange Identifier');
                    DocExchIdentifier := IdentifierFieldRef.Value();
                    HyperLink(DocExchServiceMgt.GetExternalDocURL(DocExchIdentifier));
                    exit;
                end;
        end;
        ActivityLog.ShowEntries(DocRecRef.RecordId);
    end;

    local procedure IsSupportedByDefaultDocExchStatusDrillDown(DocRecRef: RecordRef): Boolean
    begin
        exit(DocRecRef.Number in [DATABASE::"Sales Invoice Header", DATABASE::"Sales Cr.Memo Header",
                                  DATABASE::"Service Invoice Header", DATABASE::"Service Cr.Memo Header"]);
    end;

    [IntegrationEvent(false, false)]
    procedure OnDocExchStatusDrillDown(var DocRecRef: RecordRef; var Handled: Boolean)
    begin
    end;
}

