namespace Microsoft.Sales.Peppol;

using Microsoft.Service.History;
using System.IO;

codeunit 1608 "Exp. Service Cr.M. - PEPPOL2.1"
{
    TableNo = "Record Export Buffer";

    trigger OnRun()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        RecordRef: RecordRef;
        OutStr: OutStream;
    begin
        RecordRef.Get(Rec.RecordID);
        RecordRef.SetTable(ServiceCrMemoHeader);

        Rec."File Content".CreateOutStream(OutStr);
        GenerateXMLFile(ServiceCrMemoHeader, OutStr);

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

