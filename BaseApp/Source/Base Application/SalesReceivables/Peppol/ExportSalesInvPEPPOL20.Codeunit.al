codeunit 1602 "Export Sales Inv. - PEPPOL 2.0"
{
    TableNo = "Record Export Buffer";

    trigger OnRun()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        RecordRef: RecordRef;
        OutStr: OutStream;
    begin
        RecordRef.Get(Rec.RecordID);
        RecordRef.SetTable(SalesInvoiceHeader);

        Rec."File Content".CreateOutStream(OutStr);
        GenerateXMLFile(SalesInvoiceHeader, OutStr);

        Rec.Modify();
    end;

    [Scope('OnPrem')]
    procedure GenerateXMLFile(VariantRec: Variant; var OutStr: OutStream)
    var
        SalesInvoicePEPPOL20: XMLport "Sales Invoice - PEPPOL 2.0";
    begin
        SalesInvoicePEPPOL20.Initialize(VariantRec);
        SalesInvoicePEPPOL20.SetDestination(OutStr);
        SalesInvoicePEPPOL20.Export();
    end;

#if not CLEAN20
    [Scope('OnPrem')]
    [Obsolete('Replaced by GenerateXMLFile with OutStream parameter.', '20.0')]
    procedure GenerateXMLFile(VariantRec: Variant): Text[250]
    var
        PEPPOLManagement: Codeunit "PEPPOL Management";
        OutFile: File;
        OutStream: OutStream;
        XmlServerPath: Text;
    begin
        PEPPOLManagement.InitializeXMLExport(OutFile, XmlServerPath);

        OutFile.CreateOutStream(OutStream);
        GenerateXMLFile(VariantRec, OutStream);
        OutFile.Close();

        exit(CopyStr(XmlServerPath, 1, 250));
    end;
#endif
}

