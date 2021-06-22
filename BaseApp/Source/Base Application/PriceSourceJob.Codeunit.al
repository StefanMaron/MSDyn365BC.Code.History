codeunit 7036 "Price Source - Job" implements "Price Source"
{
    var
        Job: Record Job;
        ParentErr: Label 'Parent Source No. must be blank for Job source type.';

    procedure GetNo(var PriceSource: Record "Price Source")
    begin
        if Job.GetBySystemId(PriceSource."Source ID") then
            PriceSource."Source No." := Job."No."
        else
            PriceSource.InitSource();
    end;

    procedure GetId(var PriceSource: Record "Price Source")
    begin
        if Job.Get(PriceSource."Source No.") then
            PriceSource."Source ID" := Job.SystemId
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
        if Job.Get(PriceSource."Source No.") then;
        if Page.RunModal(Page::"Job List", Job) = ACTION::LookupOK then begin
            PriceSource.Validate("Source No.", Job."No.");
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