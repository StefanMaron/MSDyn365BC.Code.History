codeunit 5641 "FA Reclass. Check Line"
{
    TableNo = "FA Reclass. Journal Line";

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, IsHandled);
        if not IsHandled then begin
            if ("FA No." = '') and ("New FA No." = '') then
                exit;
            if ("FA No." = '') and ("New FA No." <> '') then
                TestField("FA No.");
            if ("FA No." <> '') and ("New FA No." = '') then
                TestField("New FA No.");
            TestField("FA Posting Date");
            TestField("FA No.");
            TestField("New FA No.");
            TestField("Depreciation Book Code");
            if DeprBookCode = '' then
                DeprBookCode := "Depreciation Book Code";

            if "Depreciation Book Code" <> DeprBookCode then
                FieldError("Depreciation Book Code", Text000);
        end;
        OnAfterOnRun(Rec);
    end;

    var
        Text000: Label 'must be the same in all journal lines';
        DeprBookCode: Code[10];

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(var FAReclassJournalLine: Record "FA Reclass. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var FAReclassJournalLine: Record "FA Reclass. Journal Line"; var IsHandled: Boolean)
    begin
    end;
}

