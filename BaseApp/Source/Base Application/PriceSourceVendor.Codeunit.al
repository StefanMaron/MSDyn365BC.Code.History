codeunit 7035 "Price Source - Vendor" implements "Price Source"
{
    var
        Vendor: Record Vendor;
        ParentErr: Label 'Parent Source No. must be blank for Vendor source type.';

    procedure GetNo(var PriceSource: Record "Price Source")
    begin
        if Vendor.GetBySystemId(PriceSource."Source ID") then
            PriceSource."Source No." := Vendor."No."
        else
            PriceSource.InitSource();
    end;

    procedure GetId(var PriceSource: Record "Price Source")
    begin
        if Vendor.Get(PriceSource."Source No.") then
            PriceSource."Source ID" := Vendor.SystemId
        else
            PriceSource.InitSource();
    end;

    procedure IsForAmountType(AmountType: Enum "Price Amount Type"): Boolean
    begin
        exit(true);
    end;

    procedure IsSourceNoAllowed() Result: Boolean;
    begin
        Result := true;
    end;

    procedure IsLookupOK(var PriceSource: Record "Price Source"): Boolean
    begin
        if Vendor.Get(PriceSource."Source No.") then;
        if Page.RunModal(Page::"Vendor List", Vendor) = ACTION::LookupOK then begin
            PriceSource.Validate("Source No.", Vendor."No.");
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
        exit(PriceSource."Source No.");
    end;
}