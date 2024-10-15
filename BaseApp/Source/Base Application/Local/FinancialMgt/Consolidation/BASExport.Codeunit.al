codeunit 11604 "BAS Export"
{
    TableNo = "VAT Report Header";

    trigger OnRun()
    var
        BASManagement: Codeunit "BAS Management";
    begin
        BASManagement.ExportBASReport(
          Rec, BASManagement.SaveBASTemplateToServerFile(Rec."BAS ID No.", Rec."BAS Version No."));
        Rec.Status := Rec.Status::Accepted;
        Rec.Modify();
    end;
}

