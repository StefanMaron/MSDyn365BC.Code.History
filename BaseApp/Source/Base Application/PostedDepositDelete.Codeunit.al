codeunit 10144 "Posted Deposit-Delete"
{
    Permissions = TableData "Posted Deposit Header" = rd,
                  TableData "Posted Deposit Line" = rd;
    TableNo = "Posted Deposit Header";

    trigger OnRun()
    begin
        PostedDepositLine.SetRange("Deposit No.", "No.");
        PostedDepositLine.DeleteAll();

        Delete;
    end;

    var
        PostedDepositLine: Record "Posted Deposit Line";
}

