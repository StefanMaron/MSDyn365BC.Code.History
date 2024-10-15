#if not CLEAN19
codeunit 11706 "Issue Payment Order"
{
    Permissions = TableData "Issued Payment Order Header" = im,
                  TableData "Issued Payment Order Line" = im;
    TableNo = "Payment Order Header";
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
    ObsoleteTag = '19.0';

    trigger OnRun()
    begin
        PmtOrdHdr.Copy(Rec);
        Code();
        Rec := PmtOrdHdr;
    end;

    var
        BankAccount: Record "Bank Account";
        PmtOrdHdr: Record "Payment Order Header";
        PaymentOrderManagement: Codeunit "Payment Order Management";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        ApprovalProcessReopenErr: Label 'The approval process must be cancelled or completed to reopen this document.';

    local procedure "Code"()
    var
        PmtOrdLn: Record "Payment Order Line";
        IssuedPmtOrdHdr: Record "Issued Payment Order Header";
        IssuedPmtOrdLn: Record "Issued Payment Order Line";
        NoSeriesMgt: Codeunit NoSeriesManagement;
    begin
        with PmtOrdHdr do begin
            OnBeforeIssuePaymentOrder(PmtOrdHdr);
            OnCheckPaymentOrderIssueRestrictions();

            TestField("Bank Account No.");
            TestField("Document Date");
            BankAccount.Get("Bank Account No.");
            BankAccount.TestField(Blocked, false);

            SetPaymentOrderLineFilters(PmtOrdLn, PmtOrdHdr);

            if PmtOrdLn.IsEmpty() then
                Error(DocumentErrorsMgt.GetNothingToPostErrorMsg());

            CheckPaymentOrderLines(PmtOrdHdr);

            OnCodeOnAfterCheck(PmtOrdHdr);

            PmtOrdLn.LockTable();
            if PmtOrdLn.FindLast() then;

            // insert header
            IssuedPmtOrdHdr.Init();
            IssuedPmtOrdHdr.TransferFields(PmtOrdHdr);
            BankAccount.TestField("Issued Payment Order Nos.");
            if BankAccount."Issued Payment Order Nos." <> "No. Series" then
                IssuedPmtOrdHdr."No." := NoSeriesMgt.GetNextNo(BankAccount."Issued Payment Order Nos.", "Document Date", true);

            "Last Issuing No." := IssuedPmtOrdHdr."No.";

            IssuedPmtOrdHdr."Pre-Assigned No. Series" := "No. Series";
            IssuedPmtOrdHdr."Pre-Assigned No." := "No.";
            IssuedPmtOrdHdr."Pre-Assigned User ID" := "User ID";
            IssuedPmtOrdHdr."User ID" := UserId;
            OnBeforeIssuedPaymentOrderHeaderInsert(IssuedPmtOrdHdr, PmtOrdHdr);
            IssuedPmtOrdHdr.Insert();
            OnAfterIssuedPaymentOrderHeaderInsert(IssuedPmtOrdHdr, PmtOrdHdr);

            // insert lines
            if PmtOrdLn.FindSet() then
                repeat
                    IssuedPmtOrdLn.Init();
                    IssuedPmtOrdLn.TransferFields(PmtOrdLn);
                    IssuedPmtOrdLn."Payment Order No." := IssuedPmtOrdHdr."No.";
                    OnBeforeIssuedPaymentOrderLineInsert(IssuedPmtOrdLn, PmtOrdLn);
                    IssuedPmtOrdLn.Insert();
                    OnAfterIssuedPaymentOrderLineInsert(IssuedPmtOrdLn, PmtOrdLn);
                until PmtOrdLn.Next() = 0;

            OnAfterIssuePaymentOrder(PmtOrdHdr);

            // delete non issued bank statement
            SuspendStatusCheck(true);
            Delete(true);
        end;
    end;

    local procedure CheckPaymentOrderLines(PmtOrdHdr: Record "Payment Order Header")
    var
        PmtOrdLn: Record "Payment Order Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPaymentOrderLines(PmtOrdHdr, IsHandled);
        if IsHandled then
            exit;

        with PmtOrdLn do begin
            PaymentOrderManagement.ClearErrorMessageLog();
            SetPaymentOrderLineFilters(PmtOrdLn, PmtOrdHdr);
            FindSet();
            repeat
                IsHandled := false;
                OnBeforeCheckPaymentOrderLine(PmtOrdLn, IsHandled);
                if not IsHandled then begin
                    PaymentOrderManagement.CheckPaymentOrderLineFormat(PmtOrdLn, false);
                    PaymentOrderManagement.CheckPaymentOrderLineBankAccountNo(PmtOrdLn, false);
                    PaymentOrderManagement.CheckPaymentOrderLineCustVendBlocked(PmtOrdLn, false);
                    PaymentOrderManagement.CheckPaymentOrderLineApply(PmtOrdLn, false);
                    PaymentOrderManagement.CheckPaymentOrderLineCustom(PmtOrdLn, false);
                end;
            until Next() = 0;

            PaymentOrderManagement.ProcessErrorMessages(true, true);
        end;
    end;

    local procedure SetPaymentOrderLineFilters(var PmtOrdLn: Record "Payment Order Line"; PmtOrdHdr: Record "Payment Order Header")
    begin
        PmtOrdLn.SetRange("Payment Order No.", PmtOrdHdr."No.");
        PmtOrdLn.SetRange("Skip Payment", false);
        OnAfterSetPaymentOrderLineFilters(PmtOrdLn, PmtOrdHdr);
    end;

    [Scope('OnPrem')]
    procedure Reopen(var PmtOrdHdr: Record "Payment Order Header")
    begin
        OnBeforeReopenPaymentOrder(PmtOrdHdr);

        with PmtOrdHdr do begin
            if Status = Status::Open then
                exit;
            Status := Status::Open;
            Modify(true);
        end;

        OnAfterReopenPaymentOrder(PmtOrdHdr);
    end;

    [Scope('OnPrem')]
    procedure PerformManualReopen(var PmtOrdHdr: Record "Payment Order Header")
    begin
        if PmtOrdHdr.Status = PmtOrdHdr.Status::"Pending Approval" then
            Error(ApprovalProcessReopenErr);

        Reopen(PmtOrdHdr);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIssuedPaymentOrderHeaderInsert(var IssuedPaymentOrderHeader: Record "Issued Payment Order Header"; var PaymentOrderHeader: Record "Payment Order Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIssuedPaymentOrderLineInsert(var IssuedPaymentOrderLine: Record "Issued Payment Order Line"; var PaymentOrderLine: Record "Payment Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIssuePaymentOrder(var PaymentOrderHeader: Record "Payment Order Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReopenPaymentOrder(var PaymentOrderHeader: Record "Payment Order Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPaymentOrderLineFilters(var PaymentOrderLine: Record "Payment Order Line"; PaymentOrderHeader: Record "Payment Order Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIssuedPaymentOrderHeaderInsert(var IssuedPaymentOrderHeader: Record "Issued Payment Order Header"; var PaymentOrderHeader: Record "Payment Order Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIssuedPaymentOrderLineInsert(var IssuedPaymentOrderLine: Record "Issued Payment Order Line"; var PaymentOrderLine: Record "Payment Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIssuePaymentOrder(var PaymentOrderHeader: Record "Payment Order Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReopenPaymentOrder(var PaymentOrderHeader: Record "Payment Order Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterCheck(var PaymentOrderHeader: Record "Payment Order Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPaymentOrderLines(var PaymentOrderHeader: Record "Payment Order Header"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPaymentOrderLine(var PaymentOrderLine: Record "Payment Order Line"; var IsHandled: Boolean);
    begin
    end;
}
#endif