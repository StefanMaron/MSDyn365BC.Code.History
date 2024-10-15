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
    begin
        SalesHeader.SetFilter("Rcvd.-from Count./Region Code", '<>%1', '');
        if not SalesHeader.IsEmpty() then
            exit;

        SalesHeader.Reset();
        SalesHeader.SetFilter("Rcvd-from Country/Region Code", '<>%1', '');
        if SalesHeader.FindSet() then
            repeat
                SalesHeader."Rcvd.-from Count./Region Code" := SalesHeader."Rcvd-from Country/Region Code";
                SalesHeader.Modify();
            until SalesHeader.Next() = 0;
    end;

    local procedure UpgradePostedSalesCreditMemos()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader.SetFilter("Rcvd.-from Count./Region Code", '<>%1', '');
        if not SalesCrMemoHeader.IsEmpty() then
            exit;

        SalesCrMemoHeader.Reset();
        SalesCrMemoHeader.SetFilter("Rcvd-from Country/Region Code", '<>%1', '');
        if SalesCrMemoHeader.FindSet() then
            repeat
                SalesCrMemoHeader."Rcvd.-from Count./Region Code" := SalesCrMemoHeader."Rcvd-from Country/Region Code";
                SalesCrMemoHeader.Modify();
            until SalesCrMemoHeader.Next() = 0;
    end;

    local procedure UpgradeReturnReceipts()
    var
        ReturnReceiptHeader: Record "Return Receipt Header";
    begin
        ReturnReceiptHeader.SetFilter("Rcvd.-from Count./Region Code", '<>%1', '');
        if not ReturnReceiptHeader.IsEmpty() then
            exit;

        ReturnReceiptHeader.Reset();
        ReturnReceiptHeader.SetFilter("Rcvd-from Country/Region Code", '<>%1', '');
        if ReturnReceiptHeader.FindSet() then
            repeat
                ReturnReceiptHeader."Rcvd.-from Count./Region Code" := ReturnReceiptHeader."Rcvd-from Country/Region Code";
                ReturnReceiptHeader.Modify();
            until ReturnReceiptHeader.Next() = 0;
    end;

    local procedure UpgradeSalesDocumentsArchive()
    var
        SalesHeaderArchive: Record "Sales Header Archive";
    begin
        SalesHeaderArchive.SetFilter("Rcvd.-from Count./Region Code", '<>%1', '');
        if not SalesHeaderArchive.IsEmpty() then
            exit;

        SalesHeaderArchive.Reset();
        SalesHeaderArchive.SetFilter("Rcvd-from Country/Region Code", '<>%1', '');
        if SalesHeaderArchive.FindSet() then
            repeat
                SalesHeaderArchive."Rcvd.-from Count./Region Code" := SalesHeaderArchive."Rcvd-from Country/Region Code";
                SalesHeaderArchive.Modify();
            until SalesHeaderArchive.Next() = 0;
    end;
}