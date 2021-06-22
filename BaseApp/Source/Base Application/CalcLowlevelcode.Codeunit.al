codeunit 99000853 "Calc. Low-level code"
{

    trigger OnRun()
    begin
        FindTopLevel;
    end;

    var
        Text000: Label 'Calculate low-level code';
        Text001: Label 'No. #2################## @3@@@@@@@@@@@@@';
        Text002: Label 'Top-Level Items';
        Text003: Label 'BOMs';
        HideDialogs: Boolean;

    local procedure FindTopLevel()
    var
        ProdBOMLine: Record "Production BOM Line";
        BOMComp: Record "BOM Component";
        Item: Record Item;
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMHeader2: Record "Production BOM Header";
        CalcLowLevelCode: Codeunit "Calculate Low-Level Code";
        Window: Dialog;
        WindowUpdateDateTime: DateTime;
        NoofItems: Integer;
        CountOfRecords: Integer;
        HasProductionBOM: Boolean;
    begin
        NoofItems := 0;
        if not HideDialogs then
            if not Confirm(Text000, false) then
                exit;
        Window.Open(
          '#1################## \\' +
          Text001);
        WindowUpdateDateTime := CurrentDateTime;

        Window.Update(1, Text002);

        Item.LockTable();
        Item.ModifyAll("Low-Level Code", 0);
        ProdBOMHeader.LockTable();
        ProdBOMHeader.ModifyAll("Low-Level Code", 0);

        ProdBOMLine.SetCurrentKey(Type, "No.");
        CountOfRecords := Item.Count();
        if Item.Find('-') then
            repeat
                if CurrentDateTime - WindowUpdateDateTime > 2000 then begin
                    Window.Update(2, Item."No.");
                    Window.Update(3, Round(NoofItems / CountOfRecords * 10000, 1));
                    WindowUpdateDateTime := CurrentDateTime;
                end;

                HasProductionBOM := ProdBOMHeader.Get(Item."Production BOM No.");
                if (ProdBOMHeader."Low-Level Code" = 0) or not HasProductionBOM
                then begin
                    ProdBOMLine.SetRange("No.", Item."No.");
                    ProdBOMLine.SetRange(Type, ProdBOMLine.Type::Item);

                    BOMComp.SetRange(Type, BOMComp.Type::Item);
                    BOMComp.SetRange("No.", Item."No.");

                    if ProdBOMLine.IsEmpty and BOMComp.IsEmpty then begin
                        // handle items which are not part of any BOMs
                        Item.CalcFields("Assembly BOM");
                        if Item."Assembly BOM" then
                            CalcLowLevelCode.RecalcAsmLowerLevels(Item."No.", CalcLowLevelCode.CalcLevels(3, Item."No.", 0, 0), true);
                        if HasProductionBOM then
                            CalcLevelsForBOM(ProdBOMHeader);
                    end else
                        if HasProductionBOM then begin
                            if ProdBOMLine.Find('-') then
                                repeat
                                    // handle items which are part of un-certified, active BOMs
                                    if ProdBOMHeader2.Get(ProdBOMLine."Production BOM No.") then
                                        if ProdBOMHeader2.Status in [ProdBOMHeader2.Status::New, ProdBOMHeader2.Status::"Under Development"] then
                                            CalcLevelsForBOM(ProdBOMHeader);
                                until ProdBOMLine.Next = 0;
                        end;
                end;

                NoofItems := NoofItems + 1;
            until Item.Next = 0;

        NoofItems := 0;
        Window.Update(1, Text003);
        ProdBOMHeader.Reset();
        ProdBOMHeader.SetCurrentKey(Status);
        ProdBOMHeader.SetRange(Status, ProdBOMHeader.Status::Certified);
        ProdBOMHeader.SetRange("Low-Level Code", 0);
        CountOfRecords := ProdBOMHeader.Count();
        if ProdBOMHeader.Find('-') then
            repeat
                if CurrentDateTime - WindowUpdateDateTime > 2000 then begin
                    Window.Update(2, ProdBOMHeader."No.");
                    Window.Update(3, Round(NoofItems / CountOfRecords * 10000, 1));
                    WindowUpdateDateTime := CurrentDateTime;
                end;
                ProdBOMHeader2 := ProdBOMHeader;
                CalcLevelsForBOM(ProdBOMHeader2);
                NoofItems := NoofItems + 1;
            until ProdBOMHeader.Next = 0;

        OnAfterFindTopLevel;
    end;

    local procedure CalcLevelsForBOM(var ProdBOM: Record "Production BOM Header")
    var
        ProdBOMLine: Record "Production BOM Line";
        CalcLowLevelCode: Codeunit "Calculate Low-Level Code";
    begin
        if ProdBOM.Status = ProdBOM.Status::Certified then begin
            ProdBOM."Low-Level Code" := CalcLowLevelCode.CalcLevels(ProdBOMLine.Type::"Production BOM", ProdBOM."No.", 0, 0);
            CalcLowLevelCode.RecalcLowerLevels(ProdBOM."No.", ProdBOM."Low-Level Code", true);
            ProdBOM.Modify();
        end;
    end;

    procedure SetHideDialogs(NewHideDialogs: Boolean)
    begin
        HideDialogs := NewHideDialogs;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindTopLevel()
    begin
    end;
}

