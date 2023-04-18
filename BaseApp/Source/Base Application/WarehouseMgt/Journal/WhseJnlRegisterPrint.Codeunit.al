codeunit 7309 "Whse. Jnl.-Register+Print"
{
    TableNo = "Warehouse Journal Line";

    trigger OnRun()
    begin
        WhseJnlLine.Copy(Rec);
        Code();
        Copy(WhseJnlLine);
    end;

    var
        WhseJnlTemplate: Record "Warehouse Journal Template";
        WhseJnlLine: Record "Warehouse Journal Line";
        WarehouseReg: Record "Warehouse Register";
        WhseJnlRegisterBatch: Codeunit "Whse. Jnl.-Register Batch";
        TempJnlBatchName: Code[10];
        IsHandled: Boolean;

        Text001: Label 'Do you want to register the journal lines?';
        Text002: Label 'There is nothing to register.';
        Text003: Label 'The journal lines were successfully registered.';
        Text004: Label 'You are now in the %1 journal.';

    local procedure "Code"()
    begin
        with WhseJnlLine do begin
            WhseJnlTemplate.Get("Journal Template Name");
            WhseJnlTemplate.TestField("Registering Report ID");

            if not Confirm(Text001, false) then
                exit;

            IsHandled := false;
            OnAfterConfirm(WhseJnlLine, IsHandled);
            if IsHandled then
                exit;

            TempJnlBatchName := "Journal Batch Name";

            WhseJnlRegisterBatch.Run(WhseJnlLine);
            OnAfterRegisterBatch(WhseJnlLine);

            if WarehouseReg.Get(WhseJnlRegisterBatch.GetWhseRegNo()) then begin
                WarehouseReg.SetRecFilter();
                REPORT.Run(WhseJnlTemplate."Registering Report ID", false, false, WarehouseReg);
            end;

            if "Line No." = 0 then
                Message(Text002)
            else
                if TempJnlBatchName = "Journal Batch Name" then
                    Message(Text003)
                else
                    Message(
                      Text003 +
                      Text004,
                      "Journal Batch Name");

            if not Find('=><') or (TempJnlBatchName <> "Journal Batch Name") then begin
                Reset();
                FilterGroup(2);
                SetRange("Journal Template Name", "Journal Template Name");
                SetRange("Journal Batch Name", "Journal Batch Name");
                SetRange("Location Code", "Location Code");
                FilterGroup(0);
                "Line No." := 10000;
            end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConfirm(var WarehouseJournalLine: Record "Warehouse Journal Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRegisterBatch(var WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
    end;
}

