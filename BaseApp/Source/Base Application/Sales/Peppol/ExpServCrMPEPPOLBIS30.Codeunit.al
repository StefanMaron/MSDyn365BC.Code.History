namespace Microsoft.Sales.Peppol;

using Microsoft.Service.History;
using System.IO;

codeunit 1613 "Exp. Serv.CrM. PEPPOL BIS3.0"
{
    TableNo = "Record Export Buffer";

    trigger OnRun()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        PEPPOLValidation: Codeunit "PEPPOL Validation";
        RecordRef: RecordRef;
        OutStr: OutStream;
    begin
        RecordRef.Get(Rec.RecordID);
        RecordRef.SetTable(ServiceCrMemoHeader);

        PEPPOLValidation.CheckServiceCreditMemo(ServiceCrMemoHeader);

        Rec."File Content".CreateOutStream(OutStr);
        GenerateXMLFile(ServiceCrMemoHeader, OutStr);

        Rec.Modify();
    end;

    [Scope('OnPrem')]
    procedure GenerateXMLFile(VariantRec: Variant; var OutStr: OutStream)
    var
        SalesCrMemoPEPPOLBIS30: XMLport "Sales Cr.Memo - PEPPOL BIS 3.0";
    begin
        SalesCrMemoPEPPOLBIS30.Initialize(VariantRec);
        SalesCrMemoPEPPOLBIS30.SetDestination(OutStr);
        SalesCrMemoPEPPOLBIS30.Export();
    end;
}

