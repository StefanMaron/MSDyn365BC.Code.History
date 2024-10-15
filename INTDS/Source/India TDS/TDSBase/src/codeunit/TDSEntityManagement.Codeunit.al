codeunit 18685 "TDS Entity Management"
{
    procedure GetDetailTxt(Section: Record "TDS Section") DetailTxt: Text
    var
        IStream: InStream;
        SectionsDetailLbl: Label 'Click here to enter Section Details';
    begin
        Section.CalcFields(Detail);
        if not Section.Detail.HasValue() then begin
            DetailTxt := SectionsDetailLbl;
            exit;
        end else
            Section.Detail.CreateInStream(IStream);
        IStream.ReadText(DetailTxt);
    end;

    procedure SetDetailTxt(DetailTxt: Text; var Section: Record "TDS Section")
    var
        OStream: OutStream;
    begin
        Section.Detail.CreateOutStream(OStream);
        OStream.WriteText(DetailTxt);
        Section.Modify(true);
    end;

    procedure OpenTDSEntries(FromEntry: Integer; ToEntry: Integer)
    var
        TDSEntry: Record "TDS Entry";
        GlEntry: Record "G/L Entry";
        TransactionNo: Integer;
    begin
        GlEntry.SetRange("Entry No.", FromEntry, ToEntry);
        if GlEntry.FindFirst() then begin
            TDSEntry.SETRANGE("Transaction No.", GlEntry."Transaction No.");
            PAGE.RUN(0, TDSEntry);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Tax Document GL Posting", 'OnPrepareTransValueToPost', '', false, false)]
    local procedure SetTotalTDSInclSHECessAmount(var TempTransValue: Record "Tax Transaction Value")
    var
        TDSSetup: Record "TDS Setup";
        TaxComponent: Record "Tax Component";
        TaxBaseSubscribers: Codeunit "Tax Base Subscribers";
        ComponenetNameLbl: Label 'Total TDS Amount';
    begin
        if TempTransValue."Value Type" <> TempTransValue."Value Type"::COMPONENT then
            exit;

        if not TDSSetup.Get() then
            exit;
        if TempTransValue."Tax Type" <> TDSSetup."Tax Type" then
            exit;
        TaxComponent.SetRange("Tax Type", TDSSetup."Tax Type");
        TaxComponent.SetRange(Name, ComponenetNameLbl);
        if not TaxComponent.FindFirst() then
            exit;

        if TempTransValue."Value ID" <> TaxComponent.Id then
            exit;
        TaxBaseSubscribers.OnAfterGetTDSAmount(TempTransValue.Amount);
    end;
}