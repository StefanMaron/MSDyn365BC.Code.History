codeunit 10125 "Posted Bank Rec.-Delete"
{
    Permissions = TableData "Bank Comment Line" = rd,
                  TableData "Posted Bank Rec. Header" = rd,
                  TableData "Posted Bank Rec. Line" = rd;
    TableNo = "Posted Bank Rec. Header";

    trigger OnRun()
    begin
        PostedBankRecLines.SetRange("Bank Account No.", "Bank Account No.");
        PostedBankRecLines.SetRange("Statement No.", "Statement No.");
        PostedBankRecLines.DeleteAll();

        BankRecCommentLines.SetRange("Table Name", BankRecCommentLines."Table Name"::"Posted Bank Rec.");
        BankRecCommentLines.SetRange("Bank Account No.", "Bank Account No.");
        BankRecCommentLines.SetRange("No.", "Statement No.");
        BankRecCommentLines.DeleteAll();

        OnRunOnBeforeDelete(Rec);
        Delete;
    end;

    var
        PostedBankRecLines: Record "Posted Bank Rec. Line";
        BankRecCommentLines: Record "Bank Comment Line";

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeDelete(var PostedBankRecHeader: Record "Posted Bank Rec. Header")
    begin
    end;
}

