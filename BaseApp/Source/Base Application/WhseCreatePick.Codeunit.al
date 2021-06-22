codeunit 5778 "Whse. Create Pick"
{
    TableNo = "Whse. Worksheet Line";

    trigger OnRun()
    begin
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
}

