// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

using Microsoft.Integration.Graph;
using Microsoft.Sales.Archive;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.Environment;
using System.Upgrade;

codeunit 104052 "Upgrade Rcvd. Country Code"
{
    Permissions = TableData "Return Receipt Header" = rm,
                  TableData "Sales Header Archive" = rm,
                  TableData "Sales Cr.Memo Header" = rm;

    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    var
        HybridDeployment: Codeunit "Hybrid Deployment";
        DisableAggregateTableUpdate: Codeunit "Disable Aggregate Table Update";
    begin
        if not HybridDeployment.VerifyCanStartUpgrade(CompanyName()) then
            exit;

        DisableAggregateTableUpdate.SetDisableAllRecords(true);
        BindSubscription(DisableAggregateTableUpdate);
        UpdateData();
    end;

    procedure UpdateData();
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetReceivedFromCountryCodeUpgradeTag()) then
            exit;

        UpgradeUnpostedSalesDocuments();
        UpgradePostedSalesCreditMemos();
        UpgradeReturnReceipts();
        UpgradeSalesDocumentsArchive();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetReceivedFromCountryCodeUpgradeTag());
    end;

    local procedure UpgradeUnpostedSalesDocuments()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderDataTransfer: DataTransfer;
    begin
        SalesHeader.SetFilter("Rcvd.-from Count./Region Code", '<>%1', '');
        if not SalesHeader.IsEmpty() then
            exit;

        SalesHeaderDataTransfer.SetTables(Database::"Sales Header", Database::"Sales Header");
        SalesHeaderDataTransfer.AddSourceFilter(SalesHeader.FieldNo("Rcvd-from Country/Region Code"), '<>%1', '');
        SalesHeaderDataTransfer.AddFieldValue(SalesHeader.FieldNo("Rcvd-from Country/Region Code"), SalesHeader.FieldNo("Rcvd.-from Count./Region Code"));
        SalesHeaderDataTransfer.UpdateAuditFields := false;
        SalesHeaderDataTransfer.CopyFields();
    end;

    local procedure UpgradePostedSalesCreditMemos()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoHeaderDataTransfer: DataTransfer;
    begin
        SalesCrMemoHeader.SetFilter("Rcvd.-from Count./Region Code", '<>%1', '');
        if not SalesCrMemoHeader.IsEmpty() then
            exit;

        SalesCrMemoHeaderDataTransfer.SetTables(Database::"Sales Cr.Memo Header", Database::"Sales Cr.Memo Header");
        SalesCrMemoHeaderDataTransfer.AddSourceFilter(SalesCrMemoHeader.FieldNo("Rcvd-from Country/Region Code"), '<>%1', '');
        SalesCrMemoHeaderDataTransfer.AddFieldValue(SalesCrMemoHeader.FieldNo("Rcvd-from Country/Region Code"), SalesCrMemoHeader.FieldNo("Rcvd.-from Count./Region Code"));
        SalesCrMemoHeaderDataTransfer.UpdateAuditFields := false;
        SalesCrMemoHeaderDataTransfer.CopyFields();
    end;

    local procedure UpgradeReturnReceipts()
    var
        ReturnReceiptHeader: Record "Return Receipt Header";
        ReturnReceiptHeaderDataTransfer: DataTransfer;
    begin
        ReturnReceiptHeader.SetFilter("Rcvd.-from Count./Region Code", '<>%1', '');
        if not ReturnReceiptHeader.IsEmpty() then
            exit;

        ReturnReceiptHeaderDataTransfer.SetTables(Database::"Return Receipt Header", Database::"Return Receipt Header");
        ReturnReceiptHeaderDataTransfer.AddSourceFilter(ReturnReceiptHeader.FieldNo("Rcvd-from Country/Region Code"), '<>%1', '');
        ReturnReceiptHeaderDataTransfer.AddFieldValue(ReturnReceiptHeader.FieldNo("Rcvd-from Country/Region Code"), ReturnReceiptHeader.FieldNo("Rcvd.-from Count./Region Code"));
        ReturnReceiptHeaderDataTransfer.UpdateAuditFields := false;
        ReturnReceiptHeaderDataTransfer.CopyFields();
    end;

    local procedure UpgradeSalesDocumentsArchive()
    var
        SalesHeaderArchive: Record "Sales Header Archive";
        SalesHeaderArchiveDataTransfer: DataTransfer;
    begin
        SalesHeaderArchive.SetFilter("Rcvd.-from Count./Region Code", '<>%1', '');
        if not SalesHeaderArchive.IsEmpty() then
            exit;

        SalesHeaderArchiveDataTransfer.SetTables(Database::"Sales Header Archive", Database::"Sales Header Archive");
        SalesHeaderArchiveDataTransfer.AddSourceFilter(SalesHeaderArchive.FieldNo("Rcvd-from Country/Region Code"), '<>%1', '');
        SalesHeaderArchiveDataTransfer.AddFieldValue(SalesHeaderArchive.FieldNo("Rcvd-from Country/Region Code"), SalesHeaderArchive.FieldNo("Rcvd.-from Count./Region Code"));
        SalesHeaderArchiveDataTransfer.UpdateAuditFields := false;
        SalesHeaderArchiveDataTransfer.CopyFields();
    end;
}