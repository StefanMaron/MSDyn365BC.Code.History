// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 1991 "Guided Experience Impl."
{
    Access = Internal;
    Permissions = tabledata AllObj = r,
                  tabledata "Guided Experience Item" = rimd,
                  tabledata Translation = r;

    var
        TempBlob: Codeunit "Temp Blob";
        ObjectAndLinkToRunErr: Label 'You cannot insert a guided experience item with both an object to run and a link.';
        InvalidObjectTypeErr: Label 'The object type to run is not valid';
        ObjectDoesNotExistErr: Label 'The object %1 %2 does not exist', Comment = '%1 = Object type, %2 = The object ID';
        RunSetupAgainQst: Label 'You have already completed the %1 assisted setup guide. Do you want to run it again?', Comment = '%1 = Assisted Setup Name';
        CodeFormatLbl: Label '%1_%2_%3_%4', Locked = true;
        GuidedExperienceItemInsertedLbl: Label 'Guided Experience Item inserted.', Locked = true;
        GuidedExperienceItemDeletedLbl: Label 'Guided Experience Item deleted.', Locked = true;

    procedure Insert(Title: Text[2048]; ShortTitle: Text[50]; Description: Text[1024]; ExpectedDuration: Integer; ExtensionId: Guid; GuidedExperienceType: Enum "Guided Experience Type"; ObjectTypeToRun: ObjectType; ObjectIDToRun: Integer; Link: Text[250]; AssistedSetupGroup: Enum "Assisted Setup Group"; VideoUrl: Text[250]; VideoCategory: Enum "Video Category"; HelpUrl: Text[250]; ManualSetupCategory: Enum "Manual Setup Category"; Keywords: Text[250]; CheckObjectValidity: Boolean)
    var
        PrevGuidedExperienceItem: Record "Guided Experience Item";
        GuidedExperienceItem: Record "Guided Experience Item";
        ChecklistImplementation: Codeunit "Checklist Implementation";
        Video: Codeunit Video;
        GuidedExperienceObjectType: Enum "Guided Experience Object Type";
        Version: Integer;
        Code: Code[300];
    begin
        if not GuidedExperienceItem.WritePermission() then
            exit;

        ValidateGuidedExperienceItem(ObjectTypeToRun, ObjectIDToRun, Link, CheckObjectValidity);

        GetObjectTypeToRun(GuidedExperienceObjectType, ObjectTypeToRun);
        Code := GetCode(GuidedExperienceType, GuidedExperienceObjectType, ObjectIDToRun, Link);

        Version := GetVersion(PrevGuidedExperienceItem, Code, Title, ShortTitle, Description, ExpectedDuration, ExtensionId, GuidedExperienceType,
            GuidedExperienceObjectType, ObjectIDToRun, Link, AssistedSetupGroup, VideoUrl, VideoCategory, HelpUrl, ManualSetupCategory, Keywords);

        if Version = -1 then // this means that the record hasn't changed, so we shouldn't insert a new version
            exit;

        if Version <> 0 then
            ChecklistImplementation.UpdateVersionForSkippedChecklistItems(Code, Version);

        InsertGuidedExperienceItem(GuidedExperienceItem, Code, Version, Title, ShortTitle, Description, ExpectedDuration, ExtensionId, PrevGuidedExperienceItem.Completed,
            GuidedExperienceType, GuidedExperienceObjectType, ObjectIDToRun, Link, AssistedSetupGroup, VideoUrl, VideoCategory, HelpUrl, ManualSetupCategory, Keywords);

        InsertTranslations(GuidedExperienceItem, PrevGuidedExperienceItem);

        if VideoUrl <> '' then
            Video.Register(GuidedExperienceItem."Extension ID", CopyStr(GuidedExperienceItem.Title, 1, 250), VideoUrl, VideoCategory,
            Database::"Guided Experience Item", GuidedExperienceItem.SystemId);
    end;

    procedure OpenManualSetupPage()
    begin
        Page.RunModal(Page::"Manual Setup");
    end;

    procedure OpenManualSetupPage(ManualSetupCategory: Enum "Manual Setup Category")
    var
        ManualSetup: Page "Manual Setup";
    begin
        ManualSetup.SetCategoryToDisplay(ManualSetupCategory);
        ManualSetup.RunModal();
    end;

    procedure GetManualSetupPageIDs(var PageIDs: List of [Integer])
    var
        GuidedExperienceItem: Record "Guided Experience Item";
        PrevGuidedExperienceItem: Record "Guided Experience Item";
        GuidedExperience: Codeunit "Guided Experience";
#if not CLEAN18
        ManualSetup: Codeunit "Manual Setup";
#endif
    begin
        Clear(PageIDs);

        GuidedExperience.OnRegisterManualSetup();
#if not CLEAN18
        ManualSetup.OnRegisterManualSetup();
#endif

        GuidedExperienceItem.SetCurrentKey("Guided Experience Type", "Object Type to Run", "Object ID to Run", Link, Version);
        GuidedExperienceItem.SetRange("Guided Experience Type", GuidedExperienceItem."Guided Experience Type"::"Manual Setup");
        GuidedExperienceItem.SetRange("Object Type to Run", GuidedExperienceItem."Object Type to Run"::Page);
        if GuidedExperienceItem.FindSet() then
            repeat
                if PrevGuidedExperienceItem.Code <> GuidedExperienceItem.Code then
                    PageIDs.Add(GuidedExperienceItem."Object ID to Run");
                PrevGuidedExperienceItem := GuidedExperienceItem;
            until GuidedExperienceItem.Next() = 0;
    end;

    procedure AddTranslationForSetupObject(GuidedExperienceObjectType: Enum "Guided Experience Type"; ObjectType: ObjectType; ObjectID: Integer; LanguageID: Integer; TranslatedName: Text; FieldNo: Integer)
    var
        GuidedExperienceItem: Record "Guided Experience Item";
        Translation: Codeunit Translation;
    begin
        FilterGuidedExperienceItem(GuidedExperienceItem, GuidedExperienceObjectType, ObjectType, ObjectID, '');
        if not GuidedExperienceItem.FindLast() then
            exit;

        Translation.Set(GuidedExperienceItem, FieldNo, LanguageID, CopyStr(TranslatedName, 1, 2048));
    end;

    procedure IsAssistedSetupComplete(ObjectTypeToRun: Enum "Guided Experience Object Type"; ObjectID: Integer): Boolean
    var
        ObjectType: ObjectType;
    begin
        ObjectType := GetObjectType(ObjectTypeToRun);
        exit(IsAssistedSetupComplete(ObjectType, ObjectID));
    end;

    procedure IsAssistedSetupComplete(ObjectType: ObjectType; ObjectID: Integer): Boolean
    var
        GuidedExperienceItem: Record "Guided Experience Item";
        ObjectTypeToRun: Enum "Guided Experience Object Type";
    begin
        if not GuidedExperienceItem.ReadPermission() then
            exit;

        GetObjectTypeToRun(ObjectTypeToRun, ObjectType);

        GuidedExperienceItem.SetRange("Guided Experience Type", GuidedExperienceItem."Guided Experience Type"::"Assisted Setup");
        GuidedExperienceItem.SetRange("Object Type to Run", ObjectTypeToRun);
        GuidedExperienceItem.SetRange("Object ID to Run", ObjectID);
        GuidedExperienceItem.SetRange(Completed, true);

        exit(not GuidedExperienceItem.IsEmpty());
    end;

    procedure Exists(GuidedExperienceType: Enum "Guided Experience Type"; ObjectType: ObjectType; ObjectID: Integer): Boolean
    var
        GuidedExperienceItem: Record "Guided Experience Item";
        GuidedExperienceObjectType: Enum "Guided Experience Object Type";
    begin
        if not GuidedExperienceItem.ReadPermission() then
            exit;

        GetObjectTypeToRun(GuidedExperienceObjectType, ObjectType);

        GuidedExperienceItem.SetRange("Guided Experience Type", GuidedExperienceType);
        GuidedExperienceItem.SetRange("Object Type to Run", GuidedExperienceObjectType);
        GuidedExperienceItem.SetRange("Object ID to Run", ObjectID);

        exit(not GuidedExperienceItem.IsEmpty());
    end;

    procedure Exists(GuidedExperienceType: Enum "Guided Experience Type"; Link: Text[250]): Boolean
    var
        GuidedExperienceItem: Record "Guided Experience Item";
    begin
        if not GuidedExperienceItem.ReadPermission() then
            exit;

        GuidedExperienceItem.SetRange("Guided Experience Type", GuidedExperienceType);
        GuidedExperienceItem.SetRange(Link, Link);
        exit(not GuidedExperienceItem.IsEmpty());
    end;

    procedure AssistedSetupExistsAndIsNotComplete(ObjectType: ObjectType; ObjectID: Integer): Boolean
    var
        GuidedExperienceItem: Record "Guided Experience Item";
        GuidedExperienceObjectType: Enum "Guided Experience Object Type";
    begin
        if not GuidedExperienceItem.ReadPermission() then
            exit;

        GetObjectTypeToRun(GuidedExperienceObjectType, ObjectType);

        GuidedExperienceItem.SetRange("Guided Experience Type", GuidedExperienceItem."Guided Experience Type"::"Assisted Setup");
        GuidedExperienceItem.SetRange("Object Type to Run", GuidedExperienceObjectType);
        GuidedExperienceItem.SetRange("Object ID to Run", ObjectID);

        if GuidedExperienceItem.IsEmpty() then
            exit(false);

        GuidedExperienceItem.SetRange(Completed, true);
        exit(GuidedExperienceItem.IsEmpty());
    end;

    procedure CompleteAssistedSetup(ObjectType: ObjectType; ObjectID: Integer)
    var
        GuidedExperienceItem: Record "Guided Experience Item";
        GuidedExperienceObjectType: Enum "Guided Experience Object Type";
    begin
        if not GuidedExperienceItem.WritePermission() then
            exit;

        GetObjectTypeToRun(GuidedExperienceObjectType, ObjectType);

        GuidedExperienceItem.SetRange("Guided Experience Type", GuidedExperienceItem."Guided Experience Type"::"Assisted Setup");
        GuidedExperienceItem.SetRange("Object Type to Run", GuidedExperienceObjectType);
        GuidedExperienceItem.SetRange("Object ID to Run", ObjectID);

        Complete(GuidedExperienceItem);
    end;

    procedure ResetAssistedSetup(ObjectType: ObjectType; ObjectID: Integer)
    var
        GuidedExperienceItem: Record "Guided Experience Item";
        GuidedExperienceObjectType: Enum "Guided Experience Object Type";
    begin
        if not GuidedExperienceItem.WritePermission() then
            exit;

        GetObjectTypeToRun(GuidedExperienceObjectType, ObjectType);

        GuidedExperienceItem.SetRange("Guided Experience Type", GuidedExperienceItem."Guided Experience Type"::"Assisted Setup");
        GuidedExperienceItem.SetRange("Object Type to Run", GuidedExperienceObjectType);
        GuidedExperienceItem.SetRange("Object ID to Run", ObjectID);

        Reset(GuidedExperienceItem);
    end;

    procedure Run(GuidedExperienceType: Enum "Guided Experience Type"; ObjectType: ObjectType; ObjectID: Integer)
    var
        GuidedExperienceItem: Record "Guided Experience Item";
        GuidedExperienceObjectType: Enum "Guided Experience Object Type";
    begin
        if not GuidedExperienceItem.ReadPermission() then
            exit;

        GetObjectTypeToRun(GuidedExperienceObjectType, ObjectType);

        GuidedExperienceItem.SetRange("Guided Experience Type", GuidedExperienceType);
        GuidedExperienceItem.SetRange("Object Type to Run", GuidedExperienceObjectType);
        GuidedExperienceItem.SetRange("Object ID to Run", ObjectID);
        if not GuidedExperienceItem.FindLast() then
            exit;

        Run(GuidedExperienceItem);
    end;

    procedure RunAndRefreshAssistedSetup(var GuidedExperienceItemToRefresh: Record "Guided Experience Item")
    begin
        Run(GuidedExperienceItemToRefresh);
        RefreshAssistedSetup(GuidedExperienceItemToRefresh);
    end;

    procedure OpenAssistedSetup()
    begin
        Page.RunModal(Page::"Assisted Setup");
    end;

    procedure OpenAssistedSetup(AssistedSetupGroup: Enum "Assisted Setup Group")
    var
        AssistedSetup: Page "Assisted Setup";
    begin
        AssistedSetup.SetGroupToDisplay(AssistedSetupGroup);
        AssistedSetup.RunModal();
    end;

    procedure Remove(GuidedExperienceType: Enum "Guided Experience Type"; ObjectType: ObjectType; ObjectID: Integer)
    var
        GuidedExperienceItem: Record "Guided Experience Item";
        GuidedExperienceObjectType: Enum "Guided Experience Object Type";
    begin
        if not GuidedExperienceItem.WritePermission() then
            exit;

        FilterGuidedExperienceItem(GuidedExperienceItem, GuidedExperienceType, GuidedExperienceObjectType, ObjectID, '');

        Delete(GuidedExperienceItem);
    end;

    procedure Remove(GuidedExperienceType: Enum "Guided Experience Type"; Link: Text[250])
    var
        GuidedExperienceItem: Record "Guided Experience Item";
    begin
        if not GuidedExperienceItem.WritePermission() then
            exit;

        GuidedExperienceItem.SetRange("Guided Experience Type", GuidedExperienceType);
        GuidedExperienceItem.SetRange(Link, Link);

        Delete(GuidedExperienceItem);
    end;

    procedure NavigateToAssistedSetupHelpPage(GuidedExperienceItem: Record "Guided Experience Item")
    begin
        if GuidedExperienceItem."Help Url" = '' then
            exit;

        Hyperlink(GuidedExperienceItem."Help Url");
    end;

    procedure IsAssistedSetupSetupRecord(GuidedExperienceItem: Record "Guided Experience Item"): Boolean
    begin
        exit(GuidedExperienceItem."Object ID to Run" > 0);
    end;

    procedure GetTranslatedTitle(GuidedExperienceType: Enum "Guided Experience Type"; ObjectTypeToRun: Enum "Guided Experience Object Type"; ObjectIDToRun: Integer): Text
    var
        GuidedExperienceItem: Record "Guided Experience Item";
        Translation: Codeunit Translation;
    begin
        FilterGuidedExperienceItem(GuidedExperienceItem, GuidedExperienceType, ObjectTypeToRun, ObjectIDToRun, '');
        if GuidedExperienceItem.FindLast() then
            exit(Translation.Get(GuidedExperienceItem, GuidedExperienceItem.FieldNo(Title)));
    end;

    procedure IsObjectToRunValid(GuidedExperienceObjectType: Enum "Guided Experience Object Type"; ObjectID: Integer): Boolean
    var
        ObjectType: ObjectType;
    begin
        ObjectType := GetObjectType(GuidedExperienceObjectType);
        exit(IsObjectToRunValid(ObjectType, ObjectID));
    end;

    procedure IsObjectToRunValid(ObjectType: ObjectType; ObjectID: Integer): Boolean
    var
        AllObj: Record AllObj;
    begin
        if AllObj.Get(ObjectType, ObjectID) then
            exit(true);

        exit(false);
    end;

    procedure GetContentForAssistedSetup(var GuidedExperienceItemTemp: Record "Guided Experience Item" temporary)
    var
        GuidedExperienceItem: Record "Guided Experience Item";
        GroupValue: Enum "Assisted Setup Group";
        GroupId: Integer;
        i: Integer;
    begin
        GuidedExperienceItem.SetCurrentKey("Guided Experience Type", "Object Type to Run", "Object ID to Run", Link, Version);
        GuidedExperienceItem.SetRange("Guided Experience Type", GuidedExperienceItem."Guided Experience Type"::"Assisted Setup");

        GroupId := -1;
        foreach i in "Assisted Setup Group".Ordinals() do begin
            GroupValue := "Assisted Setup Group".FromInteger(i);
            GuidedExperienceItem.SetRange("Assisted Setup Group", GroupValue);

            if GuidedExperienceItem.FindSet() then begin
                // this part is necessary to include the assisted setup group as a header on the page
                GuidedExperienceItemTemp.Init();
                GuidedExperienceItemTemp.Code := Format(GroupId);
                GuidedExperienceItemTemp."Object ID to Run" := GroupId;
                GuidedExperienceItemTemp.Title := Format(GroupValue);
                GuidedExperienceItemTemp."Assisted Setup Group" := GroupValue;
                GuidedExperienceItemTemp.Insert();

                GroupId -= 1;

                InsertGuidedExperienceItemsInTempVar(GuidedExperienceItem, GuidedExperienceItemTemp);
            end;
        end;
    end;

    procedure GetContentForSetupPage(var GuidedExperienceItemTemp: Record "Guided Experience Item" temporary; GuidedExperienceType: Enum "Guided Experience Type")
    var
        GuidedExperienceItem: Record "Guided Experience Item";
    begin
        GuidedExperienceItem.SetCurrentKey("Guided Experience Type", "Object Type to Run", "Object ID to Run", Link, Version);
        GuidedExperienceItem.SetRange("Guided Experience Type", GuidedExperienceType);

        if GuidedExperienceItem.FindSet() then
            InsertGuidedExperienceItemsInTempVar(GuidedExperienceItem, GuidedExperienceItemTemp);
    end;

    local procedure InsertGuidedExperienceItemsInTempVar(var GuidedExperienceItem: Record "Guided Experience Item"; var GuidedExperienceItemTemp: Record "Guided Experience Item" temporary)
    var
        PrevGuidedExperienceItem: Record "Guided Experience Item";
    begin
        repeat
            if (GuidedExperienceItem."Object Type to Run" <> PrevGuidedExperienceItem."Object Type to Run")
                or (GuidedExperienceItem."Object ID to Run" <> PrevGuidedExperienceItem."Object ID to Run")
            then
                InsertGuidedExperienceItemIfValid(GuidedExperienceItemTemp, GuidedExperienceItem);

            PrevGuidedExperienceItem := GuidedExperienceItem;
        until GuidedExperienceItem.Next() = 0;
    end;

    local procedure ValidateGuidedExperienceItem(ObjectTypeToRun: ObjectType; ObjectIDToRun: Integer; Link: Text[250]; CheckObjectValidity: Boolean)
    begin
        if (ObjectIDToRun <> 0) and (Link <> '') then
            Error(ObjectAndLinkToRunErr);

        if Link = '' then begin
            if not (ObjectTypeToRun in [ObjectType::Page, ObjectType::Codeunit, ObjectType::Report, ObjectType::XmlPort]) then
                Error(InvalidObjectTypeErr);

            if CheckObjectValidity then
                if not IsObjectToRunValid(ObjectTypeToRun, ObjectIDToRun) then
                    Error(ObjectDoesNotExistErr, ObjectTypeToRun, ObjectIDToRun);
        end;
    end;

    local procedure GetCode(Type: Enum "Guided Experience Type"; ObjectType: Enum "Guided Experience Object Type"; ObjectID: Integer; Link: Text[250]): Code[300]
    begin
        exit(StrSubstNo(CodeFormatLbl, Type, ObjectType, ObjectID, Link));
    end;

    local procedure GetVersion(var GuidedExperienceItem: Record "Guided Experience Item"; Code: Code[300]; Title: Text[2048]; ShortTitle: Text[50]; Description: Text[1024]; ExpectedDuration: Integer; ExtensionId: Guid; GuidedExperienceType: Enum "Guided Experience Type"; ObjectTypeToRun: Enum "Guided Experience Object Type"; ObjectIDToRun: Integer; Link: Text[250]; AssistedSetupGroup: Enum "Assisted Setup Group"; VideoUrl: Text[250]; VideoCategory: Enum "Video Category"; HelpUrl: Text[250]; ManualSetupCategory: Enum "Manual Setup Category"; Keywords: Text[250]): Integer
    begin
        GuidedExperienceItem.SetRange(Code, Code);
        if not GuidedExperienceItem.FindLast() then
            exit(0);

        if HasTheRecordChanged(GuidedExperienceItem, Title, ShortTitle, Description, ExpectedDuration, ExtensionId, GuidedExperienceType, ObjectTypeToRun,
            ObjectIDToRun, Link, AssistedSetupGroup, VideoUrl, VideoCategory, HelpUrl, ManualSetupCategory, Keywords)
        then
            exit(GuidedExperienceItem.Version + 1);

        exit(-1);
    end;

    local procedure HasTheRecordChanged(GuidedExperienceItem: Record "Guided Experience Item"; Title: Text[2048]; ShortTitle: Text[50]; Description: Text[1024]; ExpectedDuration: Integer; ExtensionId: Guid; GuidedExperienceType: Enum "Guided Experience Type"; ObjectTypeToRun: Enum "Guided Experience Object Type"; ObjectIDToRun: Integer; Link: Text[250]; AssistedSetupGroup: Enum "Assisted Setup Group"; VideoUrl: Text[250]; VideoCategory: Enum "Video Category"; HelpUrl: Text[250]; ManualSetupCategory: Enum "Manual Setup Category"; Keywords: Text[250]): Boolean
    begin
        if (GuidedExperienceItem.Title <> Title)
            or (GuidedExperienceItem."Short Title" <> ShortTitle)
            or (GuidedExperienceItem.Description <> Description)
            or (GuidedExperienceItem."Expected Duration" <> ExpectedDuration)
            or (GuidedExperienceItem."Extension ID" <> ExtensionId)
            or (GuidedExperienceItem."Guided Experience Type" <> GuidedExperienceType)
            or (GuidedExperienceItem."Object Type to Run" <> ObjectTypeToRun)
            or (GuidedExperienceItem."Object ID to Run" <> ObjectIDToRun)
            or (GuidedExperienceItem.Link <> Link)
            or (GuidedExperienceItem."Assisted Setup Group" <> AssistedSetupGroup)
            or (GuidedExperienceItem."Video Url" <> VideoUrl)
            or (GuidedExperienceItem."Video Category" <> VideoCategory)
            or (GuidedExperienceItem."Help Url" <> HelpUrl)
            or (GuidedExperienceItem."Manual Setup Category" <> ManualSetupCategory)
            or (GuidedExperienceItem.Keywords <> Keywords) then
            exit(true);

        exit(false);
    end;

    local procedure InsertGuidedExperienceItem(var GuidedExperienceItem: Record "Guided Experience Item"; Code: Code[300]; Version: Integer; Title: Text[2048]; ShortTitle: Text[50]; Description: Text[1024]; ExpectedDuration: Integer; ExtensionId: Guid; Completed: Boolean; GuidedExperienceType: Enum "Guided Experience Type"; ObjectTypeToRun: Enum "Guided Experience Object Type"; ObjectIDToRun: Integer; Link: Text[250]; AssistedSetupGroup: Enum "Assisted Setup Group"; VideoUrl: Text[250]; VideoCategory: Enum "Video Category"; HelpUrl: Text[250]; ManualSetupCategory: Enum "Manual Setup Category"; Keywords: Text[250])
    var
        IconInStream: InStream;
    begin
        GuidedExperienceItem.Code := Code;
        GuidedExperienceItem.Version := Version;
        GuidedExperienceItem.Title := Title;
        GuidedExperienceItem."Short Title" := ShortTitle;
        GuidedExperienceItem.Description := Description;
        GuidedExperienceItem."Expected Duration" := ExpectedDuration;
        GuidedExperienceItem."Extension ID" := ExtensionId;
        GuidedExperienceItem.Completed := Completed;
        GuidedExperienceItem."Guided Experience Type" := GuidedExperienceType;
        GuidedExperienceItem."Object Type to Run" := ObjectTypeToRun;
        GuidedExperienceItem."Object ID to Run" := ObjectIDToRun;
        GuidedExperienceItem.Link := Link;
        GuidedExperienceItem."Assisted Setup Group" := AssistedSetupGroup;
        GuidedExperienceItem."Video Url" := VideoUrl;
        GuidedExperienceItem."Video Category" := VideoCategory;
        GuidedExperienceItem."Help Url" := HelpUrl;
        GuidedExperienceItem."Manual Setup Category" := ManualSetupCategory;
        GuidedExperienceItem.Keywords := Keywords;

        if GetIconInStream(IconInStream, ExtensionId) then
            GuidedExperienceItem.Icon.ImportStream(IconInStream, ExtensionId);

        GuidedExperienceItem.Insert();
    end;

    local procedure InsertTranslations(GuidedExperienceItem: Record "Guided Experience Item"; PrevVersionGuidedExperienceItem: Record "Guided Experience Item")
    var
        Translation: Codeunit Translation;
    begin
        Translation.Set(GuidedExperienceItem, GuidedExperienceItem.FieldNo(Title), GuidedExperienceItem.Title);
        Translation.Set(GuidedExperienceItem, GuidedExperienceItem.FieldNo("Short Title"), GuidedExperienceItem."Short Title");
        Translation.Set(GuidedExperienceItem, GuidedExperienceItem.FieldNo(Description), GuidedExperienceItem.Description);

        // if this isn't the first version of the record, copy all the existing translations for the title and the 
        // description if they haven't changed
        if GuidedExperienceItem.Version <> 0 then begin
            if PrevVersionGuidedExperienceItem.Title = GuidedExperienceItem.Title then
                CopyTranslations(PrevVersionGuidedExperienceItem, GuidedExperienceItem, GuidedExperienceItem.FieldNo(Title));
            if PrevVersionGuidedExperienceItem."Short Title" = GuidedExperienceItem."Short Title" then
                CopyTranslations(PrevVersionGuidedExperienceItem, GuidedExperienceItem, GuidedExperienceItem.FieldNo("Short Title"));
            if PrevVersionGuidedExperienceItem.Description = GuidedExperienceItem.Description then
                CopyTranslations(PrevVersionGuidedExperienceItem, GuidedExperienceItem, GuidedExperienceItem.FieldNo(Description));
        end;
    end;

    local procedure CopyTranslations(FromRecord: Record "Guided Experience Item"; ToRecord: Record "Guided Experience Item"; ForFieldId: Integer)
    var
        Translation: Record Translation;
        TranslationAPI: Codeunit Translation;
    begin
        Translation.SetRange(SystemId, FromRecord.SystemId);
        Translation.SetRange("Table ID", Database::"Guided Experience Item");
        Translation.SetRange("Field ID", ForFieldId);
        if Translation.FindSet() then
            repeat
                TranslationAPI.Set(ToRecord, ForFieldId, Translation."Language ID", Translation.Value);
            until Translation.Next() = 0;
    end;

    procedure GetObjectTypeToRun(var GuidedExperienceObjectType: Enum "Guided Experience Object Type"; ObjectType: ObjectType)
    begin
        case ObjectType of
            ObjectType::Page:
                GuidedExperienceObjectType := GuidedExperienceObjectType::Page;
            ObjectType::Codeunit:
                GuidedExperienceObjectType := GuidedExperienceObjectType::Codeunit;
            ObjectType::Report:
                GuidedExperienceObjectType := GuidedExperienceObjectType::Report;
            ObjectType::XmlPort:
                GuidedExperienceObjectType := GuidedExperienceObjectType::XmlPort;
            else
                GuidedExperienceObjectType := GuidedExperienceObjectType::Uninitialized;
        end
    end;

    procedure FilterGuidedExperienceItem(var GuidedExperienceItem: Record "Guided Experience Item"; GuidedExperienceType: Enum "Guided Experience Type"; ObjectType: ObjectType; ObjectID: Integer; Link: Text[250])
    var
        ObjectTypeToRun: Enum "Guided Experience Object Type";
    begin
        GetObjectTypeToRun(ObjectTypeToRun, ObjectType);

        FilterGuidedExperienceItem(GuidedExperienceItem, GuidedExperienceType, ObjectTypeToRun, ObjectID, Link);
    end;

    procedure FilterGuidedExperienceItem(var GuidedExperienceItem: Record "Guided Experience Item"; GuidedExperienceType: Enum "Guided Experience Type"; ObjectType: Enum "Guided Experience Object Type"; ObjectID: Integer; Link: Text[250])
    begin
        GuidedExperienceItem.SetCurrentKey("Guided Experience Type", "Object Type to Run", "Object ID to Run", Link, Version);
        GuidedExperienceItem.SetRange("Guided Experience Type", GuidedExperienceType);
        GuidedExperienceItem.SetRange("Object Type to Run", ObjectType);
        GuidedExperienceItem.SetRange("Object ID to Run", ObjectID);
        GuidedExperienceItem.SetRange(Link, Link);
    end;

    local procedure Complete(var GuidedExperienceItem: Record "Guided Experience Item")
    begin
        if GuidedExperienceItem.FindSet() then
            GuidedExperienceItem.ModifyAll(Completed, true);
    end;

    local procedure Reset(GuidedExperienceItem: Record "Guided Experience Item")
    begin
        if GuidedExperienceItem.FindSet() then
            repeat
                GuidedExperienceItem.Completed := false;
                GuidedExperienceItem.Modify();
            until GuidedExperienceItem.Next() = 0;
    end;

    local procedure Run(var GuidedExperienceItem: Record "Guided Experience Item")
    var
        ConfirmManagement: Codeunit "Confirm Management";
        GuidedExperience: Codeunit "Guided Experience";
#if not CLEAN18
        AssistedSetup: Codeunit "Assisted Setup";
        HandledAssistedSetup: Boolean;
#endif
        Handled: Boolean;
        ObjectType: ObjectType;
    begin
        ObjectType := GetObjectType(GuidedExperienceItem."Object Type to Run");

        if GuidedExperienceItem.Completed and (GuidedExperienceItem."Guided Experience Type" = GuidedExperienceItem."Guided Experience Type"::"Assisted Setup") then begin
            GuidedExperience.OnReRunOfCompletedAssistedSetup(GuidedExperienceItem."Extension ID", ObjectType,
                GuidedExperienceItem."Object ID to Run", Handled);

#if CLEAN18
            if Handled then
                exit;           
#else
            AssistedSetup.OnReRunOfCompletedSetup(GuidedExperienceItem."Extension ID", GuidedExperienceItem."Object ID to Run", HandledAssistedSetup);
            if Handled or HandledAssistedSetup then
                exit;
#endif

            if not ConfirmManagement.GetResponse(StrSubstNo(RunSetupAgainQst, GuidedExperienceItem.Title), false) then
                exit;
        end;

        Page.RunModal(GuidedExperienceItem."Object ID to Run");

#if not CLEAN18
        if GuidedExperienceItem."Guided Experience Type" = GuidedExperienceItem."Guided Experience Type"::"Assisted Setup" then
            AssistedSetup.OnAfterRun(GuidedExperienceItem."Extension ID", GuidedExperienceItem."Object ID to Run");
#endif
        if GuidedExperienceItem."Guided Experience Type" = GuidedExperienceItem."Guided Experience Type"::"Assisted Setup" then
            GuidedExperience.OnAfterRunAssistedSetup(GuidedExperienceItem."Extension ID", ObjectType, GuidedExperienceItem."Object ID to Run");
    end;

    procedure GetObjectType(GuidedExperienceObjectType: Enum "Guided Experience Object Type"): ObjectType
    begin
        case GuidedExperienceObjectType of
            GuidedExperienceObjectType::Uninitialized:
                exit;
            GuidedExperienceObjectType::Page:
                exit(ObjectType::Page);
            GuidedExperienceObjectType::Codeunit:
                exit(ObjectType::Codeunit);
            GuidedExperienceObjectType::Report:
                exit(ObjectType::Report);
            GuidedExperienceObjectType::XmlPort:
                exit(ObjectType::XmlPort);
        end;
    end;

    procedure RefreshAssistedSetup(var GuidedExperienceItemToRefresh: Record "Guided Experience Item")
    var
        GuidedExperienceItem: Record "Guided Experience Item";
    begin
        FilterGuidedExperienceItem(GuidedExperienceItem, GuidedExperienceItem."Guided Experience Type"::"Assisted Setup",
            GuidedExperienceItemToRefresh."Object Type to Run", GuidedExperienceItemToRefresh."Object ID to Run", '');

        if not GuidedExperienceItem.FindLast() then
            exit;

        GuidedExperienceItemToRefresh := GuidedExperienceItem;
        GuidedExperienceItemToRefresh.Modify();
    end;

    local procedure Delete(var GuidedExperienceItem: Record "Guided Experience Item")
    var
        ChecklistImplementation: Codeunit "Checklist Implementation";
    begin
        if GuidedExperienceItem.IsEmpty() then
            exit;

        ChecklistImplementation.Delete(GuidedExperienceItem.Code);

        GuidedExperienceItem.DeleteAll();
    end;

    local procedure InsertGuidedExperienceItemIfValid(var GuidedExperienceItemTemp: Record "Guided Experience Item" temporary; GuidedExperienceItem: Record "Guided Experience Item")
    begin
        if IsObjectToRunValid(GetObjectType(GuidedExperienceItem."Object Type to Run"), GuidedExperienceItem."Object ID to Run") then begin
            GuidedExperienceItemTemp.TransferFields(GuidedExperienceItem);
            GuidedExperienceItemTemp.Insert();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::Video, 'OnRegisterVideo', '', false, false)]
    local procedure OnRegisterVideo(Sender: Codeunit Video)
    var
        GuidedExperienceItem: Record "Guided Experience Item";
        PrevGuidedExperienceItem: Record "Guided Experience Item";
        GuidedExperience: Codeunit "Guided Experience";
    begin
        GuidedExperience.OnRegisterAssistedSetup();

        GuidedExperienceItem.SetCurrentKey("Object Type to Run", "Object ID to Run", Link, Version);
        GuidedExperienceItem.SetFilter("Video Url", '<>%1', '');
        if GuidedExperienceItem.FindSet() then begin
            repeat
                if (PrevGuidedExperienceItem."Object ID to Run" <> 0) and
                    ((GuidedExperienceItem."Object Type to Run" <> PrevGuidedExperienceItem."Object Type to Run") or (GuidedExperienceItem."Object Type to Run" <> PrevGuidedExperienceItem."Object Type to Run")) then
                    Sender.Register(PrevGuidedExperienceItem."Extension ID", CopyStr(PrevGuidedExperienceItem.Title, 1, 250), PrevGuidedExperienceItem."Video Url",
                        PrevGuidedExperienceItem."Video Category", Database::"Guided Experience Item", PrevGuidedExperienceItem.SystemId);

                PrevGuidedExperienceItem := GuidedExperienceItem;
            until GuidedExperienceItem.Next() = 0;

            Sender.Register(GuidedExperienceItem."Extension ID", CopyStr(GuidedExperienceItem.Title, 1, 250), GuidedExperienceItem."Video Url",
                GuidedExperienceItem."Video Category", Database::"Guided Experience Item", GuidedExperienceItem.SystemId);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Navigation Bar Subscribers", 'OnBeforeDefaultOpenRoleBasedSetupExperience', '', false, false)] // Assisted setup module
    local procedure OpenRoleBasedSetupExperience(var Handled: Boolean)
    var
        GuidedExperience: Codeunit "Guided Experience";
