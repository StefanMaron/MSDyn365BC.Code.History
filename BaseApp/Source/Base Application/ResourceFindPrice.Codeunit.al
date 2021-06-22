codeunit 221 "Resource-Find Price"
{
    TableNo = "Resource Price";
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by the new implementation (V16) of price calculation.';
    ObsoleteTag = '16.0';

    trigger OnRun()
    begin
        ResPrice.Copy(Rec);
        with ResPrice do
            if FindResPrice then
                ResPrice := ResPrice2
            else begin
                Init;
                Code := Res."No.";
                "Currency Code" := '';
                "Unit Price" := Res."Unit Price";
            end;
        Rec := ResPrice;
    end;

    var
        ResPrice: Record "Resource Price";
        ResPrice2: Record "Resource Price";
        Res: Record Resource;

    local procedure FindResPrice(): Boolean
    var
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindResPrice(ResPrice, IsHandled, Result, ResPrice2);
        if IsHandled then
            exit(Result);

        with ResPrice do begin
            if ResPrice2.Get(Type::Resource, Code, "Work Type Code", "Currency Code") then
                exit(true);

            if ResPrice2.Get(Type::Resource, Code, "Work Type Code", '') then
                exit(true);

            Res.Get(Code);
            if ResPrice2.Get(Type::"Group(Resource)", Res."Resource Group No.", "Work Type Code", "Currency Code") then
                exit(true);

            if ResPrice2.Get(Type::"Group(Resource)", Res."Resource Group No.", "Work Type Code", '') then
                exit(true);

            if ResPrice2.Get(Type::All, '', "Work Type Code", "Currency Code") then
                exit(true);

            if ResPrice2.Get(Type::All, '', "Work Type Code", '') then
                exit(true);
        end;

        OnAfterFindResPrice(ResPrice, Res);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindResPrice(var ResourcePrice: Record "Resource Price"; Resource: Record Resource)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindResPrice(var ResourcePrice: Record "Resource Price"; var IsHandled: Boolean; var Result: Boolean; var ResourcePrice2: Record "Resource Price")
    begin
    end;
}

