codeunit 1613 "Exp. Serv.CrM. PEPPOL BIS3.0"
{
    TableNo = "Record Export Buffer";

    trigger OnRun()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        RecordRef: RecordRef;
    begin
        RecordRef.Get(RecordID);
        RecordRef.SetTable(ServiceCrMemoHeader);

        ServerFilePath := GenerateXMLFile(ServiceCrMemoHeader);

        Modify;
    end;

    [Scope('OnPrem')]
    procedure GenerateXMLFile(VariantRec: Variant): Text[250]
    var
        PEPPOLManagement: Codeunit "PEPPOL Management";
        SalesCrMemoPEPPOLBIS30: XMLport "Sales Cr.Memo - PEPPOL BIS 3.0";
        OutFile: File;
        OutStream: OutStream;
        XmlServerPath: Text;
    begin
        PEPPOLManagement.InitializeXMLExport(OutFile, XmlServerPath);

        OutFile.CreateOutStream(OutStream);
        SalesCrMemoPEPPOLBIS30.Initialize(VariantRec);
        SalesCrMemoPEPPOLBIS30.SetDestination(OutStream);
        SalesCrMemoPEPPOLBIS30.Export;
        OutFile.Close;

        exit(CopyStr(XmlServerPath, 1, 250));
    end;
}

