codeunit 99000812 PlanningWkshManagement
{

    trigger OnRun()
    begin
    end;

    var
        LastReqLine: Record "Requisition Line";

    procedure SetName(CurrentWkshBatchName: Code[10]; var ReqLine: Record "Requisition Line")
    begin
        ReqLine.FilterGroup(2);
        ReqLine.SetRange("Journal Batch Name", CurrentWkshBatchName);
        ReqLine.FilterGroup(0);
        if ReqLine.Find('-') then;
    end;

    procedure GetDescriptionAndRcptName(var ReqLine: Record "Requisition Line"; var ItemDescription: Text[100]; var RoutingDescription: Text[100])
    var
        Item: Record Item;
        RtngHeader: Record "Routing Header";
    begin
        if ReqLine."No." = '' then
            ItemDescription := ''
        else
            if ReqLine."No." <> LastReqLine."No." then begin
                if Item.Get(ReqLine."No.") then
                    ItemDescription := Item.Description
                else
                    ItemDescription := '';
            end;

        if ReqLine."Routing No." = '' then
            RoutingDescription := ''
        else
            if ReqLine."Routing No." <> LastReqLine."Routing No." then begin
                if RtngHeader.Get(ReqLine."Routing No.") then
                    RoutingDescription := RtngHeader.Description
                else
                    RoutingDescription := '';
            end;

        LastReqLine := ReqLine;
    end;
}

