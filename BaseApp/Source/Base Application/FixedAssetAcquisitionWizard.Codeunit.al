codeunit 5550 "Fixed Asset Acquisition Wizard"
{

    trigger OnRun()
    begin
    end;

    var
        GenJournalBatchNameTxt: Label 'AUTOMATIC', Comment = 'Translate normally and keep the upper case';
        SimpleJnlDescriptionTxt: Label 'Fixed Asset Acquisition';

    procedure RunAcquisitionWizard(FixedAssetNo: Code[20])
    var
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
    begin
        TempGenJournalLine.SetRange("Account No.", FixedAssetNo);
        PAGE.RunModal(PAGE::"Fixed Asset Acquisition Wizard", TempGenJournalLine);
    end;

    procedure RunAcquisitionWizardFromNotification(FixedAssetAcquisitionNotification: Notification)
    var
        FixedAssetNo: Code[20];
    begin
        InitializeFromNotification(FixedAssetAcquisitionNotification, FixedAssetNo);
        RunAcquisitionWizard(FixedAssetNo);
    end;

    procedure PopulateDataOnNotification(var FixedAssetAcquisitionNotification: Notification; FixedAssetNo: Code[20])
    begin
        FixedAssetAcquisitionNotification.SetData(GetNotificationFANoDataItemID, FixedAssetNo);
    end;

    procedure InitializeFromNotification(FixedAssetAcquisitionNotification: Notification; var FixedAssetNo: Code[20])
    begin
        FixedAssetNo := FixedAssetAcquisitionNotification.GetData(GetNotificationFANoDataItemID);
    end;

    procedure GetAutogenJournalBatch(): Code[10]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        if not GenJournalBatch.Get(SelectFATemplate, GenJournalBatchNameTxt) then begin
            GenJournalBatch.Init();
            GenJournalBatch."Journal Template Name" := SelectFATemplate;
            GenJournalBatch.Name := GenJournalBatchNameTxt;
            GenJournalBatch.Description := SimpleJnlDescriptionTxt;
            GenJournalBatch.SetupNewBatch;
            GenJournalBatch.Insert();
        end;

        exit(GenJournalBatch.Name);
    end;

    procedure SelectFATemplate() ReturnValue: Code[10]
    var
        FAJournalLine: Record "FA Journal Line";
        FAJnlManagement: Codeunit FAJnlManagement;
        JnlSelected: Boolean;
    begin
        FAJnlManagement.TemplateSelection(PAGE::"Fixed Asset Journal", false, FAJournalLine, JnlSelected);

        if JnlSelected then begin
            FAJournalLine.FilterGroup := 2;
            ReturnValue := CopyStr(FAJournalLine.GetFilter("Journal Template Name"), 1, MaxStrLen(FAJournalLine."Journal Template Name"));
            FAJournalLine.FilterGroup := 0;
        end;
    end;

    procedure HideNotificationForCurrentUser(Notification: Notification)
    var
        FixedAsset: Record "Fixed Asset";
    begin
        if Notification.Id = FixedAsset.GetNotificationID then
            FixedAsset.DontNotifyCurrentUserAgain;
    end;

    procedure GetNotificationFANoDataItemID(): Text
    begin
        exit('FixedAssetNo');
    end;

    [EventSubscriber(ObjectType::Page, 5600, 'OnClosePageEvent', '', false, false)]
    [Scope('OnPrem')]
    procedure RecallNotificationAboutFAAcquisitionWizardOnFixedAssetCard(var Rec: Record "Fixed Asset")
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset.RecallNotificationForCurrentUser;
    end;

    [EventSubscriber(ObjectType::Page, 1518, 'OnInitializingNotificationWithDefaultState', '', false, false)]
    [Scope('OnPrem')]
    procedure EnableSaaSNotificationPreferenceSetupOnInitializingNotificationWithDefaultState()
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset.SetNotificationDefaultState;
    end;
}

