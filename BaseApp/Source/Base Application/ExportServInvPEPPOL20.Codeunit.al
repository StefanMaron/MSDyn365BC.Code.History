codeunit 1606 "Export Serv. Inv. - PEPPOL 2.0"
{
    TableNo = "Record Export Buffer";

    trigger OnRun()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        RecordRef: RecordRef;
    begin
        RecordRef.Get(RecordID);
        RecordRef.SetTable(ServiceInvoiceHeader);

        ServerFilePath := GenerateXMLFile(ServiceInvoiceHeader);

        Modify;
    end;

    [Scope('OnPrem')]
    procedure GenerateXMLFile(ServiceInvoiceHeader: Record "Service Invoice Header"): Text[250]
    var
        PEPPOLManagement: Codeunit "PEPPOL Management";
        SalesInvoicePEPPOL20: XMLport "Sales Invoice - PEPPOL 2.0";
        OutFile: File;
        OutStream: OutStream;
        XmlServerPath: Text;
    begin
        PEPPOLManagement.InitializeXMLExport(OutFile, XmlServerPath);
        OutFile.CreateOutStream(OutStream);
        SalesInvoicePEPPOL20.Initialize(ServiceInvoiceHeader);
        SalesInvoicePEPPOL20.SetDestination(OutStream);
        SalesInvoicePEPPOL20.Export;
        OutFile.Close;

        exit(CopyStr(XmlServerPath, 1, 250));
    end;
}

