namespace Microsoft.Service.Document;

using System.Utilities;

codeunit 5951 "Service-Disc. (Yes/No)"
{
    TableNo = "Service Line";

    trigger OnRun()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        ServiceLine.Copy(Rec);
        if ConfirmManagement.GetResponseOrDefault(Text000, true) then
            CODEUNIT.Run(CODEUNIT::"Service-Calc. Discount", ServiceLine);
        Rec := ServiceLine;
    end;

    var
        ServiceLine: Record "Service Line";

#pragma warning disable AA0074
        Text000: Label 'Do you want to calculate the invoice discount?';
#pragma warning restore AA0074
}

