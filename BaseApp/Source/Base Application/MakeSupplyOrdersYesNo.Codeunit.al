codeunit 5521 "Make Supply Orders (Yes/No)"
{
    TableNo = "Requisition Line";

    trigger OnRun()
    begin
        ReqLine.Copy(Rec);
        Code;
        Rec := ReqLine;
    end;

    var
        ReqLine: Record "Requisition Line";
        MfgUserTempl: Record "Manufacturing User Template";
        CarryOutActionMsgPlan: Report "Carry Out Action Msg. - Plan.";
        BlockForm: Boolean;
        CarriedOut: Boolean;

    local procedure "Code"()
    var
        ReqLine2: Record "Requisition Line";
    begin
        CarriedOut := false;

        with ReqLine do begin
            if not BlockForm then
                if not (PAGE.RunModal(PAGE::"Make Supply Orders", MfgUserTempl) = ACTION::LookupOK) then
                    exit;

            ReqLine2.Copy(ReqLine);
            ReqLine2.FilterGroup(2);
            CopyFilters(ReqLine2);

            CarryOutActionMsgPlan.UseRequestPage(false);
            CarryOutActionMsgPlan.SetDemandOrder(ReqLine, MfgUserTempl);
            CarryOutActionMsgPlan.RunModal;
            Clear(CarryOutActionMsgPlan);
            CarriedOut := true;
        end;
    end;

    procedure SetManufUserTemplate(ManufUserTemplate: Record "Manufacturing User Template")
    begin
        MfgUserTempl := ManufUserTemplate;
    end;

    procedure SetBlockForm()
    begin
        BlockForm := true;
    end;

    procedure SetCreatedDocumentBuffer(var TempDocumentEntry: Record "Document Entry" temporary)
    begin
        CarryOutActionMsgPlan.SetCreatedDocumentBuffer(TempDocumentEntry);
    end;

    procedure ActionMsgCarriedOut(): Boolean
    begin
        exit(CarriedOut);
    end;
}

