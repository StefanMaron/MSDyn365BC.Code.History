codeunit 7323 "Whse.-Act.-Post (Yes/No)"
{
    TableNo = "Warehouse Activity Line";

    trigger OnRun()
    begin
        WhseActivLine.Copy(Rec);
        Code;
        Copy(WhseActivLine);
    end;

    var
        Text000: Label '&Receive,Receive &and Invoice';
        WhseActivLine: Record "Warehouse Activity Line";
        WhseActivityPost: Codeunit "Whse.-Activity-Post";
        Selection: Integer;
        Text001: Label '&Ship,Ship &and Invoice';
        Text002: Label 'Do you want to post the %1 and %2?';
        PrintDoc: Boolean;
        DefaultOption: Integer;

    local procedure "Code"()
    var
        HideDialog: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        HideDialog := false;
        DefaultOption := 2;
        OnBeforeConfirmPost(WhseActivLine, HideDialog, Selection, DefaultOption, IsHandled);
        if IsHandled then
            exit;

        if (DefaultOption < 1) or (DefaultOption > 2) then
            DefaultOption := 2;

        with WhseActivLine do begin
            if not HideDialog then
                case "Activity Type" of
                    "Activity Type"::"Invt. Put-away":
                        if not SelectForPutAway then
                            exit;
                    else
                        if not SelectForOtherTypes then
                            exit;
                end;

            WhseActivityPost.SetInvoiceSourceDoc(Selection = 2);
            WhseActivityPost.PrintDocument(PrintDoc);
            WhseActivityPost.Run(WhseActivLine);
            Clear(WhseActivityPost);
        end;
    end;

    procedure PrintDocument(SetPrint: Boolean)
    begin
        PrintDoc := SetPrint;
    end;

    local procedure SelectForPutAway(): Boolean
    begin
        with WhseActivLine do
            if ("Source Document" = "Source Document"::"Prod. Output") or
               ("Source Document" = "Source Document"::"Inbound Transfer") or
               ("Source Document" = "Source Document"::"Prod. Consumption")
            then begin
                if not Confirm(Text002, false, "Activity Type", "Source Document") then
                    exit(false);
            end else begin
                Selection := StrMenu(Text000, DefaultOption);
                if Selection = 0 then
                    exit(false);
            end;

        exit(true);
    end;

    local procedure SelectForOtherTypes(): Boolean
    begin
        with WhseActivLine do
            if ("Source Document" = "Source Document"::"Prod. Consumption") or
               ("Source Document" = "Source Document"::"Outbound Transfer")
            then begin
                if not Confirm(Text002, false, "Activity Type", "Source Document") then
                    exit(false);
            end else begin
                Selection := StrMenu(Text001, DefaultOption);
                if Selection = 0 then
                    exit(false);
            end;

        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmPost(var WhseActivLine: Record "Warehouse Activity Line"; var HideDialog: Boolean; var Selection: Integer; var DefaultOption: Integer; var IsHandled: Boolean)
    begin
    end;
}

