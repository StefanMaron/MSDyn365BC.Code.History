namespace Microsoft.Sales.Peppol;

using Microsoft.Sales.History;
using System.IO;

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
}

