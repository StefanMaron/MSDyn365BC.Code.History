codeunit 17406 "Payroll Document - Post (Y/N)"
{
    TableNo = "Payroll Document";

    trigger OnRun()
    begin
        PayrollDoc.Copy(Rec);
        Code;
        Rec := PayrollDoc;
    end;

    var
        PayrollDoc: Record "Payroll Document";
        Text001: Label 'Do you want to post %1?';

    local procedure "Code"()
    var
        PayrollDocumentPost: Codeunit "Payroll Document - Post";
    begin
        with PayrollDoc do begin
            if not Confirm(StrSubstNo(Text001, TableCaption), false) then
                exit;

            PayrollDocumentPost.Run(PayrollDoc);
        end;
    end;
}

