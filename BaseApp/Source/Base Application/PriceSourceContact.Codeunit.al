codeunit 7038 "Price Source - Contact" implements "Price Source"
{
    var
        Contact: Record Contact;
        ParentErr: Label 'Parent Source No. must be blank for Contact source type.';

    procedure GetNo(var PriceSource: Record "Price Source")
    begin
        if Contact.GetBySystemId(PriceSource."Source ID") then
            PriceSource."Source No." := Contact."No."
        else
            PriceSource.InitSource();
    end;

    procedure GetId(var PriceSource: Record "Price Source")
    begin
        if Contact.Get(PriceSource."Source No.") then
            PriceSource."Source ID" := Contact.SystemId
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
        if Contact.Get(PriceSource."Source No.") then;
        if Page.RunModal(Page::"Contact List", Contact) = ACTION::LookupOK then begin
            PriceSource.Validate("Source No.", Contact."No.");
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