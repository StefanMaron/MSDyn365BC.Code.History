namespace Microsoft.Sales.Peppol;

using Microsoft.Sales.History;
using System.IO;

codeunit 1601 "Export Sales Cr.M. - PEPPOL2.1"
{
    TableNo = "Record Export Buffer";

    trigger OnRun()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        RecordRef: RecordRef;
        OutStr: OutStream;
    begin
        RecordRef.Get(Rec.RecordID);
        RecordRef.SetTable(SalesCrMemoHeader);

        Rec."File Content".CreateOutStream(OutStr);
        GenerateXMLFile(SalesCrMemoHeader, OutStr);

        Rec.Modify();
    end;

    [Scope('OnPrem')]
    procedure GenerateXMLFile(VariantRec: Variant; var OutStr: OutStream)
    var
        SalesCreditMemoPEPPOL: XMLport "Sales Credit Memo - PEPPOL 2.1";
    begin
        SalesCreditMemoPEPPOL.Initialize(VariantRec);
        SalesCreditMemoPEPPOL.SetDestination(OutStr);
        SalesCreditMemoPEPPOL.Export();
    end;
}

