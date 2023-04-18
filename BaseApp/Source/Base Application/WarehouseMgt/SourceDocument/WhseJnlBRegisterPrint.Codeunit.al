codeunit 7300 "Whse. Jnl.-B.Register+Print"
{
    TableNo = "Warehouse Journal Batch";

    trigger OnRun()
    begin
        WhseJnlBatch.Copy(Rec);
        Code();
        Copy(WhseJnlBatch);
    end;

    var
        WhseJnlTemplate: Record "Warehouse Journal Template";
        WhseJnlBatch: Record "Warehouse Journal Batch";
        WhseJnlLine: Record "Warehouse Journal Line";
        WhseReg: Record "Warehouse Register";
        WhseJnlRegisterBatch: Codeunit "Whse. Jnl.-Register Batch";
        JnlWithErrors: Boolean;

        Text000: Label 'Do you want to register the journals?';
        Text001: Label 'The journals were successfully registered.';
        Text002: Label 'It was not possible to register all of the journals. ';
        Text003: Label 'The journals that were not successfully registered are now marked.';

    local procedure "Code"()
    begin
        with WhseJnlBatch do begin
            WhseJnlTemplate.Get("Journal Template Name");
            WhseJnlTemplate.TestField("Registering Report ID");

            if not Confirm(Text000, false) then
                exit;

            Find('-');
            repeat
                WhseJnlLine."Journal Template Name" := "Journal Template Name";
                WhseJnlLine."Journal Batch Name" := Name;
                WhseJnlLine."Location Code" := "Location Code";
                WhseJnlLine."Line No." := 10000;
                Clear(WhseJnlRegisterBatch);
                if WhseJnlRegisterBatch.Run(WhseJnlLine) then begin
                    OnAfterRegisterBatch(WhseJnlLine);
                    Mark(false);
                    if WhseReg.Get(WhseJnlLine."Line No.") then begin
                        WhseReg.SetRecFilter();
                        REPORT.Run(WhseJnlTemplate."Registering Report ID", false, false, WhseReg);
                    end;
                end else begin
                    Mark(true);
                    JnlWithErrors := true;
                end;
            until Next() = 0;

            if not JnlWithErrors then
                Message(Text001)
            else
                Message(
                  Text002 +
                  Text003);

            if not Find('=><') then begin
                Reset();
                FilterGroup(2);
                SetRange("Journal Template Name", "Journal Template Name");
                SetRange("Location Code", "Location Code");
                FilterGroup(0);
                Name := '';
            end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRegisterBatch(var WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
    end;
}

