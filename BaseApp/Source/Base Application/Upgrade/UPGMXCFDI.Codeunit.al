codeunit 104151 "UPG. MX CFDI"
{
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    var
        HybridDeployment: Codeunit "Hybrid Deployment";
    begin
        if not HybridDeployment.VerifyCanStartUpgrade(CompanyName()) then
            exit;
         
        UpdateSATCatalogs;
        UpdateCFDIFields;
        UpdateCFDIEnabled();
        UpgradePACWebServiceDetails();
        UpgradeSATAddress();
    end;

    local procedure UpdateSATCatalogs()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetSATPaymentCatalogsSwapTag()) then
            exit;

        Codeunit.Run(Codeunit::"Update SAT Payment Catalogs");

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetSATPaymentCatalogsSwapTag());
    end;

    local procedure UpdateCFDIFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetCFDIPurposeRelationFieldsDocUpdateTag()) then
            exit;

        Codeunit.Run(Codeunit::"Update CFDI Fields Sales Doc");

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetCFDIPurposeRelationFieldsDocUpdateTag());
    end;

    local procedure UpdateCFDIEnabled()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetCFDIEnableOptionUpgradeTag()) then
            exit;

        if GeneralLedgerSetup.Get() then begin
            GeneralLedgerSetup."CFDI Enabled" :=
                GeneralLedgerSetup."PAC Environment" in [GeneralLedgerSetup."PAC Environment"::Test, GeneralLedgerSetup."PAC Environment"::Production];
            GeneralLedgerSetup.Modify();
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetCFDIEnableOptionUpgradeTag());
    end;

    local procedure UpgradePACWebServiceDetails()
    var
        SATUtilities: Codeunit "SAT Utilities";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetPACWebServiceDetailsUpgradeTag()) then
            exit;

        SATUtilities.PopulatePACWebServiceData();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetPACWebServiceDetailsUpgradeTag());
    end;

    local procedure UpgradeSATAddress()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetSATAddressUpgradeTag()) then
            exit;

        UpdateLocations();
        UpdateSalesDocuments();
        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetSATAddressUpgradeTag());
    end;

    local procedure UpdateLocations()
    var
        Location: Record "Location";
    begin
        Location.SetFilter("Country/Region Code", '<>%1', '');
        Location.SetFilter("SAT State Code", '<>%1', '');
        Location.SetFilter("SAT Municipality Code", '<>%1', '');
        Location.SetFilter("SAT Locality Code", '<>%1', '');
        Location.SetFilter("SAT Suburb ID", '<>0');
        if Location.FindSet() then
            repeat
                Location."SAT Address ID" := InsertSATAddress(Location);
                if Location.Modify() then;
            until Location.Next() = 0;
    end;

    local procedure InsertSATAddress(Location: Record "Location"): Integer
    var
        SATAddress: Record "SAT Address";
    begin
        SATAddress."Country/Region Code" := Location."Country/Region Code";
        SATAddress."SAT State Code" := Location."SAT State Code";
        SATAddress."SAT Municipality Code" := Location."SAT Municipality Code";
        SATAddress."SAT Locality Code" := Location."SAT Locality Code";
        SATAddress."SAT Suburb ID" := Location."SAT Suburb ID";
        if SATAddress.Insert() then;
        exit(SATAddress.Id);
    end;

    local procedure UpdateSalesDocuments()
    var
        Location: Record "Location";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        Location.SetFilter("SAT Address ID", '<>0');
        if Location.FindSet() then
            repeat
                SalesHeader.SetRange("Transit-to Location",Location.Code);
                SalesHeader.ModifyAll("SAT Address ID",Location."SAT Address ID");

                SalesInvoiceHeader.SetRange("Transit-to Location",Location.Code);
                SalesInvoiceHeader.SetFilter(
                    "Electronic Document Status",'%1|%2',
                    SalesInvoiceHeader."Electronic Document Status"::" ",SalesInvoiceHeader."Electronic Document Status"::"Stamp Request Error");
                SalesInvoiceHeader.ModifyAll("SAT Address ID",Location."SAT Address ID");

                SalesShipmentHeader.SetRange("Transit-to Location",Location.Code);
                SalesShipmentHeader.SetFilter(
                    "Electronic Document Status",'%1|%2',
                    SalesShipmentHeader."Electronic Document Status"::" ",SalesShipmentHeader."Electronic Document Status"::"Stamp Request Error");
                SalesShipmentHeader.ModifyAll("SAT Address ID",Location."SAT Address ID");
            until Location.Next() = 0;
    end;
}

