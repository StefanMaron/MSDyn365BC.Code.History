codeunit 31149 "Use G/L Account Dimensions CZZ"
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnPostDtldCVLedgEntryOnBeforeCreateGLEntryGainLoss', '', false, false)]
    local procedure UseGLAccountDimensionsOnBeforeCreateGLEntryGainLossInsertGLEntry(var GenJournalLine: Record "Gen. Journal Line"; var AccNo: Code[20])
    var
        DimMgt: Codeunit DimensionManagement;
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
        GenJournalAccountType: Enum "Gen. Journal Account Type";
    begin
        DimMgt.AddDimSource(
            DefaultDimSource, DimMgt.TypeToTableID1(GenJournalAccountType::"G/L Account".AsInteger()), AccNo, true);
        GenJournalLine.Validate("Dimension Set ID",
            DimMgt.GetRecDefaultDimID(
                GenJournalLine, 0, DefaultDimSource, GenJournalLine."Source Code",
                GenJournalLine."Shortcut Dimension 1 Code", GenJournalLine."Shortcut Dimension 2 Code", 0, 0));
    end;
}