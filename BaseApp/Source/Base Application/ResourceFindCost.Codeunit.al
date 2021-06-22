codeunit 220 "Resource-Find Cost"
{
    TableNo = "Resource Cost";
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced by the new implementation (V16) of price calculation.';
    ObsoleteTag = '16.0';

    trigger OnRun()
    begin
        ResCost.Copy(Rec);
        with ResCost do begin
            ResCost2 := ResCost;

            FindResUnitCost(ResCost);

            case "Cost Type" of
                "Cost Type"::Fixed:
                    ;
                "Cost Type"::"% Extra":
                    begin
                        ResCost2."Work Type Code" := '';
                        FindResUnitCost(ResCost2);
                        "Direct Unit Cost" := ResCost2."Direct Unit Cost" * (1 + "Direct Unit Cost" / 100);
                        "Unit Cost" := ResCost2."Unit Cost" * (1 + "Unit Cost" / 100);
                    end;
                "Cost Type"::"LCY Extra":
                    begin
                        ResCost2."Work Type Code" := '';
                        FindResUnitCost(ResCost2);
                        "Direct Unit Cost" := ResCost2."Direct Unit Cost" + "Direct Unit Cost";
                        "Unit Cost" := ResCost2."Unit Cost" + "Unit Cost";
                    end;
            end;
        end;
        Rec := ResCost;
    end;

    var
        ResCost: Record "Resource Cost";
        ResCost2: Record "Resource Cost";
        Res: Record Resource;

    local procedure FindResUnitCost(var NearestResCost: Record "Resource Cost")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindResUnitCost(NearestResCost, IsHandled);
        if IsHandled then
            exit;

        with NearestResCost do begin
            if Get(Type::Resource, Code, "Work Type Code") then
                exit;
            Res.Get(Code);
            if Get(Type::"Group(Resource)", Res."Resource Group No.", "Work Type Code") then
                exit;
            if Get(Type::All, '', "Work Type Code") then
                exit;
            Init;
            Code := Res."No.";
            "Direct Unit Cost" := Res."Direct Unit Cost";
            "Unit Cost" := Res."Unit Cost";
        end;

        OnAfterFindResUnitCost(NearestResCost, Res);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindResUnitCost(var ResourceCost: Record "Resource Cost"; Resource: Record Resource)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindResUnitCost(var ResourceCost: Record "Resource Cost"; var IsHandled: Boolean)
    begin
    end;
}

