codeunit 7039 "Price Source - Campaign" implements "Price Source"
{
    var
        Campaign: Record Campaign;
        ParentErr: Label 'Parent Source No. must be blank for Campaign source type.';

    procedure GetNo(var PriceSource: Record "Price Source")
    begin
        if Campaign.GetBySystemId(PriceSource."Source ID") then
            PriceSource."Source No." := Campaign."No."
        else
            PriceSource.InitSource();
    end;

    procedure GetId(var PriceSource: Record "Price Source")
    begin
        if Campaign.Get(PriceSource."Source No.") then
            PriceSource."Source ID" := Campaign.SystemId
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
        if Campaign.Get(PriceSource."Source No.") then;
        if Page.RunModal(Page::"Campaign List", Campaign) = ACTION::LookupOK then begin
            PriceSource.Validate("Source No.", Campaign."No.");
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
}