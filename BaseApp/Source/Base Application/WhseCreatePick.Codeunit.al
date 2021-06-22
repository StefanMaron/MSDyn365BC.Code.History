codeunit 5778 "Whse. Create Pick"
{
    TableNo = "Whse. Worksheet Line";

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, IsHandled);
        if IsHandled then
            exit;

        WkshPickLine.Copy(Rec);
        WhseCreatePick.SetWkshPickLine(WkshPickLine);
        WhseCreatePick.RunModal;
        if WhseCreatePick.GetResultMessage then
            AutofillQtyToHandle(Rec);
        Clear(WhseCreatePick);

        Reset;
        SetCurrentKey("Worksheet Template Name", Name, "Location Code", "Sorting Sequence No.");
        FilterGroup := 2;
        SetRange("Worksheet Template Name", "Worksheet Template Name");
        SetRange(Name, Name);
        SetRange("Location Code", "Location Code");
        FilterGroup := 0;
    end;

    var
        WkshPickLine: Record "Whse. Worksheet Line";
        WhseCreatePick: Report "Create Pick";

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var WhseWorksheetLine: Record "Whse. Worksheet Line"; var IsHandled: Boolean);
    begin
    end;
}