#if not CLEAN18
        AssistedSetup: Codeunit "Assisted Setup";
        HandledAssistedSetup: Boolean;
#endif
        RoleBasedSetupExperienceID: Integer;
    begin
        RoleBasedSetupExperienceID := Page::"Assisted Setup";

        GuidedExperience.OnBeforeOpenRoleBasedAssistedSetupExperience(RoleBasedSetupExperienceID, Handled);
#if not CLEAN18
        AssistedSetup.OnBeforeOpenRoleBasedSetupExperience(RoleBasedSetupExperienceID, HandledAssistedSetup);
        if not (HandledAssistedSetup or Handled) then
#else
        if not Handled then
#endif
            Page.Run(RoleBasedSetupExperienceID);

        Handled := true;
    end;

    local procedure GetIconInStream(var IconInStream: InStream; ExtensionId: Guid): Boolean
    var
        ExtensionManagement: Codeunit "Extension Management";
    begin
        ExtensionManagement.GetExtensionLogo(ExtensionId, TempBlob);

        if not TempBlob.HasValue() then
            exit(false);

        TempBlob.CreateInStream(IconInStream);
        exit(true);
    end;

    local procedure GetGuidedExperienceItemDimensions(var Dimensions: Dictionary of [Text, Text]; Title: Text[2048]; ShortTitle: Text[1024]; Description: Text[1024]; ExtensionName: Text[250])
    begin
        Dimensions.Add('Guided experience item title', Title);
        Dimensions.Add('Guided experience item short title', ShortTitle);
        Dimensions.Add('Guided experience item description', Description);
        Dimensions.Add('Guided experience item extension', ExtensionName);
    end;

    local procedure LogMessageOnDatabaseEvent(var Rec: Record "Guided Experience Item"; Tag: Text; Message: Text)
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        GetGuidedExperienceItemDimensions(Dimensions,
            Rec.Title, Rec."Short Title", Rec.Description, rec."Extension Name");
        Session.LogMessage(Tag, Message, Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation,
            TelemetryScope::ExtensionPublisher, Dimensions);
    end;


    [EventSubscriber(ObjectType::Table, Database::"Guided Experience Item", 'OnAfterInsertEvent', '', true, true)]
    local procedure OnAfterGuidedExperienceItemInsert(var Rec: Record "Guided Experience Item")
    begin
        LogMessageOnDatabaseEvent(Rec, '0000EIM', GuidedExperienceItemInsertedLbl);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Guided Experience Item", 'OnAfterDeleteEvent', '', true, true)]
    local procedure OnAfterGuidedExperienceItemDelete(var Rec: Record "Guided Experience Item")
    begin
        LogMessageOnDatabaseEvent(Rec, '0000EIN', GuidedExperienceItemDeletedLbl);
    end;
}