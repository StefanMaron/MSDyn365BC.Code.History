namespace Microsoft.Finance.VAT;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Service.Document;

codeunit 6486 "Serv. VAT Specification Mgt."
{
    var
        CanOnlyBeModifiedErr: Label '%1 can only be modified on the %2 tab.', Comment = '%1 - field caption, %2 - page tab caption';
        DetailsTxt: Label 'Details';

    [EventSubscriber(ObjectType::Page, Page::"VAT Specification Subform", 'OnBeforeCheckAmountChange', '', false, false)]
    local procedure OnBeforeCheckAmountChange(ParentControl: Integer; AmountFieldCaption: Text);
    begin
        if ParentControl = PAGE::"Service Order Statistics" then
            Error(CanOnlyBeModifiedErr, AmountFieldCaption, DetailsTxt)
    end;

    [EventSubscriber(ObjectType::Page, Page::"VAT Specification Subform", 'OnAfterModifyRec', '', false, false)]
    local procedure OnAfterModifyRec(var SourceHeader: Variant; var VATAmountLine: Record "VAT Amount Line"; ParentControl: Integer; CurrentTabNo: Integer)
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(SourceHeader);
        if RecRef.Number <> ParentControl then
            exit;

        ServiceHeader := SourceHeader;
        if ((ParentControl = PAGE::"Service Order Statistics") and
            (CurrentTabNo <> 1))
        then
            if VATAmountLine.GetAnyLineModified() then begin
                ServiceLine.UpdateVATOnLines(0, ServiceHeader, ServiceLine, VATAmountLine);
                ServiceLine.UpdateVATOnLines(1, ServiceHeader, ServiceLine, VATAmountLine);
            end;
    end;
}