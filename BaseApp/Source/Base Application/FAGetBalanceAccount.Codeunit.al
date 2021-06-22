codeunit 5603 "FA Get Balance Account"
{

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'Do you want to insert a line for the balancing account that is related to the selected lines?';
        FAInsertGLAcc: Codeunit "FA Insert G/L Account";

    procedure InsertAcc(var GenJnlLine: Record "Gen. Journal Line")
    begin
        ClearAll;
        with GenJnlLine do begin
            if Count > 1 then
                if not Confirm(Text000) then
                    exit;
            if Find('+') then
                repeat
                    FAInsertGLAcc.GetBalAcc(GenJnlLine);
                until Next(-1) = 0;
        end;
    end;

    procedure InsertAccWithBalAccountInfo(var GenJnlLine: Record "Gen. Journal Line"; BalAccountType: Option; BalAccountNo: Code[20])
    begin
        ClearAll;
        with GenJnlLine do begin
            if Count > 1 then
                if not Confirm(Text000) then
                    exit;
            if Find('+') then
                repeat
                    FAInsertGLAcc.GetBalAccWithBalAccountInfo(GenJnlLine, BalAccountType, BalAccountNo);
                until Next(-1) = 0;
        end;
    end;
}

