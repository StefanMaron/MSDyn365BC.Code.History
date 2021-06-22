codeunit 7034 "Price Source - Cust. Disc. Gr." implements "Price Source"
{
    var
        CustomerDiscountGroup: Record "Customer Discount Group";
        ParentErr: Label 'Parent Source No. must be blank for Customer Disc. Group source type.';

    procedure GetNo(var PriceSource: Record "Price Source")
    begin
        with PriceSource do
            if CustomerDiscountGroup.GetBySystemId("Source ID") then begin
                "Source No." := CustomerDiscountGroup.Code;
                FillAdditionalFields(PriceSource);
            end else
                InitSource();
    end;

    procedure GetId(var PriceSource: Record "Price Source")
    begin
        with PriceSource do
            if CustomerDiscountGroup.Get("Source No.") then begin
                "Source ID" := CustomerDiscountGroup.SystemId;
                FillAdditionalFields(PriceSource);
            end else
                InitSource();
    end;

    procedure IsForAmountType(AmountType: Enum "Price Amount Type"): Boolean
    begin
        exit(AmountType = AmountType::Discount);
    end;

    procedure IsSourceNoAllowed() Result: Boolean;
    begin
        Result := true;
    end;

    procedure IsLookupOK(var PriceSource: Record "Price Source"): Boolean
    var
        xPriceSource: Record "Price Source";
    begin
        xPriceSource := PriceSource;
        if CustomerDiscountGroup.Get(xPriceSource."Source No.") then;
        if Page.RunModal(Page::"Customer Disc. Groups", CustomerDiscountGroup) = ACTION::LookupOK then begin
            xPriceSource.Validate("Source No.", CustomerDiscountGroup.Code);
            PriceSource := xPriceSource;
            exit(true);
        end;
    end;

    procedure VerifyParent(var PriceSource: Record "Price Source") Result: Boolean
    begin
        if PriceSource."Parent Source No." <> '' then
            Error(ParentErr);
    end;

    procedure GetGroupNo(PriceSource: Record "Price Source"): Code[20];
    begin
    end;

    local procedure FillAdditionalFields(var PriceSource: Record "Price Source")
    begin
        PriceSource.Description := CustomerDiscountGroup.Description;
    end;

}