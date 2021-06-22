codeunit 1600 "Export Sales Inv. - PEPPOL 2.1"
{
    TableNo = "Record Export Buffer";

    trigger OnRun()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        RecordRef: RecordRef;
    begin
        RecordRef.Get(RecordID);
        RecordRef.SetTable(SalesInvoiceHeader);

        ServerFilePath := GenerateXMLFile(SalesInvoiceHeader);

        Modify;
    end;

    [Scope('OnPrem')]
    procedure GenerateXMLFile(VariantRec: Variant): Text[250]
    var
        PEPPOLManagement: Codeunit "PEPPOL Management";
        SalesInvoicePEPPOL: XMLport "Sales Invoice - PEPPOL 2.1";
        OutFile: File;
        OutStream: OutStream;
        XmlServerPath: Text;
    begin
        PEPPOLManagement.InitializeXMLExport(OutFile, XmlServerPath);

        OutFile.CreateOutStream(OutStream);
        SalesInvoicePEPPOL.Initialize(VariantRec);
        SalesInvoicePEPPOL.SetDestination(OutStream);
        SalesInvoicePEPPOL.Export;
        OutFile.Close;

        exit(CopyStr(XmlServerPath, 1, 250));
    end;
}

