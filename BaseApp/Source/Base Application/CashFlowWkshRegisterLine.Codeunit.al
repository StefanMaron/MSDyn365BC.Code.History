codeunit 846 "Cash Flow Wksh. -Register Line"
{
    Permissions = TableData "Cash Flow Forecast Entry" = imd;
    TableNo = "Cash Flow Worksheet Line";

    trigger OnRun()
    begin
        GLSetup.Get();
        RunWithCheck(Rec);
    end;

    var
        CFWkshLine: Record "Cash Flow Worksheet Line";
        CFForecastEntry: Record "Cash Flow Forecast Entry";
        CashFlowForecast: Record "Cash Flow Forecast";
        GLSetup: Record "General Ledger Setup";
        CFAccount: Record "Cash Flow Account";
        CFWkshCheckLine: Codeunit "Cash Flow Wksh.- Check Line";
        NextEntryNo: Integer;

    procedure RunWithCheck(var CFWkshLine2: Record "Cash Flow Worksheet Line")
    begin
        CFWkshLine.Copy(CFWkshLine2);
        Code;
        CFWkshLine2 := CFWkshLine;
    end;

    local procedure "Code"()
    begin
        with CFWkshLine do begin
            if EmptyLine then
                exit;

            CFWkshCheckLine.RunCheck(CFWkshLine);

            if NextEntryNo = 0 then begin
                CFForecastEntry.LockTable();
                NextEntryNo := CFForecastEntry.GetLastEntryNo() + 1;
            end;

            CashFlowForecast.Get("Cash Flow Forecast No.");
            if "Cash Flow Account No." <> '' then begin
                CFAccount.Get("Cash Flow Account No.");
                CFAccount.TestField(Blocked, false);
            end;

            CFForecastEntry.Init();
            CFForecastEntry."Cash Flow Forecast No." := "Cash Flow Forecast No.";
            CFForecastEntry."Cash Flow Date" := "Cash Flow Date";
            CFForecastEntry."Document No." := "Document No.";
            CFForecastEntry."Document Date" := "Document Date";
            CFForecastEntry."Cash Flow Account No." := "Cash Flow Account No.";
            CFForecastEntry."Source Type" := "Source Type";
            CFForecastEntry."Source No." := "Source No.";
            CFForecastEntry."G/L Budget Name" := "G/L Budget Name";
            CFForecastEntry.Description := Description;
            CFForecastEntry."Payment Discount" := Round("Payment Discount", 0.00001);
            CFForecastEntry."Associated Entry No." := "Associated Entry No.";
            CFForecastEntry.Overdue := Overdue;
            CFForecastEntry."Global Dimension 2 Code" := "Shortcut Dimension 2 Code";
            CFForecastEntry."Global Dimension 1 Code" := "Shortcut Dimension 1 Code";
            CFForecastEntry."Dimension Set ID" := "Dimension Set ID";
            CFForecastEntry."Amount (LCY)" := Round("Amount (LCY)", 0.00001);
            CFForecastEntry.Positive := CFForecastEntry."Amount (LCY)" > 0;

            if CFForecastEntry.Description = CashFlowForecast.Description then
                CFForecastEntry.Description := '';
            CFForecastEntry."User ID" := UserId;
            CFForecastEntry."Entry No." := NextEntryNo;

            OnAfterCreateForecastEntry(CFForecastEntry, CFWkshLine);
            CFForecastEntry.Insert();

            NextEntryNo := NextEntryNo + 1;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateForecastEntry(var CashFlowForecastEntry: Record "Cash Flow Forecast Entry"; CashFlowWorksheetLine: Record "Cash Flow Worksheet Line")
    begin
    end;
}

