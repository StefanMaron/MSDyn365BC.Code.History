codeunit 12175 "Vendor Bills Floppy"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    begin
        VendorBillHeader.SetRange("No.", GetFilter("Document No."));
        if VendorBillHeader.IsEmpty then
            Error(ExportVendBillHdrErr);
        SEPADDExportMgt.DeleteExportErrors(GetFilter("Document No."), '');
        Commit();
        REPORT.Run(REPORT::"Vendor Bills Floppy", false, false, VendorBillHeader);
    end;

    var
        VendorBillHeader: Record "Vendor Bill Header";
        ExportVendBillHdrErr: Label 'Your export format is not set up to export vendor bills with this function. Use the function in the Vendor Bill List Sent Card window instead.';
        SEPADDExportMgt: Codeunit "SEPA - DD Export Mgt.";
}

