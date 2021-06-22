codeunit 345 "Sales Line CaptionClass Mgmt"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        GlobalSalesHeader: Record "Sales Header";
        GlobalField: Record "Field";

    procedure GetSalesLineCaptionClass(var SalesLine: Record "Sales Line"; FieldNumber: Integer): Text
    begin
        if (GlobalSalesHeader."Document Type" <> SalesLine."Document Type") or (GlobalSalesHeader."No." <> SalesLine."Document No.") then
            if not GlobalSalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.") then
                Clear(GlobalSalesHeader);
        case FieldNumber of
            SalesLine.FieldNo("No."):
                exit(StrSubstNo('3,%1', GetFieldCaption(DATABASE::"Sales Line", FieldNumber)));
            else begin
                    if GlobalSalesHeader."Prices Including VAT" then
                        exit('2,1,' + GetFieldCaption(DATABASE::"Sales Line", FieldNumber));
                    exit('2,0,' + GetFieldCaption(DATABASE::"Sales Line", FieldNumber));
                end;
        end;
    end;

    local procedure GetFieldCaption(TableNumber: Integer; FieldNumber: Integer): Text
    begin
        if (GlobalField.TableNo <> TableNumber) or (GlobalField."No." <> FieldNumber) then
            GlobalField.Get(TableNumber, FieldNumber);
        exit(GlobalField."Field Caption");
    end;

    [EventSubscriber(ObjectType::Table, 36, 'OnAfterChangePricesIncludingVAT', '', true, true)]
    local procedure SalesHeaderChangedPricesIncludingVAT(var SalesHeader: Record "Sales Header")
    begin
        GlobalSalesHeader := SalesHeader;
    end;

    [EventSubscriber(ObjectType::Table, 36, 'OnAfterSetFieldsBilltoCustomer', '', true, true)]
    local procedure UpdateSalesLineFieldsCaptionOnAfterSetFieldsBilltoCustomer(var SalesHeader: Record "Sales Header"; Customer: Record Customer)
    begin
        GlobalSalesHeader := SalesHeader;
    end;

    [EventSubscriber(ObjectType::Table, 36, 'OnValidateBilltoCustomerTemplateCodeBeforeRecreateSalesLines', '', true, true)]
    local procedure UpdateSalesLineFieldsCaptionOnValidateBilltoCustTemplCodeBeforeRecreateSalesLines(var SalesHeader: Record "Sales Header"; CallingFieldNo: Integer)
    begin
        GlobalSalesHeader := SalesHeader;
    end;
}

