codeunit 31105 "VAT Control Report DPHKH1 CZL" implements "VAT Control Report Export CZL"
{
    procedure ExportToXMLFile(VATCtrlReportHeaderCZL: Record "VAT Ctrl. Report Header CZL"): Text
    var
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        ClientFileNameLbl: Label 'VAT Control Report %1.xml', Comment = '%1 = VAT Control Report number';
    begin
        ExportToXMLBlob(VATCtrlReportHeaderCZL, TempBlob);
        if TempBlob.HasValue() then
            exit(FileManagement.BLOBExport(TempBlob, StrSubstNo(ClientFileNameLbl, VATCtrlReportHeaderCZL."No."), true));
    end;

    procedure ExportToXMLBlob(VATCtrlReportHeaderCZL: Record "VAT Ctrl. Report Header CZL"; var TempBlob: Codeunit "Temp Blob")
    var
        ExportVATCtrlDialogCZL: Report "Export VAT Ctrl. Dialog CZL";
        VATStmtXMLExportHelperCZL: Codeunit "VAT Stmt XML Export Helper CZL";
        VATControlReportCZL: XMLport "VAT Control Report DPHKH1 CZL";
        OutputStream: OutStream;
        XmlParams: Text;
    begin
        XmlParams := VATStmtXMLExportHelperCZL.GetReportRequestPageParameters(Report::"Export VAT Ctrl. Dialog CZL");
        VATStmtXMLExportHelperCZL.UpdateParamsVATCtrlReportHeader(XmlParams, VATCtrlReportHeaderCZL);
        XmlParams := ExportVATCtrlDialogCZL.RunRequestPage(XmlParams);
        if XmlParams = '' then
            exit;
        VATStmtXMLExportHelperCZL.SaveReportRequestPageParameters(Report::"Export VAT Ctrl. Dialog CZL", XmlParams);

        TempBlob.CreateOutStream(OutputStream);
        VATControlReportCZL.SetXMLParams(XmlParams);
        VATControlReportCZL.SetDestination(OutputStream);
        VATControlReportCZL.Export();
    end;
}