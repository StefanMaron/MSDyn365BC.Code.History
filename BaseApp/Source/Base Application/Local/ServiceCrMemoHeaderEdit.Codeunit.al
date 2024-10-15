codeunit 12188 "Service Cr. Memo Header - Edit"
{
    Permissions = TableData "Service Cr.Memo Header" = rm;
    TableNo = "Service Cr.Memo Header";

    trigger OnRun()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        ServiceCrMemoHeader := Rec;
        ServiceCrMemoHeader.LockTable();
        ServiceCrMemoHeader.Find();
        ServiceCrMemoHeader."Fattura Document Type" := "Fattura Document Type";
        OnRunOnBeforeServiceCrMemoHeaderModify(ServiceCrMemoHeader, Rec);
        ServiceCrMemoHeader.TestField("No.", "No.");
        ServiceCrMemoHeader.Modify();
        Rec := ServiceCrMemoHeader;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeServiceCrMemoHeaderModify(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; FromServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
    end;
}

