codeunit 441 "Prepayment Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        JobQueueEntryHasStartedTxt: Label 'A job for changing the status from Pending Prepayment to Release has started with the frequency %1.', Comment = '%1 - job queue frequency';
        StatusOfSalesOrderIsChangedTxt: Label 'The status of the sales order %1 is changed from Pending Prepayment to Release.', Comment = '%1 - sales order no.';
        StatusOfPurchaseOrderIsChangedTxt: Label 'The status of the purchase order %1 is changed from Pending Prepayment to Release.', Comment = '%1 - purchase order no.';
        UpdateSalesOrderStatusTxt: Label 'Update sales order status.';
        UpdatePurchaseOrderStatusTxt: Label 'Update purchase order status.';

    procedure SetSalesPrepaymentPct(var SalesLine: Record "Sales Line"; Date: Date)
    var
        Cust: Record Customer;
        SalesPrepaymentPct: Record "Sales Prepayment %";
    begin
        with SalesPrepaymentPct do begin
            if (SalesLine.Type <> SalesLine.Type::Item) or (SalesLine."No." = '') or
               (SalesLine."Document Type" <> SalesLine."Document Type"::Order)
            then
                exit;
            SetFilter("Starting Date", '..%1', Date);
            SetFilter("Ending Date", '%1|>=%2', 0D, Date);
            SetRange("Item No.", SalesLine."No.");
            for "Sales Type" := "Sales Type"::Customer to "Sales Type"::"All Customers" do begin
                SetRange("Sales Type", "Sales Type");
                case "Sales Type" of
                    "Sales Type"::Customer:
                        begin
                            SetRange("Sales Code", SalesLine."Bill-to Customer No.");
                            if ApplySalesPrepaymentPct(SalesLine, SalesPrepaymentPct) then
                                exit;
                        end;
                    "Sales Type"::"Customer Price Group":
                        begin
                            Cust.Get(SalesLine."Bill-to Customer No.");
                            if Cust."Customer Price Group" <> '' then
                                SetRange("Sales Code", Cust."Customer Price Group");
                            if ApplySalesPrepaymentPct(SalesLine, SalesPrepaymentPct) then
                                exit;
                        end;
                    "Sales Type"::"All Customers":
                        begin
                            SetRange("Sales Code");
                            if ApplySalesPrepaymentPct(SalesLine, SalesPrepaymentPct) then
                                exit;
                        end;
                end;
            end;
        end;
    end;

    local procedure ApplySalesPrepaymentPct(var SalesLine: Record "Sales Line"; var SalesPrepaymentPct: Record "Sales Prepayment %"): Boolean
    begin
        with SalesPrepaymentPct do
            if FindLast then begin
                SalesLine."Prepayment %" := "Prepayment %";
                exit(true);
            end;
    end;

    procedure SetPurchPrepaymentPct(var PurchLine: Record "Purchase Line"; Date: Date)
    var
        PurchPrepaymentPct: Record "Purchase Prepayment %";
    begin
        with PurchPrepaymentPct do begin
            if (PurchLine.Type <> PurchLine.Type::Item) or (PurchLine."No." = '') or
               (PurchLine."Document Type" <> PurchLine."Document Type"::Order)
            then
                exit;
            SetFilter("Starting Date", '..%1', Date);
            SetFilter("Ending Date", '%1|>=%2', 0D, Date);
            SetRange("Item No.", PurchLine."No.");
            SetRange("Vendor No.", PurchLine."Pay-to Vendor No.");
            if ApplyPurchPrepaymentPct(PurchLine, PurchPrepaymentPct) then
                exit;

            // All Vendors
            SetRange("Vendor No.", '');
            if ApplyPurchPrepaymentPct(PurchLine, PurchPrepaymentPct) then
                exit;
        end;
    end;

    local procedure ApplyPurchPrepaymentPct(var PurchLine: Record "Purchase Line"; var PurchPrepaymentPct: Record "Purchase Prepayment %"): Boolean
    begin
        with PurchPrepaymentPct do
            if FindLast then begin
                PurchLine."Prepayment %" := "Prepayment %";
                exit(true);
            end;
    end;

    procedure TestSalesPrepayment(SalesHeader: Record "Sales Header"): Boolean
    var
        SalesLine: Record "Sales Line";
        IsHandled: Boolean;
        TestResult: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestSalesPrepayment(SalesHeader, TestResult, IsHandled);
        if IsHandled then
            exit(TestResult);

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet then
            repeat
                if SalesLine."Prepmt. Line Amount" <> 0 then
                    if SalesLine."Prepmt. Amt. Inv." <> SalesLine."Prepmt. Line Amount" then
                        exit(true);
            until SalesLine.Next = 0;
    end;

    procedure TestPurchasePrepayment(PurchaseHeader: Record "Purchase Header"): Boolean
    var
        PurchaseLine: Record "Purchase Line";
        IsHandled: Boolean;
        TestResult: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestPurchPrepayment(PurchaseHeader, TestResult, IsHandled);
        if IsHandled then
            exit(TestResult);

        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetFilter("Prepmt. Line Amount", '<>%1', 0);
        if PurchaseLine.FindSet then
            repeat
                if PurchaseLine."Prepmt. Amt. Inv." <> PurchaseLine."Prepmt. Line Amount" then
                    exit(true);
            until PurchaseLine.Next = 0;
    end;

    procedure TestSalesPayment(SalesHeader: Record "Sales Header"): Boolean
    var
        SalesSetup: Record "Sales & Receivables Setup";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesInvHeader: Record "Sales Invoice Header";
    begin
        SalesSetup.Get();
        if not SalesSetup."Check Prepmt. when Posting" then
            exit(false);

        SalesInvHeader.SetCurrentKey("Prepayment Order No.", "Prepayment Invoice");
        SalesInvHeader.SetRange("Prepayment Order No.", SalesHeader."No.");
        SalesInvHeader.SetRange("Prepayment Invoice", true);
        if SalesInvHeader.FindSet then
            repeat
                CustLedgerEntry.SetCurrentKey("Document No.");
                CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
                CustLedgerEntry.SetRange("Document No.", SalesInvHeader."No.");
                CustLedgerEntry.SetFilter("Remaining Amt. (LCY)", '<>%1', 0);
                if not CustLedgerEntry.IsEmpty then
                    exit(true);
            until SalesInvHeader.Next = 0;

        exit(false);
    end;

    procedure TestPurchasePayment(PurchaseHeader: Record "Purchase Header"): Boolean
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchasesPayablesSetup.Get();
        if not PurchasesPayablesSetup."Check Prepmt. when Posting" then
            exit(false);

        PurchInvHeader.SetCurrentKey("Prepayment Order No.", "Prepayment Invoice");
        PurchInvHeader.SetRange("Prepayment Order No.", PurchaseHeader."No.");
        PurchInvHeader.SetRange("Prepayment Invoice", true);
        if PurchInvHeader.FindSet then
            repeat
                VendLedgerEntry.SetCurrentKey("Document No.");
                VendLedgerEntry.SetRange("Document Type", VendLedgerEntry."Document Type"::Invoice);
                VendLedgerEntry.SetRange("Document No.", PurchInvHeader."No.");
                VendLedgerEntry.SetFilter("Remaining Amt. (LCY)", '<>%1', 0);
                if not VendLedgerEntry.IsEmpty then
                    exit(true);
            until PurchInvHeader.Next = 0;

        exit(false);
    end;

    procedure UpdatePendingPrepaymentSales()
    var
        SalesHeader: Record "Sales Header";
        PrepaymentMgt: Codeunit "Prepayment Mgt.";
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange(Status, SalesHeader.Status::"Pending Prepayment");
        if SalesHeader.FindSet(true) then
            repeat
                if not PrepaymentMgt.TestSalesPayment(SalesHeader) then begin
                    CODEUNIT.Run(CODEUNIT::"Release Sales Document", SalesHeader);
                    if SalesHeader.Status = SalesHeader.Status::Released then
                        SendTraceTag(
                          '0000254', UpdateSalesOrderStatusTxt, VERBOSITY::Normal,
                          StrSubstNo(StatusOfSalesOrderIsChangedTxt, Format(SalesHeader."No.")), DATACLASSIFICATION::CustomerContent);
                end;
            until SalesHeader.Next = 0;
    end;

    procedure UpdatePendingPrepaymentPurchase()
    var
        PurchaseHeader: Record "Purchase Header";
        PrepaymentMgt: Codeunit "Prepayment Mgt.";
    begin
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange(Status, PurchaseHeader.Status::"Pending Prepayment");
        if PurchaseHeader.FindSet(true) then
            repeat
                if not PrepaymentMgt.TestPurchasePayment(PurchaseHeader) then begin
                    CODEUNIT.Run(CODEUNIT::"Release Purchase Document", PurchaseHeader);
                    if PurchaseHeader.Status = PurchaseHeader.Status::Released then
                        SendTraceTag(
                          '0000255', UpdatePurchaseOrderStatusTxt, VERBOSITY::Normal,
                          StrSubstNo(StatusOfPurchaseOrderIsChangedTxt, Format(PurchaseHeader."No.")), DATACLASSIFICATION::CustomerContent);
                end;
            until PurchaseHeader.Next = 0;
    end;

    procedure CreateAndStartJobQueueEntrySales(UpdateFrequency: Option Never,Daily,Weekly)
    begin
        CreateAndStartJobQueueEntry(
          CODEUNIT::"Upd. Pending Prepmt. Sales", UpdateFrequency, UpdateSalesOrderStatusTxt);
    end;

    procedure CreateAndStartJobQueueEntryPurchase(UpdateFrequency: Option Never,Daily,Weekly)
    begin
        CreateAndStartJobQueueEntry(
          CODEUNIT::"Upd. Pending Prepmt. Purchase", UpdateFrequency, UpdatePurchaseOrderStatusTxt);
    end;

    procedure CreateAndStartJobQueueEntry(CodeunitID: Integer; UpdateFrequency: Option Never,Daily,Weekly; Category: Text)
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueManagement: Codeunit "Job Queue Management";
    begin
        JobQueueManagement.DeleteJobQueueEntries(JobQueueEntry."Object Type to Run"::Codeunit, CodeunitID);

        JobQueueEntry."No. of Minutes between Runs" := UpdateFrequencyToNoOfMinutes(UpdateFrequency);
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CodeunitID;
        JobQueueManagement.CreateJobQueueEntry(JobQueueEntry);

        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);
        SendTraceTag(
          '0000256', Category, VERBOSITY::Normal,
          StrSubstNo(JobQueueEntryHasStartedTxt, Format(UpdateFrequency)), DATACLASSIFICATION::SystemMetadata);
    end;

    local procedure UpdateFrequencyToNoOfMinutes(UpdateFrequency: Option Never,Daily,Weekly): Integer
    begin
        case UpdateFrequency of
            UpdateFrequency::Never:
                exit(0);
            UpdateFrequency::Daily:
                exit(60 * 24);
            UpdateFrequency::Weekly:
                exit(60 * 24 * 7);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestSalesPrepayment(SalesHeader: Record "Sales Header"; var TestResult: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestPurchPrepayment(PurchHeader: Record "Purchase Header"; var TestResult: Boolean; var IsHandled: Boolean)
    begin
    end;
}

