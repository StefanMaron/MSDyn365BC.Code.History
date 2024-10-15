codeunit 31476 "Calc. And Post VAT Handler CZZ"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Report, Report::"Calc. and Post VAT Settl. CZL", 'OnClosingGLAndVATEntryOnAfterGetRecordOnAfterSetVATEntryFilters', '', false, false)]
    local procedure FilterAdvancesOnClosingGLAndVATEntryOnAfterGetRecordOnAfterSetVATEntryFilters(var VATEntry: Record "VAT Entry")
    begin
#if not CLEAN19
        if AdvancePaymentMgt.IsEnabled() then begin
#endif
            if AdvanceNumberRun = 1 then
                VATEntry.SetFilter("Advance Letter No. CZZ", '=''''');
            if AdvanceNumberRun = 2 then
                VATEntry.SetFilter("Advance Letter No. CZZ", '<>''''');
#if not CLEAN19
#pragma warning disable AL0432
            VATEntry.SetRange("Advance Letter No.");
        end;
#pragma warning restore AL0432
#endif
    end;

    procedure SetAdvanceNumberRun(AdvanceNumberRunSet: Integer)
    begin
        AdvanceNumberRun := AdvanceNumberRunSet;
    end;

    var
#if not CLEAN19
        AdvancePaymentMgt: Codeunit "Advance Payments Mgt. CZZ";
#endif
        AdvanceNumberRun: Integer;
}