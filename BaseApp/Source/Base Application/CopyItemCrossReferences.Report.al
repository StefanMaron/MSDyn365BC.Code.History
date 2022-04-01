
#if not CLEAN19
report 5717 "Copy Item Cross References"
{
    Caption = 'Copy Item Cross References';
    ProcessingOnly = true;
    ObsoleteState = Pending;
    ObsoleteTag = '19.0';
    ObsoleteReason = 'Will be removed along with Item Cross Reference table.';

    dataset
    {
        dataitem(ItemCrossReference; "Item Cross Reference")
        {
            trigger OnPreDataItem()
            var
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                ReadRecs := 0;
                InsertedRecs := 0;
                if GuiAllowed() then begin
                    FoundRecs := ItemCrossReference.Count();
                    if FoundRecs > 0 then
                        if not ConfirmManagement.GetResponse(StrSubstNo(ConfirmCopyTxt, FoundRecs), true) then
                            CurrReport.Quit();
                end;
            end;

            trigger OnAfterGetRecord()
            var
                ItemReference: Record "Item Reference";
            begin
                ReadRecs += 1;
                if not ItemReference.Get(
                    ItemCrossReference."Item No.", ItemCrossReference."Variant Code", ItemCrossReference."Unit of Measure",
                    ItemCrossReference."Cross-Reference Type", ItemCrossReference."Cross-Reference Type No.", ItemCrossReference."Cross-Reference No.")
                then begin
                    Clear(ItemReference);
                    ItemReference.TransferFields(ItemCrossReference, true, true);
                    ItemReference.SystemId := ItemCrossReference.SystemId;
                    ItemReference.Insert(false, true);
                    InsertedRecs += 1;

                    CommitEach1000RecordsInserted();
                end;
            end;

            trigger OnPostDataItem()
            begin
                if GuiAllowed() then
                    Message(StrSubstNo(FinalMessageTxt, InsertedRecs, FoundRecs));
            end;
        }
    }

    var
        FoundRecs: Integer;
        ReadRecs: Integer;
        InsertedRecs: Integer;
        ConfirmCopyTxt: Label 'There are %1 filtered records in Item Cross Reference table. Do you want to copy them?', Comment = '%1 - a number';
        FinalMessageTxt: Label '%1 of %2 records were copied.', Comment = '%1 and %2 - numbers';

    local procedure CommitEach1000RecordsInserted()
    begin
        if ReadRecs mod 1000 = 0 then
            Commit();
    end;
}
#endif