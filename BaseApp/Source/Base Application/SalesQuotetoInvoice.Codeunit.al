codeunit 1305 "Sales-Quote to Invoice"
{
    TableNo = "Sales Header";

    trigger OnRun()
    var
        Cust: Record Customer;
        SalesInvoiceLine: Record "Sales Line";
        SalesSetup: Record "Sales & Receivables Setup";
        CustCheckCrLimit: Codeunit "Cust-Check Cr. Limit";
    begin
        OnBeforeOnRun(Rec);

        TestField("Document Type", "Document Type"::Quote);

        if "Sell-to Customer No." = '' then
            Error(SpecifyCustomerErr);

        if "Bill-to Customer No." = '' then
            Error(SpecifyBillToCustomerNoErr, FieldCaption("Bill-to Customer No."));

        Cust.Get("Sell-to Customer No.");
        Cust.CheckBlockedCustOnDocs(Cust, "Document Type"::Quote, true, false);
        CalcFields("Amount Including VAT", "Invoice Discount Amount", "Work Description");

        ValidateSalesPersonOnSalesHeader(Rec, true, false);

        CheckForBlockedLines;

        SalesInvoiceHeader := Rec;

        SalesInvoiceLine.LockTable();

        CreateSalesInvoiceHeader(SalesInvoiceHeader, Rec);
        CreateSalesInvoiceLines(SalesInvoiceHeader, Rec);
        OnAfterInsertAllSalesInvLines(SalesInvoiceLine, Rec);

        SalesSetup.Get();
        if SalesSetup."Default Posting Date" = SalesSetup."Default Posting Date"::"No Date" then begin
            SalesInvoiceHeader."Posting Date" := 0D;
            SalesInvoiceHeader.Modify();
        end;
        UpdateEmailParameters(SalesInvoiceHeader);
        UpdateCouponClaims(SalesInvoiceHeader);

        OnBeforeDeletionOfQuote(Rec, SalesInvoiceHeader);

        DeleteLinks;
        Delete;

        Commit();
        Clear(CustCheckCrLimit);

        OnAfterOnRun(Rec, SalesInvoiceHeader);
    end;

    var
        SalesInvoiceHeader: Record "Sales Header";
        SpecifyCustomerErr: Label 'You must select a customer before you can convert a quote to an invoice.';
        SpecifyBillToCustomerNoErr: Label 'You must specify the %1 before you can convert a quote to an invoice.', Comment = '%1 is Bill-To Customer No.';

    procedure GetSalesInvoiceHeader(var SalesHeader2: Record "Sales Header")
    begin
        SalesHeader2 := SalesInvoiceHeader;
    end;

    local procedure CreateSalesInvoiceHeader(var SalesInvoiceHeader: Record "Sales Header"; SalesQuoteHeader: Record "Sales Header")
    begin
        with SalesQuoteHeader do begin
            SalesInvoiceHeader."Document Type" := SalesInvoiceHeader."Document Type"::Invoice;

            SalesInvoiceHeader."No. Printed" := 0;
            SalesInvoiceHeader.Status := SalesInvoiceHeader.Status::Open;
            SalesInvoiceHeader."No." := '';

            SalesInvoiceHeader."Quote No." := "No.";
            SalesInvoiceHeader.Insert(true);

            if "Posting Date" <> 0D then
                SalesInvoiceHeader."Posting Date" := "Posting Date"
            else
                SalesInvoiceHeader."Posting Date" := WorkDate;
            SalesInvoiceHeader.InitFromSalesHeader(SalesQuoteHeader);
            OnBeforeInsertSalesInvoiceHeader(SalesInvoiceHeader, SalesQuoteHeader);
            SalesInvoiceHeader.Modify();
        end;
    end;

    local procedure CreateSalesInvoiceLines(SalesInvoiceHeader: Record "Sales Header"; SalesQuoteHeader: Record "Sales Header")
    var
        SalesQuoteLine: Record "Sales Line";
        SalesInvoiceLine: Record "Sales Line";
        IsHandled: Boolean;
    begin
        with SalesQuoteHeader do begin
            SalesQuoteLine.Reset();
            SalesQuoteLine.SetRange("Document Type", "Document Type");
            SalesQuoteLine.SetRange("Document No.", "No.");
            OnAfterSalesQuoteLineSetFilters(SalesQuoteLine);
            if SalesQuoteLine.FindSet then
                repeat
                    IsHandled := false;
                    OnBeforeCreateSalesInvoiceLineLoop(SalesQuoteLine, SalesQuoteHeader, SalesInvoiceHeader, IsHandled);
                    if not IsHandled then begin
                        SalesInvoiceLine := SalesQuoteLine;
                        SalesInvoiceLine."Document Type" := SalesInvoiceHeader."Document Type";
                        SalesInvoiceLine."Document No." := SalesInvoiceHeader."No.";
                        if SalesInvoiceLine."No." <> '' then
                            SalesInvoiceLine.DefaultDeferralCode;
                        SalesInvoiceLine.InitQtyToShip;
                        OnBeforeInsertSalesInvoiceLine(SalesQuoteLine, SalesQuoteHeader, SalesInvoiceLine, SalesInvoiceHeader);
                        SalesInvoiceLine.Insert();
                        OnAfterInsertSalesInvoiceLine(SalesQuoteLine, SalesQuoteHeader, SalesInvoiceLine, SalesInvoiceHeader);
                    end;
                until SalesQuoteLine.Next = 0;

            MoveLineCommentsToSalesInvoice(SalesInvoiceHeader, SalesQuoteHeader);

            SalesQuoteLine.DeleteAll();
        end;
    end;

    local procedure MoveLineCommentsToSalesInvoice(SalesInvoiceHeader: Record "Sales Header"; SalesQuoteHeader: Record "Sales Header")
    var
        SalesCommentLine: Record "Sales Comment Line";
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        SalesCommentLine.CopyComments(
          SalesQuoteHeader."Document Type", SalesInvoiceHeader."Document Type", SalesQuoteHeader."No.", SalesInvoiceHeader."No.");
        RecordLinkManagement.CopyLinks(SalesQuoteHeader, SalesInvoiceHeader);
    end;

    local procedure UpdateEmailParameters(SalesHeader: Record "Sales Header")
    var
        EmailParameter: Record "Email Parameter";
    begin
        EmailParameter.SetRange("Document No", SalesHeader."Quote No.");
        EmailParameter.SetRange("Document Type", SalesHeader."Document Type"::Quote);
        EmailParameter.DeleteAll();
    end;

    local procedure UpdateCouponClaims(SalesHeader: Record "Sales Header")
    var
        O365CouponClaimDocLink: Record "O365 Coupon Claim Doc. Link";
    begin
        O365CouponClaimDocLink.SetRange("Document No.", SalesHeader."Quote No.");
        O365CouponClaimDocLink.SetRange("Document Type", SalesHeader."Document Type"::Quote);
        if O365CouponClaimDocLink.FindSet(true, true) then
            repeat
                O365CouponClaimDocLink.Rename(
                  O365CouponClaimDocLink."Claim ID", O365CouponClaimDocLink."Graph Contact ID", SalesHeader."Document Type", SalesHeader."No.");
            until O365CouponClaimDocLink.Next = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertSalesInvoiceHeader(var SalesInvoiceHeader: Record "Sales Header"; QuoteSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertSalesInvoiceLine(SalesQuoteLine: Record "Sales Line"; SalesQuoteHeader: Record "Sales Header"; var SalesInvoiceLine: Record "Sales Line"; SalesInvoiceHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertAllSalesInvLines(var SalesInvoiceLine: Record "Sales Line"; SalesQuoteHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(var SalesHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesQuoteLineSetFilters(var SalesQuoteLine: Record "Sales Line");

    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertSalesInvoiceLine(SalesQuoteLine: Record "Sales Line"; SalesQuoteHeader: Record "Sales Header"; var SalesInvoiceLine: Record "Sales Line"; SalesInvoiceHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateSalesInvoiceLineLoop(var SalesQuoteLine: Record "Sales Line"; var SalesQuoteHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Header"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeletionOfQuote(var SalesHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Header")
    begin
    end;
}

