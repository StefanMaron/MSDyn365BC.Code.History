table 5600 "Fixed Asset"
{
    Caption = 'Fixed Asset';
    DataCaptionFields = "No.", Description;
    DrillDownPageID = "Fixed Asset List";
    LookupPageID = "Fixed Asset List";
    Permissions = TableData "Ins. Coverage Ledger Entry" = r;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    FASetup.Get();
                    NoSeriesMgt.TestManual(FASetup."Fixed Asset Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';

            trigger OnValidate()
            var
                FADeprBook: Record "FA Depreciation Book";
            begin
                if ("Search Description" = UpperCase(xRec.Description)) or ("Search Description" = '') then
                    "Search Description" := Description;
                if Description <> xRec.Description then begin
                    FADeprBook.SetCurrentKey("FA No.");
                    FADeprBook.SetRange("FA No.", "No.");
                    FADeprBook.ModifyAll(Description, Description);
                end;
            end;
        }
        field(3; "Search Description"; Code[100])
        {
            Caption = 'Search Description';
        }
        field(4; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(5; "FA Class Code"; Code[10])
        {
            Caption = 'FA Class Code';
            TableRelation = "FA Class";

            trigger OnValidate()
            var
                FASubclass: Record "FA Subclass";
            begin
                if "FA Subclass Code" = '' then
                    exit;

                FASubclass.Get("FA Subclass Code");
                if not (FASubclass."FA Class Code" in ['', "FA Class Code"]) then
                    "FA Subclass Code" := '';
            end;
        }
        field(6; "FA Subclass Code"; Code[10])
        {
            Caption = 'FA Subclass Code';
            TableRelation = "FA Subclass";

            trigger OnValidate()
            var
                FASubclass: Record "FA Subclass";
            begin
                if "FA Subclass Code" = '' then begin
                    Validate("FA Posting Group", '');
                    exit;
                end;

                FASubclass.Get("FA Subclass Code");
                if "FA Class Code" <> '' then begin
                    if not (FASubclass."FA Class Code" in ['', "FA Class Code"]) then
                        Error(UnexpctedSubclassErr);
                end else
                    Validate("FA Class Code", FASubclass."FA Class Code");

                if "FA Posting Group" = '' then
                    Validate("FA Posting Group", FASubclass."Default FA Posting Group");
            end;
        }
        field(7; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Global Dimension 1 Code");
            end;
        }
        field(8; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Global Dimension 2 Code");
            end;
        }
        field(9; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location WHERE("Use As In-Transit" = CONST(false));
        }
        field(10; "FA Location Code"; Code[10])
        {
            Caption = 'FA Location Code';
            TableRelation = "FA Location";

            trigger OnValidate()
            begin
                // NAVCZ
                FASetup.Get();
                if FASetup."Fixed Asset History" and
                   ("FA Location Code" <> xRec."FA Location Code")
                then
                    ChangeEntry(FAHistory.Type::Location);
                // NAVCZ
            end;
        }
        field(11; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
        }
        field(12; "Main Asset/Component"; Option)
        {
            Caption = 'Main Asset/Component';
            Editable = false;
            OptionCaption = ' ,Main Asset,Component';
            OptionMembers = " ","Main Asset",Component;
        }
        field(13; "Component of Main Asset"; Code[20])
        {
            Caption = 'Component of Main Asset';
            Editable = false;
            TableRelation = "Fixed Asset";
        }
        field(14; "Budgeted Asset"; Boolean)
        {
            Caption = 'Budgeted Asset';

            trigger OnValidate()
            begin
                FAMoveEntries.ChangeBudget(Rec);
            end;
        }
        field(15; "Warranty Date"; Date)
        {
            Caption = 'Warranty Date';
        }
        field(16; "Responsible Employee"; Code[20])
        {
            Caption = 'Responsible Employee';
            TableRelation = Employee;

            trigger OnValidate()
            begin
                // NAVCZ
                FASetup.Get();
                if FASetup."Fixed Asset History" and
                   ("Responsible Employee" <> xRec."Responsible Employee")
                then
                    ChangeEntry(FAHistory.Type::"Responsible Employee");
                // NAVCZ
            end;
        }
        field(17; "Serial No."; Text[50])
        {
            Caption = 'Serial No.';
        }
        field(18; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(19; Insured; Boolean)
        {
            CalcFormula = Exist ("Ins. Coverage Ledger Entry" WHERE("FA No." = FIELD("No."),
                                                                    "Disposed FA" = CONST(false)));
            Caption = 'Insured';
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; Comment; Boolean)
        {
            CalcFormula = Exist ("Comment Line" WHERE("Table Name" = CONST("Fixed Asset"),
                                                      "No." = FIELD("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(21; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(22; Picture; BLOB)
        {
            Caption = 'Picture';
            ObsoleteReason = 'Replaced by Image field';
            ObsoleteState = Pending;
            SubType = Bitmap;
            ObsoleteTag = '15.0';
        }
        field(23; "Maintenance Vendor No."; Code[20])
        {
            Caption = 'Maintenance Vendor No.';
            TableRelation = Vendor;
        }
        field(24; "Under Maintenance"; Boolean)
        {
            Caption = 'Under Maintenance';
        }
        field(25; "Next Service Date"; Date)
        {
            Caption = 'Next Service Date';
        }
        field(26; Inactive; Boolean)
        {
            Caption = 'Inactive';
        }
        field(27; "FA Posting Date Filter"; Date)
        {
            Caption = 'FA Posting Date Filter';
            FieldClass = FlowFilter;
        }
        field(28; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(29; "FA Posting Group"; Code[20])
        {
            Caption = 'FA Posting Group';
            TableRelation = "FA Posting Group";

            trigger OnValidate()
            var
                FALedgerEntry: Record "FA Ledger Entry";
            begin
                if "FA Posting Group" <> xRec."FA Posting Group" then begin
                    FALedgerEntry.SetRange("FA No.", "No.");
                    if not FALedgerEntry.IsEmpty() then
                        Error(FoundFALedgerEntriesErr);
                end;
            end;
        }
        field(30; Acquired; Boolean)
        {
            CalcFormula = Exist ("FA Depreciation Book" WHERE("FA No." = FIELD("No."),
                                                              "Acquisition Date" = FILTER(<> 0D)));
            Caption = 'Acquired';
            FieldClass = FlowField;
        }
        field(140; Image; Media)
        {
            Caption = 'Image';
        }
        field(11792; "Full Description"; Text[100])
        {
            Caption = 'Full Description';
            ObsoleteState = Pending;
            ObsoleteReason = 'The functionality of Fields for Full Description will be removed and this field should not be used. Standard fields for Name are now 100. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '15.3';

            trigger OnValidate()
            begin
                if (Description = CopyStr(xRec."Full Description", 1, MaxStrLen(Description))) or (Description = '') then
                    Validate(Description, CopyStr("Full Description", 1, MaxStrLen(Description)));
            end;
        }
        field(31042; "Deprec. Book Code (Mainten.)"; Code[10])
        {
            Caption = 'Deprec. Book Code (Mainten.)';
            TableRelation = "Depreciation Book";
            ObsoleteState = Pending;
            ObsoleteReason = 'The functionality of Item consumption for FA maintenance will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '15.3';
        }
        field(31043; "Tax Depreciation Group Code"; Code[20])
        {
            Caption = 'Tax Depreciation Group Code';
            Editable = false;
            TableRelation = "Depreciation Group".Code;
        }
        field(31044; "SKP Code"; Code[20])
        {
            Caption = 'SKP Code';
            TableRelation = "SKP Code".Code;
            ObsoleteState = Pending;
            ObsoleteReason = 'The functionality of Fixed Assets Clasification by SKP codes will be removed and this field should not be used. (Obsolete::Removed in release 01.2021)';
            ObsoleteTag = '15.3';


            trigger OnValidate()
            var
                DepreciationGroup: Record "Depreciation Group";
                SKPCode: Record "SKP Code";
                FADeprBook: Record "FA Depreciation Book";
            begin
                if "SKP Code" <> '' then begin
                    FADeprBook.SetRange("FA No.", "No.");
                    if FADeprBook.FindFirst then
                        if FADeprBook."Depreciation Group Code" <> '' then begin
                            DepreciationGroup.Get(FADeprBook."Depreciation Group Code");
                            if SKPCode.Get("SKP Code") then
                                if SKPCode."Depreciation Group" <> DepreciationGroup."Depreciation Group" then
                                    Message(Text1220003, "SKP Code", FADeprBook."Depreciation Group Code");
                        end;
                end;
            end;
        }
        field(31045; "Clasification Code"; Code[20])
        {
            Caption = 'Clasification Code';
            TableRelation = "Classification Code";
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Search Description")
        {
        }
        key(Key3; "FA Class Code")
        {
        }
        key(Key4; "FA Subclass Code")
        {
        }
        key(Key5; "Component of Main Asset", "Main Asset/Component")
        {
        }
        key(Key6; "FA Location Code")
        {
        }
        key(Key7; "Global Dimension 1 Code")
        {
        }
        key(Key8; "Global Dimension 2 Code")
        {
        }
        key(Key9; "FA Posting Group")
        {
        }
        key(Key10; Description)
        {
        }
        key(Key11; "FA Location Code", "Responsible Employee")
        {
        }
        key(Key12; "Responsible Employee", "FA Location Code")
        {
        }
        key(Key13; "SKP Code")
        {
        }
        key(Key14; "Tax Depreciation Group Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description, "FA Class Code")
        {
        }
        fieldgroup(Brick; "No.", Description, "FA Class Code", Image)
        {
        }
    }

    trigger OnDelete()
    var
        FADeprBook: Record "FA Depreciation Book";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnDelete(Rec, IsHandled);
        if IsHandled then
            exit;

        LockTable();
        MainAssetComp.LockTable();
        InsCoverageLedgEntry.LockTable();
        if "Main Asset/Component" = "Main Asset/Component"::"Main Asset" then
            Error(Text000);
        FAMoveEntries.MoveFAInsuranceEntries("No.");
        FADeprBook.SetRange("FA No.", "No.");
        FADeprBook.DeleteAll(true);
        if not FADeprBook.IsEmpty then
            Error(Text001, TableCaption, "No.");

        MainAssetComp.SetCurrentKey("FA No.");
        MainAssetComp.SetRange("FA No.", "No.");
        MainAssetComp.DeleteAll();
        if "Main Asset/Component" = "Main Asset/Component"::Component then begin
            MainAssetComp.Reset();
            MainAssetComp.SetRange("Main Asset No.", "Component of Main Asset");
            MainAssetComp.SetRange("FA No.", '');
            MainAssetComp.DeleteAll();
            MainAssetComp.SetRange("FA No.");
            if not MainAssetComp.FindFirst then begin
                FA.Get("Component of Main Asset");
                FA."Main Asset/Component" := FA."Main Asset/Component"::" ";
                FA."Component of Main Asset" := '';
                FA.Modify();
            end;
        end;

        MaintenanceRegistration.SetRange("FA No.", "No.");
        MaintenanceRegistration.DeleteAll();

        CommentLine.SetRange("Table Name", CommentLine."Table Name"::"Fixed Asset");
        CommentLine.SetRange("No.", "No.");
        CommentLine.DeleteAll();

        DimMgt.DeleteDefaultDim(DATABASE::"Fixed Asset", "No.");
    end;

    trigger OnInsert()
    begin
        if "No." = '' then begin
            FASetup.Get();
            FASetup.TestField("Fixed Asset Nos.");
            NoSeriesMgt.InitSeries(FASetup."Fixed Asset Nos.", xRec."No. Series", 0D, "No.", "No. Series");
        end;

        "Main Asset/Component" := "Main Asset/Component"::" ";
        "Component of Main Asset" := '';

        DimMgt.UpdateDefaultDim(
          DATABASE::"Fixed Asset", "No.",
          "Global Dimension 1 Code", "Global Dimension 2 Code");
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;
    end;

    trigger OnRename()
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
    begin
        SalesLine.RenameNo(SalesLine.Type::"Fixed Asset", xRec."No.", "No.");
        PurchaseLine.RenameNo(PurchaseLine.Type::"Fixed Asset", xRec."No.", "No.");
        DimMgt.RenameDefaultDim(DATABASE::"Fixed Asset", xRec."No.", "No.");
        CommentLine.RenameCommentLine(CommentLine."Table Name"::"Fixed Asset", xRec."No.", "No.");

        "Last Date Modified" := Today;
    end;

    var
        Text000: Label 'A main asset cannot be deleted.';
        Text001: Label 'You cannot delete %1 %2 because it has associated depreciation books.';
        CommentLine: Record "Comment Line";
        FA: Record "Fixed Asset";
        FASetup: Record "FA Setup";
        MaintenanceRegistration: Record "Maintenance Registration";
        MainAssetComp: Record "Main Asset Component";
        InsCoverageLedgEntry: Record "Ins. Coverage Ledger Entry";
        FAMoveEntries: Codeunit "FA MoveEntries";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        DimMgt: Codeunit DimensionManagement;
        FAHistory: Record "FA History Entry";
        OKConfirm: Boolean;
        Text1220000: Label 'Do you want to assign new %1 %2 to Fixed Asset %3?';
        Text1220001: Label 'Selected Fixed Asset %1 is disposed and FA Location/Responsible Employee cannot be assigned to it.';
        Text1220002: Label 'Do you want to print FA assignment/discharge report?';
        Text1220003: Label 'The depreciation group associated with SKP Code %1 doesn''t correspond with depreciation group associated with depreciation group code %2.';
        UnexpctedSubclassErr: Label 'This fixed asset subclass belongs to a different fixed asset class.';
        DontAskAgainActionTxt: Label 'Don''t ask again';
        NotificationNameTxt: Label 'Fixed Asset Acquisition Wizard';
        NotificationDescriptionTxt: Label 'Notify when ready to acquire the fixed asset.';
        ReadyToAcquireMsg: Label 'You are ready to acquire the fixed asset.';
        AcquireActionTxt: Label 'Acquire';
        FoundFALedgerEntriesErr: Label 'You cannot change the FA posting group because posted FA ledger entries use the existing posting group.';

    procedure AssistEdit(OldFA: Record "Fixed Asset"): Boolean
    begin
        with FA do begin
            FA := Rec;
            FASetup.Get();
            FASetup.TestField("Fixed Asset Nos.");
            if NoSeriesMgt.SelectSeries(FASetup."Fixed Asset Nos.", OldFA."No. Series", "No. Series") then begin
                NoSeriesMgt.SetSeries("No.");
                Rec := FA;
                exit(true);
            end;
        end;
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        if not IsTemporary then begin
            DimMgt.SaveDefaultDim(DATABASE::"Fixed Asset", "No.", FieldNumber, ShortcutDimCode);
            Modify(true);
        end;

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    [Scope('OnPrem')]
    procedure PrintAssignmentAndDischarge(FAHistoryEntryNo: Integer)
    begin
        // NAVCZ
        if GuiAllowed and (CurrFieldNo <> 0) then
            if Confirm(Text1220002) then begin
                FAHistory.Get(FAHistoryEntryNo);
                FAHistory.SetRecFilter;
                REPORT.Run(REPORT::"FA Assignment/Discharge", false, false, FAHistory);
            end;
    end;

    [Scope('OnPrem')]
    procedure ChangeEntry(ChangeType: Option Location,"Responsible Employee")
    var
        FADeprBook: Record "FA Depreciation Book";
        OldValue: Code[20];
        NewValue: Code[20];
        IsHandled: Boolean;
    begin
        // NAVCZ
        IsHandled := false;
        OnBeforeChangeEntry(Rec, xRec, ChangeType, IsHandled);
        if IsHandled then
            exit;

        if Inactive then
            Error(Text1220001, "No.");

        FASetup.Get();
        FADeprBook.SetRange("FA No.", "No.");
        FADeprBook.SetRange("Depreciation Book Code", FASetup."Default Depr. Book");
        if FADeprBook.FindLast then
            if FADeprBook."Disposal Date" > 0D then
                Error(Text1220001, "No.");

        OKConfirm := true;
        if GuiAllowed and (CurrFieldNo <> 0) then begin
            if ChangeType = ChangeType::Location then
                OKConfirm := Confirm(Text1220000, true, FieldCaption("FA Location Code"), "FA Location Code", "No.")
            else
                OKConfirm := Confirm(Text1220000, true, FieldCaption("Responsible Employee"), "Responsible Employee", "No.");
        end;
        if OKConfirm then begin
            case ChangeType of
                ChangeType::Location:
                    begin
                        OldValue := xRec."FA Location Code";
                        NewValue := "FA Location Code";
                    end;
                ChangeType::"Responsible Employee":
                    begin
                        OldValue := xRec."Responsible Employee";
                        NewValue := "Responsible Employee";
                    end;
            end;

            PrintAssignmentAndDischarge(FAHistory.InsertEntry(ChangeType, "No.", OldValue, NewValue, 0, false));
        end else begin
            if ChangeType = ChangeType::Location then
                "FA Location Code" := xRec."FA Location Code"
            else
                "Responsible Employee" := xRec."Responsible Employee";
        end;
    end;

    procedure FieldsForAcquitionInGeneralGroupAreCompleted(): Boolean
    begin
        exit(("No." <> '') and (Description <> '') and ("FA Subclass Code" <> ''));
    end;

    procedure ShowAcquireWizardNotification()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        FixedAssetAcquisitionWizard: Codeunit "Fixed Asset Acquisition Wizard";
        FAAcquireWizardNotification: Notification;
    begin
        if IsNotificationEnabledForCurrentUser then begin
            FAAcquireWizardNotification.Id(GetNotificationID);
            FAAcquireWizardNotification.Message(ReadyToAcquireMsg);
            FAAcquireWizardNotification.Scope(NOTIFICATIONSCOPE::LocalScope);
            FAAcquireWizardNotification.AddAction(
              AcquireActionTxt, CODEUNIT::"Fixed Asset Acquisition Wizard", 'RunAcquisitionWizardFromNotification');
            FAAcquireWizardNotification.AddAction(
              DontAskAgainActionTxt, CODEUNIT::"Fixed Asset Acquisition Wizard", 'HideNotificationForCurrentUser');
            FAAcquireWizardNotification.SetData(FixedAssetAcquisitionWizard.GetNotificationFANoDataItemID, "No.");
            NotificationLifecycleMgt.SendNotification(FAAcquireWizardNotification, RecordId);
        end
    end;

    procedure GetNotificationID(): Guid
    begin
        exit('3d5c2f86-cfb9-4407-97c3-9df74c7696c9');
    end;

    procedure SetNotificationDefaultState()
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefault(GetNotificationID, NotificationNameTxt, NotificationDescriptionTxt, true);
    end;

    local procedure IsNotificationEnabledForCurrentUser(): Boolean
    var
        MyNotifications: Record "My Notifications";
    begin
        exit(MyNotifications.IsEnabled(GetNotificationID));
    end;

    procedure DontNotifyCurrentUserAgain()
    var
        MyNotifications: Record "My Notifications";
    begin
        if not MyNotifications.Disable(GetNotificationID) then
            MyNotifications.InsertDefault(GetNotificationID, NotificationNameTxt, NotificationDescriptionTxt, false);
    end;

    procedure RecallNotificationForCurrentUser()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        NotificationLifecycleMgt.RecallNotificationsForRecord(RecordId, false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var FixedAsset: Record "Fixed Asset"; var xFixedAsset: Record "Fixed Asset"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnDelete(var FixedAsset: Record "Fixed Asset"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var FixedAsset: Record "Fixed Asset"; var xFixedAsset: Record "Fixed Asset"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeChangeEntry(var FixedAsset: Record "Fixed Asset"; var xFixedAsset: Record "Fixed Asset"; ChangeType: Option Location,"Responsible Employee"; var IsHandled: Boolean)
    begin
    end;
}

