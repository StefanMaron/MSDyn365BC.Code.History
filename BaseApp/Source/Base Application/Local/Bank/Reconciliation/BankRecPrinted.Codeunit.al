codeunit 10124 "BankRec-Printed"
{
    Permissions = TableData "Posted Bank Rec. Header" = rm;
    TableNo = "Posted Bank Rec. Header";

    trigger OnRun()
    begin
        Rec.Find();
        Rec."No. Printed" := Rec."No. Printed" + 1;
        Rec.Modify();
        Commit();
    end;
}
