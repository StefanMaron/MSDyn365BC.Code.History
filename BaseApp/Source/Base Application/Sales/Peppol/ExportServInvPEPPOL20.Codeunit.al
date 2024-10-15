namespace Microsoft.Sales.Peppol;

using Microsoft.Service.History;
using System.IO;

codeunit 1606 "Export Serv. Inv. - PEPPOL 2.0"
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
        SalesInvoicePEPPOL20: XMLport "Sales Invoice - PEPPOL 2.0";
    begin
        SalesInvoicePEPPOL20.Initialize(VariantRec);
        SalesInvoicePEPPOL20.SetDestination(OutStr);
        SalesInvoicePEPPOL20.Export();
    end;
}

