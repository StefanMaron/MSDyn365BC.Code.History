codeunit 17302 "Tax Diff.-Post Jnl. Batch"
{
    TableNo = "Tax Diff. Journal Line";

    trigger OnRun()
    begin
        ClearAll;
        with TaxDiffJnlLine do begin
            Copy(Rec);
            if FindSet() then begin
                Wnd.Open(Text1001 + Text1002);
                Total := Count;
                repeat
                    if not "Partial Disposal" then begin
                        Processing += 1;
                        Wnd.Update(1, "Journal Batch Name");
                        Wnd.Update(2, Processing);
                        Wnd.Update(3, Round((Processing / Total) * 10000, 1));
                        if not EmptyLine then
                            TaxDiffPostJnlLine.RunWithCheck(TaxDiffJnlLine);
                        Delete;
                    end;
                until Next() = 0;
                if FindSet() then
                    repeat
                        if "Partial Disposal" then begin
                            Processing += 1;
                            Wnd.Update(1, "Journal Batch Name");
                            Wnd.Update(2, Processing);
                            Wnd.Update(3, Round((Processing / Total) * 10000, 1));
                            if not EmptyLine then
                                TaxDiffPostJnlLine.RunWithCheck(TaxDiffJnlLine);
                            Delete;
                        end;
                    until Next() = 0;
                Wnd.Close;
            end;
        end;
    end;

    var
        TaxDiffJnlLine: Record "Tax Diff. Journal Line";
        TaxDiffPostJnlLine: Codeunit "Tax Diff.-Post Jnl. Line";
        Wnd: Dialog;
        Total: Integer;
        Processing: Integer;
        Text1001: Label 'Journal Batch Name  #1##########\';
        Text1002: Label 'Posting lines       #2###### @3@@@@@@@@@@@@@';

    local procedure EmptyLine(): Boolean
    begin
        with TaxDiffJnlLine do
            exit(
              ("Asset Tax Amount" = 0) and
              ("Liability Tax Amount" = 0) and
              ("Disposal Mode" = "Disposal Mode"::" "));
    end;
}

