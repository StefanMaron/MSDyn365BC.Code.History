codeunit 7303 "Whse. Jnl.-Register"
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
        TempJnlBatchName: Code[10];

        Text001: Label 'Do you want to register the journal lines?';
        Text002: Label 'There is nothing to register.';
        Text003: Label 'The journal lines were successfully registered.';
        Text004: Label 'You are now in the %1 journal.';
        Text005: Label 'Do you want to register and post the journal lines?';

    local procedure "Code"()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCode(WhseJnlLine, IsHandled);
        if IsHandled then
            exit;

        with WhseJnlLine do begin
            WhseJnlTemplate.Get("Journal Template Name");
            WhseJnlTemplate.TestField("Force Registering Report", false);

            if not ConfirmRegisterLines(WhseJnlLine) then
                exit;

            TempJnlBatchName := "Journal Batch Name";

            CODEUNIT.Run(CODEUNIT::"Whse. Jnl.-Register Batch", WhseJnlLine);

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

    local procedure ConfirmRegisterLines(WhseJnlLine: Record "Warehouse Journal Line") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmRegisterLines(WhseJnlLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        with WhseJnlLine do
            if ItemTrackingReclass("Journal Template Name", "Journal Batch Name", "Location Code", 0) then begin
                if not Confirm(Text005, false) then
                    exit(false)
            end else
                if not Confirm(Text001, false) then
                    exit(false);

        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var WhseJnlLine: Record "Warehouse Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmRegisterLines(var WhseJnlLine: Record "Warehouse Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

