codeunit 5641 "FA Reclass. Check Line"
{
    TableNo = "FA Reclass. Journal Line";

    trigger OnRun()
    begin
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

        CheckNewDeprBookCode(Rec);

        OnAfterOnRun(Rec);
    end;

    var
        Text000: Label 'must be the same in all journal lines';
        GLSetup: Record "General Ledger Setup";
        DeprBookCode: Code[10];
        NewDeprBookCode: Code[10];
        Text001: Label 'must be the same in all journal lines';

    local procedure CheckNewDeprBookCode(FAReclassJnlLine: Record "FA Reclass. Journal Line")
    begin
        GLSetup.Get;
        if not GLSetup."Enable Russian Accounting" then
            exit;

        with FAReclassJnlLine do begin
            TestField("New Depreciation Book Code");

            if NewDeprBookCode = '' then
                NewDeprBookCode := "New Depreciation Book Code";

            if "New Depreciation Book Code" <> NewDeprBookCode then
                FieldError("New Depreciation Book Code", Text001);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(var FAReclassJournalLine: Record "FA Reclass. Journal Line")
    begin
    end;
}

