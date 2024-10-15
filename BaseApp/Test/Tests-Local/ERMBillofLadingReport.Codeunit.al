codeunit 144722 "ERM Bill of Lading Report"
{
    // // [FEATURE] [Report] [Bill of Lading]

    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesSetupReportTemplate()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 377117] Verify SalesReceivablesSetup."Bill of Lading Template Code" <> ''
        SalesReceivablesSetup.Get;
        Assert.AreNotEqual(
          '',
          SalesReceivablesSetup."Bill of Lading Template Code",
          SalesReceivablesSetup.FieldCaption("Bill of Lading Template Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestReportExport()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 377117] Export "Bill of Lading" Excel for an open Sales Invoice

        CreateReleaseSalesInvoice(SalesHeader);
        SalesHeader.SetRange("No.", SalesHeader."No.");

        RunReport(SalesHeader);
    end;

    local procedure CreateReleaseSalesInvoice(var SalesHeader: Record "Sales Header")
    begin
        LibrarySales.CreateSalesInvoice(SalesHeader);
        with SalesHeader do begin
            "Location Code" := CreateLocationCode;
            "Shipping Agent Code" := CreateShippingAgentCode;
            Modify;
        end;
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateLocationCode(): Code[10]
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocation(Location);
        with Location do begin
            "Country/Region Code" := CreateCountryRegionCode;
            "Post Code" := LibraryUtility.GenerateGUID;
            City := LibraryUtility.GenerateGUID;
            Address := LibraryUtility.GenerateGUID;
            "Address 2" := LibraryUtility.GenerateGUID;
            Modify;
            exit(Code);
        end;
    end;

    local procedure CreateCountryRegionCode(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        with CountryRegion do begin
            "Local Name" := LibraryUtility.GenerateGUID;
            Modify;
            exit(Code);
        end;
    end;

    local procedure CreateShippingAgentCode(): Code[10]
    var
        ShippingAgent: Record "Shipping Agent";
    begin
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        with ShippingAgent do begin
            Name := LibraryUtility.GenerateGUID;
            Modify;
            exit(Code);
        end;
    end;

    local procedure RunReport(var SalesHeader: Record "Sales Header")
    var
        BillOfLading: Report "Bill of Lading";
    begin
        BillOfLading.SetTestMode(true);
        BillOfLading.UseRequestPage(false);
        BillOfLading.SetTableView(SalesHeader);
        BillOfLading.Run;
    end;
}

