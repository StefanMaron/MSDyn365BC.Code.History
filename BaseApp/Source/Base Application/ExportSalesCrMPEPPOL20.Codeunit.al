codeunit 1603 "Export Sales Cr.M. - PEPPOL2.0"
{
    TableNo = "Record Export Buffer";

    trigger OnRun()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        RecordRef: RecordRef;
    begin
        RecordRef.Get(RecordID);
        RecordRef.SetTable(SalesCrMemoHeader);

        ServerFilePath := GenerateXMLFile(SalesCrMemoHeader);

        Modify;
    end;

    [Scope('OnPrem')]
    procedure GenerateXMLFile(VariantRec: Variant): Text[250]
    var
        PEPPOLManagement: Codeunit "PEPPOL Management";
        SalesCreditMemoPEPPOL20: XMLport "Sales Credit Memo - PEPPOL 2.0";
        OutFile: File;
        OutStream: OutStream;
        XmlServerPath: Text;
    begin
        PEPPOLManagement.InitializeXMLExport(OutFile, XmlServerPath);

        OutFile.CreateOutStream(OutStream);
        SalesCreditMemoPEPPOL20.Initialize(VariantRec);
        SalesCreditMemoPEPPOL20.SetDestination(OutStream);
        SalesCreditMemoPEPPOL20.Export;
        OutFile.Close;

        exit(CopyStr(XmlServerPath, 1, 250));
    end;
}

