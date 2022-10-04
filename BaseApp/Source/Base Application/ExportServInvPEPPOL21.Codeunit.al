codeunit 1604 "Export Serv. Inv. - PEPPOL 2.1"
{
    TableNo = "Record Export Buffer";

    trigger OnRun()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        RecordRef: RecordRef;
        OutStr: OutStream;
    begin
        RecordRef.Get(Rec.RecordID);
        RecordRef.SetTable(ServiceInvoiceHeader);

        Rec."File Content".CreateOutStream(OutStr);
        GenerateXMLFile(ServiceInvoiceHeader, OutStr);

        Rec.Modify();
    end;

    [Scope('OnPrem')]
    procedure GenerateXMLFile(VariantRec: Variant; var OutStr: OutStream)
    var
        SalesInvoicePEPPOL: XMLport "Sales Invoice - PEPPOL 2.1";
    begin
        SalesInvoicePEPPOL.Initialize(VariantRec);
        SalesInvoicePEPPOL.SetDestination(OutStr);
        SalesInvoicePEPPOL.Export();
    end;

#if not CLEAN20
    [Scope('OnPrem')]
    [Obsolete('Replaced by GenerateXMLFile with OutStream parameter.', '20.0')]
    procedure GenerateXMLFile(ServiceInvoiceHeader: Record "Service Invoice Header"): Text[250]
    var
        PEPPOLManagement: Codeunit "PEPPOL Management";
        OutFile: File;
        OutStream: OutStream;
        XmlServerPath: Text;
    begin
        PEPPOLManagement.InitializeXMLExport(OutFile, XmlServerPath);

        OutFile.CreateOutStream(OutStream);
        GenerateXMLFile(ServiceInvoiceHeader, OutStream);
        OutFile.Close();

        exit(CopyStr(XmlServerPath, 1, 250));
    end;
#endif
}

