codeunit 212 "Res. Jnl.-Post Line"
{
    Permissions = TableData "Res. Ledger Entry" = imd,
                  TableData "Resource Register" = imd,
                  TableData "Time Sheet Line" = m,
                  TableData "Time Sheet Detail" = m;
    TableNo = "Res. Journal Line";

    trigger OnRun()
    begin
        GetGLSetup;
        RunWithCheck(Rec);
    end;

    var
        GLSetup: Record "General Ledger Setup";
        ResJnlLine: Record "Res. Journal Line";
        ResLedgEntry: Record "Res. Ledger Entry";
        Res: Record Resource;
        ResReg: Record "Resource Register";
        GenPostingSetup: Record "General Posting Setup";
        ResUOM: Record "Resource Unit of Measure";
        ResJnlCheckLine: Codeunit "Res. Jnl.-Check Line";
        NextEntryNo: Integer;
        GLSetupRead: Boolean;

    procedure RunWithCheck(var ResJnlLine2: Record "Res. Journal Line")
    begin
        ResJnlLine.Copy(ResJnlLine2);
        Code;
        ResJnlLine2 := ResJnlLine;
    end;

    local procedure "Code"()
    var
        IsHandled: Boolean;
    begin
        OnBeforePostResJnlLine(ResJnlLine);

        with ResJnlLine do begin
            if EmptyLine then
                exit;

            ResJnlCheckLine.RunCheck(ResJnlLine);

            if NextEntryNo = 0 then begin
                ResLedgEntry.LockTable();
                NextEntryNo := ResLedgEntry.GetLastEntryNo() + 1;
            end;

            if "Document Date" = 0D then
                "Document Date" := "Posting Date";

            if ResReg."No." = 0 then begin
                ResReg.LockTable();
                if (not ResReg.FindLast) or (ResReg."To Entry No." <> 0) then begin
                    ResReg.Init();
                    ResReg."No." := ResReg."No." + 1;
                    ResReg."From Entry No." := NextEntryNo;
                    ResReg."To Entry No." := NextEntryNo;
                    ResReg."Creation Date" := Today;
                    ResReg."Creation Time" := Time;
                    ResReg."Source Code" := "Source Code";
                    ResReg."Journal Batch Name" := "Journal Batch Name";
                    ResReg."User ID" := UserId;
                    ResReg.Insert();
                end;
            end;
            ResReg."To Entry No." := NextEntryNo;
            ResReg.Modify();

            Res.Get("Resource No.");
            Res.CheckResourcePrivacyBlocked(true);

            IsHandled := false;
            OnBeforeCheckResourceBlocked(Res, IsHandled);
            if not IsHandled then
                Res.TestField(Blocked, false);

            IsHandled := false;
            OnBeforeGenPostingSetupGet(ResJnlLine, IsHandled);
            if not IsHandled then
                if (GenPostingSetup."Gen. Bus. Posting Group" <> "Gen. Bus. Posting Group") or
                    (GenPostingSetup."Gen. Prod. Posting Group" <> "Gen. Prod. Posting Group")
                then
                    GenPostingSetup.Get("Gen. Bus. Posting Group", "Gen. Prod. Posting Group");

            "Resource Group No." := Res."Resource Group No.";

            ResLedgEntry.Init();
            ResLedgEntry.CopyFromResJnlLine(ResJnlLine);

            GetGLSetup;
            ResLedgEntry."Total Cost" := Round(ResLedgEntry."Total Cost");
            ResLedgEntry."Total Price" := Round(ResLedgEntry."Total Price");
            if ResLedgEntry."Entry Type" = ResLedgEntry."Entry Type"::Sale then begin
                ResLedgEntry.Quantity := -ResLedgEntry.Quantity;
                ResLedgEntry."Total Cost" := -ResLedgEntry."Total Cost";
                ResLedgEntry."Total Price" := -ResLedgEntry."Total Price";
            end;
            ResLedgEntry."Direct Unit Cost" := Round(ResLedgEntry."Direct Unit Cost", GLSetup."Unit-Amount Rounding Precision");
            ResLedgEntry."User ID" := UserId;
            ResLedgEntry."Entry No." := NextEntryNo;
            ResUOM.Get(ResLedgEntry."Resource No.", ResLedgEntry."Unit of Measure Code");
            if ResUOM."Related to Base Unit of Meas." then
                ResLedgEntry."Quantity (Base)" := ResLedgEntry.Quantity * ResLedgEntry."Qty. per Unit of Measure";

            if ResLedgEntry."Entry Type" = ResLedgEntry."Entry Type"::Usage then begin
                PostTimeSheetDetail(ResJnlLine, ResLedgEntry."Quantity (Base)");
                ResLedgEntry.Chargeable := IsChargable(ResJnlLine, ResLedgEntry.Chargeable);
            end;

            OnBeforeResLedgEntryInsert(ResLedgEntry, ResJnlLine);

            ResLedgEntry.Insert(true);

            NextEntryNo := NextEntryNo + 1;
        end;

        OnAfterPostResJnlLine(ResJnlLine);
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then
            GLSetup.Get();
        GLSetupRead := true;
    end;

    local procedure PostTimeSheetDetail(ResJnlLine2: Record "Res. Journal Line"; QtyToPost: Decimal)
    var
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetDetail: Record "Time Sheet Detail";
        TimeSheetMgt: Codeunit "Time Sheet Management";
    begin
        with ResJnlLine2 do
            if "Time Sheet No." <> '' then begin
                TimeSheetDetail.Get("Time Sheet No.", "Time Sheet Line No.", "Time Sheet Date");
                TimeSheetDetail."Posted Quantity" += QtyToPost;
                TimeSheetDetail.Posted := TimeSheetDetail.Quantity = TimeSheetDetail."Posted Quantity";
                TimeSheetDetail.Modify();
                TimeSheetLine.Get("Time Sheet No.", "Time Sheet Line No.");
                TimeSheetMgt.CreateTSPostingEntry(TimeSheetDetail, Quantity, "Posting Date", "Document No.", TimeSheetLine.Description);

                TimeSheetDetail.SetRange("Time Sheet No.", "Time Sheet No.");
                TimeSheetDetail.SetRange("Time Sheet Line No.", "Time Sheet Line No.");
                TimeSheetDetail.SetRange(Posted, false);
                if TimeSheetDetail.IsEmpty then begin
                    TimeSheetLine.Posted := true;
                    TimeSheetLine.Modify();
                end;
            end;
    end;

    local procedure IsChargable(ResJournalLine: Record "Res. Journal Line"; Chargeable: Boolean): Boolean
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        if ResJournalLine."Time Sheet No." <> '' then begin
            TimeSheetLine.Get(ResJournalLine."Time Sheet No.", ResJournalLine."Time Sheet Line No.");
            exit(TimeSheetLine.Chargeable);
        end;
        exit(Chargeable);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckResourceBlocked(Resource: Record Resource; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostResJnlLine(var ResJournalLine: Record "Res. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostResJnlLine(var ResJournalLine: Record "Res. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenPostingSetupGet(var ResJournalLine: Record "Res. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeResLedgEntryInsert(var ResLedgerEntry: Record "Res. Ledger Entry"; ResJournalLine: Record "Res. Journal Line")
    begin
    end;
}

