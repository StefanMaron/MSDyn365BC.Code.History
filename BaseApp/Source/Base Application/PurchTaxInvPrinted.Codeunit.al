codeunit 28071 "Purch. Tax Inv.-Printed"
{
    Permissions = TableData "Purch. Tax Inv. Header" = rimd;
    TableNo = "Purch. Tax Inv. Header";

    trigger OnRun()
    begin
        Find;
        "No. Printed" := "No. Printed" + 1;
        Modify;
        Commit;
    end;
}

