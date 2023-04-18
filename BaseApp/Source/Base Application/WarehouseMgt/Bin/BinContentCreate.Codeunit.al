codeunit 7319 "Bin Content Create"
{
    TableNo = "Bin Creation Worksheet Line";

    trigger OnRun()
    begin
        BinCreateLine.Copy(Rec);
        Code();
        Rec := BinCreateLine;
    end;

    var
        BinCreateLine: Record "Bin Creation Worksheet Line";
        BinContent: Record "Bin Content";
        Location: Record Location;

        Text000: Label 'Do you want to create the bin content?';
        Text001: Label 'There is nothing to create.';

    local procedure "Code"()
    begin
        if not Confirm(Text000, false) then
            exit;

        if BinCreateLine.Find('-') then begin
            BinCreateLine.TestField("Location Code");
            GetLocation(BinCreateLine."Location Code");
            repeat
                if Location."Directed Put-away and Pick" then begin
                    BinCreateLine.TestField("Zone Code");
                    BinCreateLine.TestField("Unit of Measure Code");
                end;
                BinCreateLine.TestField("Bin Code");
                BinCreateLine.TestField("Item No.");
                BinCreate(BinCreateLine);
            until BinCreateLine.Next() = 0;
            BinCreateLine.DeleteAll();
        end else
            Message(Text001);
    end;

    local procedure BinCreate(BinCreateLine2: Record "Bin Creation Worksheet Line")
    begin
        with BinCreateLine2 do begin
            if EmptyLine() then
                exit;
            BinContent.Init();
            BinContent."Bin Code" := "Bin Code";
            BinContent."Location Code" := "Location Code";
            BinContent."Item No." := "Item No.";
            BinContent."Variant Code" := "Variant Code";
            BinContent."Unit of Measure Code" := "Unit of Measure Code";
            BinContent."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
            BinContent.Fixed := Fixed;
            BinContent.Default := Default;
            BinContent.Dedicated := Dedicated;
            BinContent."Zone Code" := "Zone Code";
            BinContent."Bin Type Code" := "Bin Type Code";
            BinContent."Warehouse Class Code" := "Warehouse Class Code";
            BinContent."Block Movement" := "Block Movement";
            BinContent."Bin Ranking" := "Bin Ranking";
            BinContent."Cross-Dock Bin" := "Cross-Dock Bin";
            BinContent."Min. Qty." := "Min. Qty.";
            BinContent."Max. Qty." := "Max. Qty.";
            OnBinCreateOnBeforeInsertBinContent(BinContent, BinCreateLine2);
            BinContent.Insert(true);
        end;
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if Location.Code <> LocationCode then
            Location.Get(LocationCode);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBinCreateOnBeforeInsertBinContent(var BinContent: Record "Bin Content"; BinCreateLine2: Record "Bin Creation Worksheet Line")
    begin
    end;
}

