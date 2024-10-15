codeunit 28073 "Purch. Tax Cr.Memo-Printed"
{
    Permissions = TableData "Purch. Tax Cr. Memo Hdr." = rimd;
    TableNo = "Purch. Tax Cr. Memo Hdr.";

    trigger OnRun()
    begin
        Find;
        "No. Printed" := "No. Printed" + 1;
        Modify;
        Commit;
    end;
}

