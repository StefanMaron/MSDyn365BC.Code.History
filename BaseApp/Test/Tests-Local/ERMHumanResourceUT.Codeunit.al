codeunit 147202 "ERM Human Resource UT"
{
    // // [FEATURE] [UI] [UT]

    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;

    [Test]
    [HandlerFunctions('PostedPurchAdvanceReportsPageHandler')]
    [Scope('OnPrem')]
    procedure BuyFromVendorHistoryFactBox_PstdInvoicesQtyDrillDownPostedPurchAdvanceReports()
    var
        Vendor: Record Vendor;
        PurchInvHeader: Record "Purch. Inv. Header";
        ResponsibleEmployees: TestPage "Responsible Employees";
    begin
        // [FEATURE] [Employee] [Posted Purchase Invoice]
        // [SCENARIO 225488] "Buy From Vendor History" FactBox drilldown on "Pstd. Invoices" field opens Posted Purch. Advance Reports list for Responsible Employees.
        Initialize;

        MockVendorWithPurchInvHeader(Vendor, PurchInvHeader);
        UpdateVendorWithPurchInvoicHeaderForResponsibleEmployee(Vendor, PurchInvHeader);

        Vendor.SetRecFilter;

        ResponsibleEmployees.OpenView;
        ResponsibleEmployees.GotoRecord(Vendor);
        ResponsibleEmployees.Control1903435607."No. of Pstd. Invoices".DrillDown;

        VerifyVendorNoAndDocumentNo(Vendor."No.", PurchInvHeader."No.");
        LibraryVariableStorage.AssertEmpty;
    end;

    [Test]
    [HandlerFunctions('PostedPurchInvoicesPageHandler')]
    [Scope('OnPrem')]
    procedure BuyFromVendorHistoryFactBox_PstdInvoicesQtyDrillDownPostedPurchInvHeaders()
    var
        Vendor: Record Vendor;
        PurchInvHeader: Record "Purch. Inv. Header";
        Vendors: TestPage Vendors;
    begin
        // [FEATURE] [Employee] [Posted Purchase Invoice]
        // [SCENARIO 225488] "Buy From Vendor History" FactBox drilldown on "Pstd. Invoices" field opens Posted Purch. Advance Reports list for Vendors.
        Initialize;

        MockVendorWithPurchInvHeader(Vendor, PurchInvHeader);

        Vendor.SetRecFilter;
        Vendors.OpenView;
        Vendors.GotoRecord(Vendor);
        Vendors.Control1903435607."No. of Pstd. Invoices".DrillDown;

        VerifyVendorNoAndDocumentNo(Vendor."No.", PurchInvHeader."No.");
        LibraryVariableStorage.AssertEmpty;
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear;
    end;

    local procedure MockVendorWithPurchInvHeader(var Vendor: Record Vendor; var PurchInvHeader: Record "Purch. Inv. Header")
    begin
        with Vendor do begin
            Init;
            "No." := LibraryUtility.GenerateGUID;
            Insert;
        end;

        with PurchInvHeader do begin
            Init;
            "No." := LibraryUtility.GenerateGUID;
            "Buy-from Vendor No." := Vendor."No.";
            Insert;
        end;
    end;

    local procedure UpdateVendorWithPurchInvoicHeaderForResponsibleEmployee(var Vendor: Record Vendor; var PurchInvHeader: Record "Purch. Inv. Header")
    begin
        Vendor."Vendor Type" := Vendor."Vendor Type"::"Resp. Employee";
        Vendor.Modify;

        PurchInvHeader."Empl. Purchase" := true;
        PurchInvHeader.Modify;
    end;

    local procedure VerifyVendorNoAndDocumentNo(VendorNo: Code[20]; PurchInvDocNo: Code[20])
    begin
        Assert.AreEqual(PurchInvDocNo, LibraryVariableStorage.DequeueText, 'Purch Inv. Document "No." must match');
        Assert.AreEqual(VendorNo, LibraryVariableStorage.DequeueText, 'Vendor "No." must match');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchAdvanceReportsPageHandler(var PostedPurchAdvanceReports: TestPage "Posted Purch. Advance Reports")
    begin
        LibraryVariableStorage.Enqueue(Format(PostedPurchAdvanceReports."No.".Value));
        LibraryVariableStorage.Enqueue(Format(PostedPurchAdvanceReports."Buy-from Vendor No.".Value));
        PostedPurchAdvanceReports.Close;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchInvoicesPageHandler(var PostedPurchaseInvoices: TestPage "Posted Purchase Invoices")
    begin
        LibraryVariableStorage.Enqueue(Format(PostedPurchaseInvoices."No.".Value));
        LibraryVariableStorage.Enqueue(Format(PostedPurchaseInvoices."Buy-from Vendor No.".Value));
        PostedPurchaseInvoices.Close;
    end;
}

