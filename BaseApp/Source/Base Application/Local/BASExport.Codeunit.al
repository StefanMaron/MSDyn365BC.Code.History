codeunit 11604 "BAS Export"
{
    TableNo = "VAT Report Header";

    trigger OnRun()
    var
        BASManagement: Codeunit "BAS Management";
    begin
        BASManagement.ExportBASReport(
          Rec, BASManagement.SaveBASTemplateToServerFile("BAS ID No.", "BAS Version No."));
        Status := Status::Accepted;
        Modify();
    end;
}

