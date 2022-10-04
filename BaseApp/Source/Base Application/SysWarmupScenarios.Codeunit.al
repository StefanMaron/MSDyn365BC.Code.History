#if NOT CLEAN21
codeunit 130411 "Sys. Warmup Scenarios"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'The codeunit will be deleted';
    ObsoleteTag = '21.0';
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    [Test]
    procedure WarmupInvoicePosting()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        if not Customer.FindFirst() then
            exit;

        Item.SetFilter(Inventory, '<>%1', 0);
        if not Item.FindFirst() then
            exit;

        OnWarmupInvoicePostingBeforeCreateSalesInvoice(SalesHeader);
        CreateSalesInvoice(SalesHeader, Customer, Item);
        PostSalesInvoice(SalesHeader);

        OnAfterWarmupInvoicePosting(SalesHeader);
    end;

    local procedure GetRandomString(): Text
    begin
        exit(DelChr(Format(CreateGuid()), '=', '{}-'));
    end;

    local procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header"; Customer: Record Customer; Item: Record Item)
    begin
        CreateSalesHeader(SalesHeader, Customer);
        CreateSalesLine(SalesHeader, Item);
    end;

    local procedure PostSalesInvoice(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; Customer: Record Customer)
    begin
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader."No." := CopyStr(GetRandomString(), 1, MaxStrLen(SalesHeader."No."));
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesLine(SalesHeader: Record "Sales Header"; Item: Record Item)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        SalesLine.Validate("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesLine.Validate("Line No.", 10000);
        SalesLine.Insert(true);
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Validate("No.", Item."No.");
        SalesLine.Validate(Quantity, 1);
        SalesLine.Modify(true);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterWarmupInvoicePosting(SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnWarmupInvoicePostingBeforeCreateSalesInvoice(SalesHeader: Record "Sales Header")
    begin
    end;
}
#endif