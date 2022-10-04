codeunit 1612 "Exp. Serv.Inv. PEPPOL BIS3.0"
{
    TableNo = "Record Export Buffer";

    trigger OnRun()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        PEPPOLValidation: Codeunit "PEPPOL Validation";
        RecordRef: RecordRef;
        OutStr: OutStream;
    begin
        RecordRef.Get(Rec.RecordID);
        RecordRef.SetTable(ServiceInvoiceHeader);

        PEPPOLValidation.CheckServiceInvoice(ServiceInvoiceHeader);

        Rec."File Content".CreateOutStream(OutStr);
        GenerateXMLFile(ServiceInvoiceHeader, OutStr);

        Rec.Modify();
    end;

    [Scope('OnPrem')]
    procedure GenerateXMLFile(VariantRec: Variant; var OutStr: OutStream)
    var
        SalesInvoicePEPPOLBIS30: XMLport "Sales Invoice - PEPPOL BIS 3.0";
    begin
        SalesInvoicePEPPOLBIS30.Initialize(VariantRec);
        SalesInvoicePEPPOLBIS30.SetDestination(OutStr);
        SalesInvoicePEPPOLBIS30.Export();
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

