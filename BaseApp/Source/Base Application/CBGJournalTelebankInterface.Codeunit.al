codeunit 11000002 "CBG Journal Telebank Interface"
{

    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure InsertPaymentHistory(CBGStatement: Record "CBG Statement")
    var
        PaymHistOverview: Page "Payment History List";
        PaymHist: Record "Payment History";
        PaymentHistLine: Record "Payment History Line";
        CBGStatementLine: Record "CBG Statement Line";
    begin
        with CBGStatement do begin
            TestField(Type, Type::"Bank/Giro");
            TestField("Account Type", "Account Type"::"Bank Account");

            PaymHist.SetCurrentKey("Our Bank", Status);
            PaymHist.Ascending(false);
            PaymHist.SetRange("Our Bank", "Account No.");
            PaymHist.SetRange(Status, PaymHist.Status::Transmitted);
            PaymHist.SetFilter("Remaining Amount", '<>%1', 0);

            PaymHistOverview.SetTableView(PaymHist);
            PaymHistOverview.LookupMode(true);
            PaymHistOverview.Editable(false);
            if PaymHistOverview.RunModal = ACTION::LookupOK then begin
                PaymHistOverview.GetRecord(PaymHist);
                PaymentHistLine.SetCurrentKey("Our Bank", Status);
                PaymentHistLine.SetRange("Our Bank", PaymHist."Our Bank");
                PaymentHistLine.SetRange("Run No.", PaymHist."Run No.");
                PaymentHistLine.SetFilter(Status, '%1|%2',
                  PaymentHistLine.Status::Transmitted,
                  PaymentHistLine.Status::"Request for Cancellation");
                if PaymentHistLine.Find('-') then begin
                    CBGStatementLine.SetRange("Journal Template Name", "Journal Template Name");
                    CBGStatementLine.SetRange("No.", "No.");
                    repeat
                        if CBGStatementLine.FindLast then
                            CBGStatementLine."Line No." := CBGStatementLine."Line No." + 10000
                        else begin
                            CBGStatementLine."Line No." := 10000;
                            CBGStatementLine."Journal Template Name" := "Journal Template Name";
                            CBGStatementLine."No." := "No.";
                        end;
                        CBGStatementLine.Init;
                        CBGStatementLine.InitRecord(CBGStatementLine);
                        CBGStatementLine.Validate(Identification, PaymentHistLine.Identification);
                        CBGStatementLine.Insert(true);
                        CBGStatementLine."Amount Settled" := CBGStatementLine.Amount;
                        CBGStatementLine.Validate(Amount);
                        CBGStatementLine.Validate("Shortcut Dimension 1 Code", PaymentHistLine."Global Dimension 1 Code");
                        CBGStatementLine.Validate("Shortcut Dimension 2 Code", PaymentHistLine."Global Dimension 2 Code");
                        CBGStatementLine.Modify(true);
                    until PaymentHistLine.Next = 0;
                end;
            end;
        end;
    end;
}

