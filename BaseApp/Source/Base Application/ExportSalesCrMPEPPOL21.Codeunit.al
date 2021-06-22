codeunit 1601 "Export Sales Cr.M. - PEPPOL2.1"
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
        SalesCreditMemoPEPPOL: XMLport "Sales Credit Memo - PEPPOL 2.1";
        OutFile: File;
        OutStream: OutStream;
        XmlServerPath: Text;
    begin
        PEPPOLManagement.InitializeXMLExport(OutFile, XmlServerPath);

        OutFile.CreateOutStream(OutStream);
        SalesCreditMemoPEPPOL.Initialize(VariantRec);
        SalesCreditMemoPEPPOL.SetDestination(OutStream);
        SalesCreditMemoPEPPOL.Export;
        OutFile.Close;

        exit(CopyStr(XmlServerPath, 1, 250));
    end;
}

