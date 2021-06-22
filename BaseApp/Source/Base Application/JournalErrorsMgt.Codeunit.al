codeunit 9080 "Journal Errors Mgt."
{
    SingleInstance = true;

    trigger OnRun()
    begin

    end;

    var
        TempErrorMessage: Record "Error Message" temporary;
        TempDeletedGenJnlLine: Record "Gen. Journal Line" temporary;
        TempModifiedGenJnlLine: Record "Gen. Journal Line" temporary;
        TempGenJnlLineBeforeModify: Record "Gen. Journal Line" temporary;
        TempGenJnlLineAfterModify: Record "Gen. Journal Line" temporary;
        FullBatchCheck: Boolean;

    procedure IsEnabled() Result: Boolean
    var
        FeatureKey: Record "Feature Key";
    begin
        if FeatureKey.Get(GetFeatureKey()) then
            Result := FeatureKey.Enabled = FeatureKey.Enabled::"All Users";

        OnAfterIsEnabled(Result);
    end;

    procedure GetFeatureKey(): Text[50]
    begin
        exit('JournalErrorBackgroundCheck');
    end;

    procedure TestIsEnabled()
    var
        FeatureKey: Record "Feature Key";
    begin
        if not IsEnabled() then begin
            FeatureKey.ID := GetFeatureKey();
            FeatureKey.TestField(Enabled, FeatureKey.Enabled::"All Users");
        end;
    end;

    local procedure ClearBackgroundErrorCheckInAllCompanies()
    var
        Company: Record Company;
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        if Company.FindSet() then
            repeat
                if GenJnlBatch.ChangeCompany(Company.Name) then
                    GenJnlBatch.ModifyAll("Background Error Check", false);
            until Company.Next() = 0;
    end;

    procedure SetErrorMessages(var SourceTempErrorMessage: Record "Error Message" temporary)
    begin
        TempErrorMessage.Copy(SourceTempErrorMessage, true);
    end;

    procedure GetErrorMessages(var NewTempErrorMessage: Record "Error Message" temporary)
    begin
        NewTempErrorMessage.Copy(TempErrorMessage, true);
    end;

    procedure SetRecXRecOnModify(xRec: Record "Gen. Journal Line"; Rec: Record "Gen. Journal Line")
    var
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        if GenJnlBatch.Get(Rec."Journal Template Name", Rec."Journal Batch Name") and GenJnlBatch."Background Error Check" then begin
            TempGenJnlLineBeforeModify := xRec;
            TempGenJnlLineBeforeModify.Insert();

            TempGenJnlLineAfterModify := Rec;
            TempGenJnlLineAfterModify.Insert();
        end;
    end;

    procedure GetRecXRecOnModify(var xRec: Record "Gen. Journal Line"; var Rec: Record "Gen. Journal Line"): Boolean
    begin
        if TempGenJnlLineAfterModify.FindFirst() then begin
            xRec := TempGenJnlLineBeforeModify;
            Rec := TempGenJnlLineAfterModify;

            if TempGenJnlLineBeforeModify.Delete() then;
            if TempGenJnlLineAfterModify.Delete() then;
            exit(true);
        end;

        exit(false);
    end;

    procedure SetFullBatchCheck(NewFullBatchCheck: Boolean)
    begin
        FullBatchCheck := NewFullBatchCheck;
    end;

    procedure GetFullBatchCheck(): Boolean
    begin
        exit(FullBatchCheck);
    end;

    procedure GetDeletedGenJnlLine(var TempGenJnlLine: Record "Gen. Journal Line" temporary; ClearBuffer: Boolean): Boolean
    begin
        if TempDeletedGenJnlLine.FindSet() then begin
            repeat
                TempGenJnlLine := TempDeletedGenJnlLine;
                TempGenJnlLine.Insert();
            until TempDeletedGenJnlLine.Next() = 0;

            if ClearBuffer then
                TempDeletedGenJnlLine.DeleteAll();
            exit(true);
        end;

        exit(false);
    end;

    procedure GetModifiedGenJnlLine(var TempGenJnlLine: Record "Gen. Journal Line" temporary): Boolean
    begin
        TempGenJnlLine.Reset();
        TempGenJnlLine.DeleteAll();
        if TempModifiedGenJnlLine.FindSet() then begin
            repeat
                TempGenJnlLine := TempModifiedGenJnlLine;
                TempGenJnlLine.Insert();
            until TempModifiedGenJnlLine.Next() = 0;

            TempModifiedGenJnlLine.DeleteAll();
            exit(true);
        end;

        exit(false);
    end;

    procedure InsertDeletedLine(GenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        if GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name") and GenJnlBatch."Background Error Check" then begin
            TempDeletedGenJnlLine := GenJnlLine;
            if TempDeletedGenJnlLine.Insert() then;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsEnabled(var Result: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Page, 39, 'OnDeleteRecordEvent', '', false, false)]
    local procedure OnDeleteRecordEventGeneralJournal(var Rec: Record "Gen. Journal Line"; var AllowDelete: Boolean)
    begin
        InsertDeletedLine(Rec);
    end;

    [EventSubscriber(ObjectType::Page, 39, 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventGeneralJournal(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; var AllowModify: Boolean)
    begin
        SetRecXRecOnModify(xRec, Rec);
    end;

    [EventSubscriber(ObjectType::Page, 39, 'OnInsertRecordEvent', '', false, false)]
    local procedure OnInsertRecordEventGeneralJournal(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; var AllowInsert: Boolean)
    begin
        SetRecXRecOnModify(xRec, Rec);
    end;

    [EventSubscriber(ObjectType::Page, 253, 'OnDeleteRecordEvent', '', false, false)]
    local procedure OnDeleteRecordEventSalesJournal(var Rec: Record "Gen. Journal Line"; var AllowDelete: Boolean)
    begin
        InsertDeletedLine(Rec);
    end;

    [EventSubscriber(ObjectType::Page, 253, 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventSalesJournal(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; var AllowModify: Boolean)
    begin
        SetRecXRecOnModify(xRec, Rec);
    end;

    [EventSubscriber(ObjectType::Page, 253, 'OnInsertRecordEvent', '', false, false)]
    local procedure OnInsertRecordEventSalesJournal(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; var AllowInsert: Boolean)
    begin
        SetRecXRecOnModify(xRec, Rec);
    end;

    [EventSubscriber(ObjectType::Page, 254, 'OnDeleteRecordEvent', '', false, false)]
    local procedure OnDeleteRecordEventPurchaseJournal(var Rec: Record "Gen. Journal Line"; var AllowDelete: Boolean)
    begin
        InsertDeletedLine(Rec);
    end;

    [EventSubscriber(ObjectType::Page, 254, 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventPurchaseJournal(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; var AllowModify: Boolean)
    begin
        SetRecXRecOnModify(xRec, Rec);
    end;

    [EventSubscriber(ObjectType::Page, 254, 'OnInsertRecordEvent', '', false, false)]
    local procedure OnInsertRecordEventPurchaseJournal(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; var AllowInsert: Boolean)
    begin
        SetRecXRecOnModify(xRec, Rec);
    end;

    [EventSubscriber(ObjectType::Page, 255, 'OnDeleteRecordEvent', '', false, false)]
    local procedure OnDeleteRecordEventCashReceiptJournal(var Rec: Record "Gen. Journal Line"; var AllowDelete: Boolean)
    begin
        InsertDeletedLine(Rec);
    end;

    [EventSubscriber(ObjectType::Page, 255, 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventCashReceiptJournal(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; var AllowModify: Boolean)
    begin
        SetRecXRecOnModify(xRec, Rec);
    end;

    [EventSubscriber(ObjectType::Page, 255, 'OnInsertRecordEvent', '', false, false)]
    local procedure OnInsertRecordEventCashReceiptJournal(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; var AllowInsert: Boolean)
    begin
        SetRecXRecOnModify(xRec, Rec);
    end;

    [EventSubscriber(ObjectType::Page, 256, 'OnDeleteRecordEvent', '', false, false)]
    local procedure OnDeleteRecordEventPaymentJournal(var Rec: Record "Gen. Journal Line"; var AllowDelete: Boolean)
    begin
        InsertDeletedLine(Rec);
    end;

    [EventSubscriber(ObjectType::Page, 256, 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventPaymentJournal(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; var AllowModify: Boolean)
    begin
        SetRecXRecOnModify(xRec, Rec);
    end;

    [EventSubscriber(ObjectType::Page, 256, 'OnInsertRecordEvent', '', false, false)]
    local procedure OnInsertRecordEventPaymentJournal(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; var AllowInsert: Boolean)
    begin
        SetRecXRecOnModify(xRec, Rec);
    end;

    [EventSubscriber(ObjectType::Page, 610, 'OnDeleteRecordEvent', '', false, false)]
    local procedure OnDeleteRecordEventICGeneralJournal(var Rec: Record "Gen. Journal Line"; var AllowDelete: Boolean)
    begin
        InsertDeletedLine(Rec);
    end;

    [EventSubscriber(ObjectType::Page, 610, 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventICGeneralJournal(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; var AllowModify: Boolean)
    begin
        SetRecXRecOnModify(xRec, Rec);
    end;

    [EventSubscriber(ObjectType::Page, 610, 'OnInsertRecordEvent', '', false, false)]
    local procedure OnInsertRecordEventICGeneralJournal(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; var AllowInsert: Boolean)
    begin
        SetRecXRecOnModify(xRec, Rec);
    end;

    [EventSubscriber(ObjectType::Page, 1020, 'OnDeleteRecordEvent', '', false, false)]
    local procedure OnDeleteRecordEventJobGLJournal(var Rec: Record "Gen. Journal Line"; var AllowDelete: Boolean)
    begin
        InsertDeletedLine(Rec);
    end;

    [EventSubscriber(ObjectType::Page, 1020, 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventJobGLJournal(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; var AllowModify: Boolean)
    begin
        SetRecXRecOnModify(xRec, Rec);
    end;

    [EventSubscriber(ObjectType::Page, 1020, 'OnInsertRecordEvent', '', false, false)]
    local procedure OnInsertRecordEventJobJournal(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; var AllowInsert: Boolean)
    begin
        SetRecXRecOnModify(xRec, Rec);
    end;

    [EventSubscriber(ObjectType::Page, 5628, 'OnDeleteRecordEvent', '', false, false)]
    local procedure OnDeleteRecordEventFixedAssetGLJournal(var Rec: Record "Gen. Journal Line"; var AllowDelete: Boolean)
    begin
        InsertDeletedLine(Rec);
    end;

    [EventSubscriber(ObjectType::Page, 5628, 'OnModifyRecordEvent', '', false, false)]
    local procedure OnModifyRecordEventFixedAssetGLJournal(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; var AllowModify: Boolean)
    begin
        SetRecXRecOnModify(xRec, Rec);
    end;

    [EventSubscriber(ObjectType::Page, 5628, 'OnInsertRecordEvent', '', false, false)]
    local procedure OnInsertRecordEventFixedAssetGLJournal(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line"; var AllowInsert: Boolean)
    begin
        SetRecXRecOnModify(xRec, Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Feature Key", 'OnAfterValidateEvent', 'Enabled', false, false)]
    local procedure AfterValidateEnabledHandler(var Rec: Record "Feature Key"; var xRec: Record "Feature Key"; CurrFieldNo: Integer)
    begin
        if (Rec.ID = GetFeatureKey()) and (Rec.Enabled = Rec.Enabled::None) and (Rec.Enabled <> xRec.Enabled) then
            ClearBackgroundErrorCheckInAllCompanies();
    end;
}