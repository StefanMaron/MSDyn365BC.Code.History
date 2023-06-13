codeunit 5931 "Resource Skill Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'Do you want to update the skill code on the related items and service items?';
        Text001: Label 'Do you want to update the skill code on the related service items?';
        Text002: Label 'Do you want to assign the skill codes of %1 %2 to %3 %4?';
        Text003: Label 'Do you want to delete skill codes on the related items and service items?';
        Text004: Label 'Do you want to delete skill codes on the related service items?';
        Text005: Label 'You have changed the skill code on the item.';
        Text006: Label 'How do you want to update the resource skill codes on the related service items?';
        Text007: Label 'Change the skill codes to the selected value.';
        Text008: Label 'Delete the skill codes or update their relation.';
        Text010: Label 'You have changed the skill code on the service item group.';
        Text011: Label 'How do you want to update the resource skill codes on the related items and service items?';
        Text012: Label 'Change the skill codes to the selected value.';
        Text013: Label 'Delete the skill codes or update their relation.';
        Text015: Label 'You have deleted the skill code(s) on the item.';
        Text016: Label 'How do you want to update the resource skill codes on the related service items?';
        Text017: Label 'Delete all the related skill codes.';
        Text018: Label 'Leave all the related skill codes.';
        Text019: Label 'You have deleted the skill code(s) on the service item group.';
        Text020: Label 'How do you want to update the resource skill codes on the related items and service items?';
        Text021: Label 'Delete all the related skill codes.';
        Text022: Label 'Leave all the related skill codes.';
        Text023: Label 'How do you want to update the resource skill codes assigned from Item and Service Item Group?';
        Text024: Label 'Delete old skill codes and assign new.';
        Text025: Label 'Leave old skill codes and do not assign new.';
        Text026: Label 'You have changed the service item group assigned to this service item/item.';
        Text027: Label 'You have changed Item No. on this service item.';
        Text028: Label 'Do you want to assign the skill codes of the item and its service item group to service item?';
        Text029: Label 'How do you want to update the resource skill codes assigned from Service Item Group?';
        SkipValidationDialog: Boolean;
        Update2: Boolean;
        AssignCodesWithUpdate: Boolean;
        Text030: Label '%1,%2', Comment = 'Delete all the related skill codes. Leave all the related skill codes.';
        Text031: Label '%1\\%2', Comment = 'You have deleted the skill code(s) on the item.\\How do you want to update the resource skill codes on the related service items?  ';

    procedure AddResSkill(var ResSkill: Record "Resource Skill")
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        with ResSkill do
            if (Type = Type::"Service Item Group") or
               (Type = Type::Item)
            then
                if IsRelatedObjectsExist(ResSkill) then begin
                    if not SkipValidationDialog then
                        case Type of
                            Type::"Service Item Group":
                                if not ConfirmManagement.GetResponseOrDefault(Text000, true) then
                                    exit;
                            Type::Item:
                                if not ConfirmManagement.GetResponseOrDefault(Text001, true) then
                                    exit;
                        end;
                    AddResSkillWithUpdate(ResSkill);
                end;
    end;

    local procedure AddResSkillWithUpdate(var ResSkill: Record "Resource Skill")
    begin
        case ResSkill.Type of
            ResSkill.Type::"Service Item Group":
                begin
                    AddResSkillToServItems(ResSkill);
                    AddResSkillToItems(ResSkill);
                end;
            ResSkill.Type::Item:
                AddResSkillToServItems(ResSkill)
        end;
    end;

    local procedure AddResSkillToServItems(var ResSkill: Record "Resource Skill")
    var
        ServiceItem: Record "Service Item";
    begin
        with ResSkill do begin
            case Type of
                Type::"Service Item Group":
                    ServiceItem.SetRange("Service Item Group Code", "No.");
                Type::Item:
                    ServiceItem.SetRange("Item No.", "No.");
            end;
            if ServiceItem.Find('-') then
                repeat
                    UnifyResSkillCode(Type::"Service Item", ServiceItem."No.", ResSkill);
                until ServiceItem.Next() = 0;
        end;
    end;

    local procedure AddResSkillToItems(var ResSkill: Record "Resource Skill")
    var
        Item: Record Item;
        AddedResSkill: Record "Resource Skill";
    begin
        with Item do begin
            SetRange("Service Item Group", ResSkill."No.");
            if Find('-') then
                repeat
                    if UnifyResSkillCode(ResSkill.Type::Item, "No.", ResSkill) then begin
                        if AddedResSkill.Get(AddedResSkill.Type::Item, "No.", ResSkill."Skill Code") then
                            AddResSkillToServItems(AddedResSkill);
                    end;
                until Next() = 0;
        end;
    end;

    local procedure UnifyResSkillCode(ObjectType: Enum "Resource Skill Type"; ObjectNo: Code[20]; var UnifiedResSkill: Record "Resource Skill"): Boolean
    var
        NewResSkill: Record "Resource Skill";
        ExistingResSkill: Record "Resource Skill";
    begin
        with NewResSkill do begin
            if not ExistingResSkill.Get(ObjectType, ObjectNo, UnifiedResSkill."Skill Code") then begin
                Init();
                Type := ObjectType;
                "No." := ObjectNo;
                "Skill Code" := UnifiedResSkill."Skill Code";

                if UnifiedResSkill.Type = Type::Item then
                    "Assigned From" := "Assigned From"::Item;
                if UnifiedResSkill.Type = Type::"Service Item Group" then
                    "Assigned From" := "Assigned From"::"Service Item Group";

                if UnifiedResSkill."Source Type" = "Source Type"::" " then begin
                    "Source Code" := UnifiedResSkill."No.";
                    if UnifiedResSkill.Type = UnifiedResSkill.Type::Item then
                        "Source Type" := "Source Type"::Item;
                    if UnifiedResSkill.Type = Type::"Service Item Group" then
                        "Source Type" := "Source Type"::"Service Item Group";
                end else begin
                    "Source Code" := UnifiedResSkill."Source Code";
                    "Source Type" := UnifiedResSkill."Source Type";
                end;

                OnUnifyResSkillCodeOnBeforeInsert(NewResSkill, UnifiedResSkill);

                Insert();
                exit(true);
            end;
            exit;
        end;
    end;

    procedure RemoveResSkill(var ResSkill: Record "Resource Skill"): Boolean
    var
        SelectedOption: Integer;
        RelatedResSkillsExist: Boolean;
        Update: Boolean;
    begin
        RelatedResSkillsExist := IsRelatedResSkillsExist(ResSkill);

        if not SkipValidationDialog then begin
            if RelatedResSkillsExist then begin
                case ResSkill.Type of
                    ResSkill.Type::Item:
                        SelectedOption := RunOptionDialog(Text015, Text016, Text017, Text018);
                    ResSkill.Type::"Service Item Group":
                        SelectedOption := RunOptionDialog(Text019, Text020, Text021, Text022);
                end;

                case SelectedOption of
                    0:
                        Update := true;
                    1:
                        Update := false;
                    2:
                        begin
                            SkipValidationDialog := false;
                            Update2 := false;
                            Error('');
                        end;
                end;
            end;
        end else
            Update := Update2;

        if RelatedResSkillsExist then begin
            case ResSkill.Type of
                ResSkill.Type::Item:
                    RemoveItemResSkill(ResSkill, Update, false);
                ResSkill.Type::"Service Item Group":
                    RemoveServItemGroupResSkill(ResSkill, Update);
            end;
            exit(true);
        end;
    end;

    procedure PrepareRemoveMultipleResSkills(var ResSkill: Record "Resource Skill")
    var
        SelectedOption: Integer;
    begin
        if not SkipValidationDialog then
            if ResSkill.Find('-') then
                repeat
                    if IsRelatedResSkillsExist(ResSkill) then begin
                        SkipValidationDialog := true;
                        case ResSkill.Type of
                            ResSkill.Type::Item:
                                SelectedOption := RunOptionDialog(Text015, Text016, Text017, Text018);
                            ResSkill.Type::"Service Item Group":
                                SelectedOption := RunOptionDialog(Text019, Text020, Text021, Text022);
                        end;

                        case SelectedOption of
                            0:
                                Update2 := true;
                            1:
                                Update2 := false;
                            2:
                                begin
                                    SkipValidationDialog := false;
                                    Update2 := false;
                                    Error('');
                                end;
                        end;
                        exit
                    end;
                until ResSkill.Next() = 0;
    end;

    local procedure RemoveItemResSkill(var ResSkill: Record "Resource Skill"; Update: Boolean; IsReassigned: Boolean)
    var
        ExistingResSkill: Record "Resource Skill";
        ExistingResSkill2: Record "Resource Skill";
        ServItem: Record "Service Item";
    begin
        with ExistingResSkill do begin
            if not IsReassigned then begin
                SetCurrentKey("Assigned From", "Source Type", "Source Code");
                SetRange("Assigned From", "Assigned From"::Item);
                SetRange("Source Type", "Source Type"::Item);
                SetRange("Source Code", ResSkill."No.");
                SetRange(Type, Type::"Service Item");
                SetRange("Skill Code", ResSkill."Skill Code");
                if Find('-') then
                    if Update then
                        DeleteAll()
                    else
                        ConvertResSkillsToOriginal(ExistingResSkill);
            end;

            ServItem.SetCurrentKey("Item No.");
            ServItem.SetRange("Item No.", ResSkill."No.");
            if ServItem.Find('-') then
                repeat
                    Reset();
                    SetCurrentKey("Assigned From", "Source Type", "Source Code");
                    SetRange("Assigned From", "Assigned From"::Item);
                    SetRange("Source Type", "Source Type"::"Service Item Group");
                    SetRange(Type, Type::"Service Item");
                    SetRange("No.", ServItem."No.");
                    SetRange("Skill Code", ResSkill."Skill Code");
                    if Find('-') then
                        repeat
                            ExistingResSkill2 := ExistingResSkill;
                            if ServItem."Service Item Group Code" = "Source Code" then begin
                                ExistingResSkill2."Assigned From" := "Assigned From"::"Service Item Group";
                                ExistingResSkill2.Modify();
                            end else begin
                                if Update then
                                    ExistingResSkill2.Delete()
                                else
                                    if IsReassigned then begin
                                        ExistingResSkill2."Source Type" := "Source Type"::Item;
                                        ExistingResSkill2."Source Code" := ResSkill."No.";
                                        ExistingResSkill2.Modify();
                                    end else
                                        ConvertResSkillToOriginal(ExistingResSkill2, true)
                            end;
                        until Next() = 0;
                until ServItem.Next() = 0;
        end;
    end;

    local procedure RemoveServItemGroupResSkill(var ResSkill: Record "Resource Skill"; Update: Boolean)
    var
        ExistingResSkill: Record "Resource Skill";
        ExistingResSkill2: Record "Resource Skill";
        ServItem: Record "Service Item";
    begin
        with ExistingResSkill do
            if Update then begin
                SetCurrentKey("Source Type", "Source Code");
                SetRange("Source Type", "Source Type"::"Service Item Group");
                SetRange("Source Code", ResSkill."No.");
                SetRange("Skill Code", ResSkill."Skill Code");
                DeleteAll();
            end else begin
                SetCurrentKey("Assigned From", "Source Type", "Source Code");
                SetRange("Assigned From", "Assigned From"::"Service Item Group");
                SetRange("Source Code", ResSkill."No.");
                SetRange("Skill Code", ResSkill."Skill Code");
                ConvertResSkillsToOriginal(ExistingResSkill);

                Reset();
                SetCurrentKey("Assigned From", "Source Type", "Source Code");
                SetRange("Assigned From", "Assigned From"::Item);
                SetRange("Source Type", "Source Type"::"Service Item Group");
                SetRange("Source Code", ResSkill."No.");
                SetRange("Skill Code", ResSkill."Skill Code");
                if Find('-') then
                    repeat
                        if ServItem.Get("No.") then begin
                            ExistingResSkill2 := ExistingResSkill;
                            ExistingResSkill2."Source Type" := "Source Type"::Item;
                            ExistingResSkill2."Source Code" := ServItem."Item No.";
                            ExistingResSkill2.Modify();
                        end;
                    until Next() = 0;
            end;
    end;

    procedure ChangeResSkill(var ResSkill: Record "Resource Skill"; OldSkillCode: Code[10]): Boolean
    var
        TempOldResSkill: Record "Resource Skill" temporary;
        SelectedOption: Integer;
        Update: Boolean;
    begin
        TempOldResSkill := ResSkill;
        TempOldResSkill."Skill Code" := OldSkillCode;
        with ResSkill do begin
            if ("Assigned From" <> "Assigned From"::" ") or
               ("Source Type" <> "Source Type"::" ")
            then
                ConvertResSkillToOriginal(ResSkill, false);

            if IsRelatedResSkillsExist(TempOldResSkill) then begin
                case TempOldResSkill.Type of
                    Type::Item:
                        SelectedOption := RunOptionDialog(Text005, Text006, Text007, Text008);
                    Type::"Service Item Group":
                        SelectedOption := RunOptionDialog(Text010, Text011, Text012, Text013);
                    Type::"Service Item":
                        SelectedOption := 1;
                end;

                case SelectedOption of
                    0:
                        Update := true;
                    1:
                        Update := false;
                    2:
                        begin
                            exit;
                        end
                end;

                if Type <> Type::"Service Item" then
                    if Update then begin
                        case Type of
                            Type::"Service Item Group":
                                ChangeServItemGroupResSkill(ResSkill, OldSkillCode);
                            Type::Item:
                                ChangeItemResSkill(ResSkill, OldSkillCode);
                        end;
                    end else
                        RemoveResSkill(TempOldResSkill);
            end;
        end;

        exit(true);
    end;

    local procedure ChangeServItemGroupResSkill(var ResSkill: Record "Resource Skill"; OldSkillCode: Code[10])
    var
        ExistingResSkill: Record "Resource Skill";
        ExistingResSkill2: Record "Resource Skill";
        ExistingResSkill3: Record "Resource Skill";
    begin
        with ExistingResSkill do begin
            SetRange("Skill Code", OldSkillCode);
            SetRange("Source Type", "Source Type"::"Service Item Group");
            SetRange("Source Code", ResSkill."No.");
            if Find('-') then
                repeat
                    ExistingResSkill3 := ExistingResSkill;
                    if not ExistingResSkill2.Get(Type, "No.", ResSkill."Skill Code") then
                        ExistingResSkill3.Rename(Type, "No.", ResSkill."Skill Code")
                    else
                        ExistingResSkill3.Delete();
                until Next() = 0;
        end;
    end;

    local procedure ChangeItemResSkill(var ResSkill: Record "Resource Skill"; OldSkillCode: Code[10])
    var
        ExistingResSkill: Record "Resource Skill";
        ExistingResSkill2: Record "Resource Skill";
        ServItem: Record "Service Item";
    begin
        with ExistingResSkill do begin
            ServItem.SetCurrentKey("Item No.");
            ServItem.SetRange("Item No.", ResSkill."No.");
            if ServItem.Find('-') then
                repeat
                    SetRange(Type, Type::"Service Item");
                    SetRange("No.", ServItem."No.");
                    SetRange("Skill Code", OldSkillCode);
                    SetRange("Assigned From", "Assigned From"::Item);
                    if FindFirst() then
                        if not ExistingResSkill2.Get(Type, "No.", ResSkill."Skill Code") then begin
                            Rename(Type, "No.", ResSkill."Skill Code");
                            "Source Type" := "Source Type"::Item;
                            "Source Code" := ResSkill."No.";
                            Modify();
                        end else
                            Delete();
                until ServItem.Next() = 0;
        end;
    end;

    procedure AssignServItemResSkills(var ServItem: Record "Service Item")
    var
        ResSkill: Record "Resource Skill";
        SrcType: Enum "Resource Skill Type";
    begin
        SrcType := ResSkill.Type::"Service Item";
        AssignResSkillRelationWithUpdate(SrcType, ServItem."No.", ResSkill.Type::Item, ServItem."Item No.");
        AssignResSkillRelationWithUpdate(SrcType, ServItem."No.", ResSkill.Type::"Service Item Group", ServItem."Service Item Group Code");
    end;

    local procedure AssignRelationConfirmation(SrcType: Enum "Resource Skill Type"; SrcCode: Code[20]; DestType: Enum "Resource Skill Type"; DestCode: Code[20]): Boolean
    var
        ServItemGroup: Record "Service Item Group";
        ServItem: Record "Service Item";
        Item: Record Item;
        ResSkill: Record "Resource Skill";
        ConfirmManagement: Codeunit "Confirm Management";
        SrcTypeText: Text[30];
        DestTypeText: Text[30];
    begin
        with ResSkill do begin
            SetRange(Type, DestType);
            SetRange("No.", DestCode);
            if FindFirst() then begin
                case DestType of
                    Type::"Service Item Group":
                        DestTypeText := ServItemGroup.TableCaption();
                    Type::Item:
                        DestTypeText := Item.TableCaption();
                end;

                case SrcType of
                    Type::Item:
                        SrcTypeText := Item.TableCaption();
                    Type::"Service Item":
                        SrcTypeText := ServItem.TableCaption();
                end;

                OnAfterAssignRelationConfirmation(ResSkill, SrcType, DestType, DestTypeText, SrcTypeText);

                exit(ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text002, DestTypeText, DestCode, SrcTypeText, SrcCode), true));
            end;
        end;
    end;

    procedure AssignResSkillRelationWithUpdate(SrcType: Enum "Resource Skill Type"; SrcCode: Code[20]; DestType: Enum "Resource Skill Type"; DestCode: Code[20])
    var
        OriginalResSkill: Record "Resource Skill";
        AddedResSkill: Record "Resource Skill";
    begin
        with OriginalResSkill do begin
            SetRange(Type, DestType);
            SetRange("No.", DestCode);
            if Find('-') then
                repeat
                    if UnifyResSkillCode(SrcType, SrcCode, OriginalResSkill) then
                        if SrcType = Type::Item then begin
                            if AddedResSkill.Get(SrcType, SrcCode, "Skill Code") then
                                AddResSkillToServItems(AddedResSkill);
                        end;
                until Next() = 0
        end;
    end;

    procedure DeleteItemResSkills(ItemNo: Code[20])
    var
        ExistingResSkill: Record "Resource Skill";
        ExistingResSkill2: Record "Resource Skill";
        ServiceItem: Record "Service Item";
        ConfirmManagement: Codeunit "Confirm Management";
        Update: Boolean;
    begin
        with ExistingResSkill do begin
            SetCurrentKey("Source Type", "Source Code");
            SetRange("Source Type", "Source Type"::Item);
            SetRange("Source Code", ItemNo);
            if Find('-') then
                Update := ConfirmManagement.GetResponseOrDefault(Text004, true)
            else
                Update := true;

            LockTable();
            Reset();
            SetRange(Type, Type::Item);
            SetRange("No.", ItemNo);
            if Find('-') then begin
                repeat
                    ExistingResSkill2 := ExistingResSkill;
                    RemoveItemResSkill(ExistingResSkill2, Update, false);
                    ExistingResSkill2.Delete();
                until Next() = 0;

                ServiceItem.Reset();
                ServiceItem.SetRange("Item No.", ItemNo);
                if ServiceItem.Find('-') then
                    repeat
                        RemoveServItemGroupRelation(ServiceItem."No.", Update, Type::"Service Item");
                    until ServiceItem.Next() = 0;
            end;
        end;
    end;

    procedure DeleteServItemGrResSkills(ServItemGrCode: Code[10])
    var
        ExistingResSkill: Record "Resource Skill";
        ExistingResSkill2: Record "Resource Skill";
        ConfirmManagement: Codeunit "Confirm Management";
        Update: Boolean;
    begin
        with ExistingResSkill do begin
            SetCurrentKey("Source Type", "Source Code");
            SetRange("Source Type", "Source Type"::"Service Item Group");
            SetRange("Source Code", ServItemGrCode);
            if Find('-') then
                Update := ConfirmManagement.GetResponseOrDefault(Text003, true)
            else
                Update := true;

            LockTable();
            Reset();
            SetRange(Type, Type::"Service Item Group");
            SetRange("No.", ServItemGrCode);
            if Find('-') then
                repeat
                    ExistingResSkill2 := ExistingResSkill;
                    RemoveServItemGroupResSkill(ExistingResSkill2, Update);
                    ExistingResSkill2.Delete();
                until Next() = 0;
        end;
    end;

    procedure DeleteServItemResSkills(ServItemNo: Code[20])
    var
        ExistingResSkill: Record "Resource Skill";
    begin
        with ExistingResSkill do begin
            LockTable();
            SetRange(Type, Type::"Service Item");
            SetRange("No.", ServItemNo);
            DeleteAll();
        end;
    end;

    procedure ChangeResSkillRelationWithItem(SrcType: Enum "Resource Skill Type"; SrcCode: Code[20]; RelationType: Enum "Resource Skill Type"; DestCode: Code[20]; OriginalCode: Code[20]; ServItemGroupCode: Code[10]): Boolean
    var
        Item: Record Item;
        ExistingResSkill: Record "Resource Skill";
        ConfirmManagement: Codeunit "Confirm Management";
        SelectedOption: Integer;
        RemoveWithUpdate: Boolean;
        AssignWithUpdate: Boolean;
        ResSkillCodesExistRelatedItem: Boolean;
        ResSkillCodesExistRelatedSIG: Boolean;
        ResSkillCodesItemExist: Boolean;
        IsHandled: Boolean;
    begin
        if not SkipValidationDialog then begin
            with ExistingResSkill do begin
                if OriginalCode <> '' then begin
                    SetRange(Type, Type::"Service Item");
                    SetRange("No.", SrcCode);
                    SetRange("Assigned From", "Assigned From"::Item);
                    ResSkillCodesExistRelatedItem := FindFirst();
                end;
                if ServItemGroupCode <> '' then begin
                    SetRange("Assigned From", "Assigned From"::"Service Item Group");
                    ResSkillCodesExistRelatedSIG := FindFirst();
                end;
                if ResSkillCodesExistRelatedItem or ResSkillCodesExistRelatedSIG then begin
                    SelectedOption := RunOptionDialog(Text027, Text023, Text024, Text025);
                    case SelectedOption of
                        0:
                            RemoveWithUpdate := true;
                        1:
                            RemoveWithUpdate := false;
                        2:
                            exit;
                    end;
                    AssignWithUpdate := RemoveWithUpdate;
                end else begin
                    if DestCode <> '' then begin
                        Reset();
                        SetRange(Type, Type::Item);
                        SetRange("No.", DestCode);
                        ResSkillCodesItemExist := FindFirst();
                        if not ResSkillCodesItemExist then
                            if Item.Get(DestCode) then
                                if Item."Service Item Group" <> '' then begin
                                    SetRange(Type, Type::"Service Item Group");
                                    SetRange("No.", Item."Service Item Group");
                                    ResSkillCodesItemExist := FindFirst();
                                end;
                        if ResSkillCodesItemExist then begin
                            IsHandled := false;
                            OnChangeResSkillRelationWithItemOnBeforeAssignWithUpdateGetResponse(Item, AssignWithUpdate, IsHandled);
                            if not IsHandled then
                                AssignWithUpdate := ConfirmManagement.GetResponseOrDefault(Text028, true);
                        end;
                    end;
                    if Item.Get(DestCode) and AssignWithUpdate then
                        if Item."Service Item Group" <> '' then
                            AssignCodesWithUpdate := true;
                end;
            end;
        end else
            AssignWithUpdate := AssignCodesWithUpdate;

        if ResSkillCodesExistRelatedItem then
            RemoveItemRelation(SrcCode, RemoveWithUpdate);

        if ResSkillCodesExistRelatedSIG then
            RemoveServItemGroupRelation(SrcCode, RemoveWithUpdate, SrcType);

        if (DestCode <> '') and AssignWithUpdate then
            AssignResSkillRelationWithUpdate(SrcType, SrcCode, RelationType, DestCode);

        exit(true);
    end;

    procedure ChangeResSkillRelationWithGroup(SrcType: Enum "Resource Skill Type"; SrcCode: Code[20]; RelationType: Enum "Resource Skill Type"; DestCode: Code[20]; OriginalCode: Code[20]): Boolean
    var
        ExistingResSkill: Record "Resource Skill";
        SelectedOption: Integer;
        AssignWithUpdate: Boolean;
        RelatedResSkillCodesExist: Boolean;
        RemoveWithUpdate: Boolean;
    begin
        if not SkipValidationDialog then begin
            with ExistingResSkill do begin
                if OriginalCode <> '' then begin
                    SetRange(Type, SrcType);
                    SetRange("No.", SrcCode);
                    SetRange("Assigned From", "Assigned From"::"Service Item Group");
                    RelatedResSkillCodesExist := FindFirst();
                end;
                if RelatedResSkillCodesExist then begin
                    SelectedOption := RunOptionDialog(Text026, Text029, Text024, Text025);
                    case SelectedOption of
                        0:
                            RemoveWithUpdate := true;
                        1:
                            RemoveWithUpdate := false;
                        2:
                            exit;
                    end;
                    AssignWithUpdate := RemoveWithUpdate;
                end else
                    if DestCode <> '' then
                        AssignWithUpdate := AssignRelationConfirmation(SrcType, SrcCode, RelationType, DestCode);
            end;
        end else
            AssignWithUpdate := AssignCodesWithUpdate;

        if RelatedResSkillCodesExist then
            RemoveServItemGroupRelation(SrcCode, RemoveWithUpdate, SrcType);

        if (DestCode <> '') and AssignWithUpdate then
            AssignResSkillRelationWithUpdate(SrcType, SrcCode, RelationType, DestCode);

        exit(true);
    end;

    local procedure RemoveItemRelation(SrcCode: Code[20]; RemoveWithUpdate: Boolean)
    var
        ExistingResSkill: Record "Resource Skill";
        ExistingResSkill2: Record "Resource Skill";
        ServItem: Record "Service Item";
    begin
        with ExistingResSkill do begin
            SetRange(Type, Type::"Service Item");
            SetRange("No.", SrcCode);
            SetRange("Assigned From", "Assigned From"::Item);
            if Find('-') then
                repeat
                    ExistingResSkill2 := ExistingResSkill;
                    if "Source Type" = "Source Type"::Item then begin
                        if RemoveWithUpdate then
                            ExistingResSkill2.Delete()
                        else
                            ConvertResSkillsToOriginal(ExistingResSkill);
                    end else
                        if ServItem.Get("No.") then
                            if ServItem."Service Item Group Code" = "Source Code" then begin
                                ExistingResSkill2."Assigned From" := "Assigned From"::"Service Item Group";
                                ExistingResSkill2.Modify();
                            end else begin
                                if RemoveWithUpdate then
                                    ExistingResSkill2.Delete()
                                else
                                    ConvertResSkillToOriginal(ExistingResSkill2, true);
                            end;
                until Next() = 0;
        end;
    end;

    local procedure RemoveServItemGroupRelation(SrcCode: Code[20]; RemoveWithUpdate: Boolean; SrcType: Enum "Resource Skill Type")
    var
        ExistingResSkill: Record "Resource Skill";
        ExistingResSkill2: Record "Resource Skill";
    begin
        with ExistingResSkill do begin
            SetRange(Type, SrcType);
            SetRange("No.", SrcCode);
            SetRange("Assigned From", "Assigned From"::"Service Item Group");
            if Find('-') then
                repeat
                    ExistingResSkill2 := ExistingResSkill;
                    if SrcType = Type::Item then
                        RemoveItemResSkill(ExistingResSkill2, RemoveWithUpdate, true);
                    if RemoveWithUpdate then
                        ExistingResSkill2.Delete()
                    else
                        ConvertResSkillToOriginal(ExistingResSkill, true);
                until Next() = 0;
        end;
    end;

    local procedure ConvertResSkillToOriginal(var ResSkill: Record "Resource Skill"; AllowModify: Boolean)
    begin
        with ResSkill do begin
            "Assigned From" := "Assigned From"::" ";
            "Source Type" := "Source Type"::" ";
            "Source Code" := '';
            if AllowModify then
                Modify();
        end;
    end;

    local procedure ConvertResSkillsToOriginal(var ResSkill: Record "Resource Skill")
    begin
        with ResSkill do begin
            if Find('-') then
                repeat
                    ConvertResSkillToOriginal(ResSkill, true);
                until Next() = 0
        end;
    end;

    local procedure IsRelatedObjectsExist(var ResSkill: Record "Resource Skill"): Boolean
    var
        Item: Record Item;
        ServItem: Record "Service Item";
    begin
        with ResSkill do begin
            case Type of
                Type::"Service Item Group":
                    begin
                        ServItem.SetCurrentKey("Service Item Group Code");
                        ServItem.SetRange("Service Item Group Code", "No.");
                        if not ServItem.IsEmpty() then
                            exit(true);

                        Item.SetCurrentKey("Service Item Group");
                        Item.SetRange("Service Item Group", "No.");
                        exit(not Item.IsEmpty);
                    end;
                Type::Item:
                    begin
                        ServItem.SetCurrentKey("Item No.");
                        ServItem.SetRange("Item No.", "No.");
                        exit(not ServItem.IsEmpty);
                    end;
            end;
            exit
        end;
    end;

    local procedure IsRelatedResSkillsExist(var ResSkill: Record "Resource Skill"): Boolean
    var
        ExistingResSkill: Record "Resource Skill";
        ServItem: Record "Service Item";
    begin
        with ExistingResSkill do
            case ResSkill.Type of
                Type::Item:
                    begin
                        SetCurrentKey("Assigned From", "Source Type", "Source Code");
                        SetRange("Assigned From", "Assigned From"::Item);
                        SetRange("Source Type", "Source Type"::Item);
                        SetRange("Source Code", ResSkill."No.");
                        SetRange("Skill Code", ResSkill."Skill Code");
                        SetRange(Type, Type::"Service Item");
                        if not IsEmpty() then
                            exit(true);

                        ServItem.SetCurrentKey("Item No.");
                        ServItem.SetRange("Item No.", ResSkill."No.");
                        if ServItem.Find('-') then
                            repeat
                                Reset();
                                SetCurrentKey("Assigned From", "Source Type", "Source Code");
                                SetRange("Assigned From", "Assigned From"::Item);
                                SetRange("Source Type", "Source Type"::"Service Item Group");
                                SetRange(Type, Type::"Service Item");
                                SetRange("No.", ServItem."No.");
                                SetRange("Skill Code", ResSkill."Skill Code");
                                if not IsEmpty() then
                                    exit(true);
                            until ServItem.Next() = 0;
                    end;
                Type::"Service Item Group":
                    begin
                        SetCurrentKey("Source Type", "Source Code");
                        SetRange("Source Type", "Source Type"::"Service Item Group");
                        SetRange("Source Code", ResSkill."No.");
                        SetRange("Skill Code", ResSkill."Skill Code");
                        if not IsEmpty() then
                            exit(true);
                    end;
            end;
    end;

    local procedure RunOptionDialog(ProblemDescription: Text[200]; SolutionProposition: Text[200]; FirstStrategy: Text[200]; SecondStrategy: Text[200]): Integer
    var
        SelectedOption: Integer;
    begin
        SelectedOption := StrMenu(StrSubstNo(Text030, FirstStrategy, SecondStrategy), 1,
            StrSubstNo(Text031, ProblemDescription, SolutionProposition));

        if SelectedOption = 0 then
            exit(2);

        exit(SelectedOption - 1);
    end;

    procedure RevalidateResSkillRelation(SrcType: Enum "Resource Skill Type"; SrcCode: Code[20]; DestType: Enum "Resource Skill Type"; DestCode: Code[20]): Boolean
    var
        AssignRelation: Boolean;
    begin
        if IsNewCodesAdded(SrcType, SrcCode, DestType, DestCode) then begin
            if not SkipValidationDialog then
                AssignRelation := RevalidateRelationConfirmation(SrcType, SrcCode, DestType, DestCode)
            else
                AssignRelation := true;

            if AssignRelation then begin
                AssignResSkillRelationWithUpdate(SrcType, SrcCode, DestType, DestCode);
                exit(true)
            end;
        end;
    end;

    local procedure RevalidateRelationConfirmation(SrcType: Enum "Resource Skill Type"; SrcCode: Code[20]; DestType: Enum "Resource Skill Type"; DestCode: Code[20]): Boolean
    var
        ServItemGroup: Record "Service Item Group";
        ServItem: Record "Service Item";
        Item: Record Item;
        ResSkill: Record "Resource Skill";
        ConfirmManagement: Codeunit "Confirm Management";
        SrcTypeText: Text[30];
        DestTypeText: Text[30];
    begin
        with ResSkill do begin
            case DestType of
                Type::"Service Item Group":
                    DestTypeText := ServItemGroup.TableCaption();
                Type::Item:
                    DestTypeText := Item.TableCaption();
            end;

            case SrcType of
                Type::Item:
                    SrcTypeText := Item.TableCaption();
                Type::"Service Item":
                    SrcTypeText := ServItem.TableCaption();
            end;

            OnAfterRevalidateRelationConfirmation(ResSkill, SrcType, DestType, DestTypeText, SrcTypeText);

            exit(ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text002, DestTypeText, DestCode, SrcTypeText, SrcCode), true));
        end;
    end;

    local procedure IsNewCodesAdded(SrcType: Enum "Resource Skill Type"; SrcCode: Code[20]; DestType: Enum "Resource Skill Type"; DestCode: Code[20]): Boolean
    var
        DestResSkill: Record "Resource Skill";
        SrcResSkill: Record "Resource Skill";
    begin
        with DestResSkill do begin
            SetRange(Type, DestType);
            SetRange("No.", DestCode);
            if Find('-') then
                repeat
                    SrcResSkill.SetRange(Type, SrcType);
                    SrcResSkill.SetRange("No.", SrcCode);
                    SrcResSkill.SetRange("Skill Code", "Skill Code");
                    if SrcResSkill.IsEmpty() then
                        exit(true);
                until Next() = 0
        end;
    end;

    procedure DropGlobals()
    begin
        SkipValidationDialog := false;
        Update2 := false;
    end;

    procedure SkipValidationDialogs()
    begin
        SkipValidationDialog := true;
    end;

    procedure CloneObjectResourceSkills(ObjectType: Integer; SrcCode: Code[20]; DestCode: Code[20])
    var
        ResSkill: Record "Resource Skill";
        NewResSkill: Record "Resource Skill";
    begin
        with ResSkill do begin
            SetRange(Type, ObjectType);
            SetRange("No.", SrcCode);
            if Find('-') then
                repeat
                    NewResSkill.Init();
                    NewResSkill := ResSkill;
                    NewResSkill."No." := DestCode;
                    NewResSkill.Insert();
                until Next() = 0;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnifyResSkillCodeOnBeforeInsert(var NewResourceSkill: Record "Resource Skill"; var UnifiedResourceSkill: Record "Resource Skill")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignRelationConfirmation(var ResourceSkill: Record "Resource Skill"; SrcType: Enum "Resource Skill Type"; DestType: Enum "Resource Skill Type"; var SrcTypeText: Text[30]; var DestTypeText: Text[30])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnChangeResSkillRelationWithItemOnBeforeAssignWithUpdateGetResponse(Item: Record Item; var AssignWithUpdate: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRevalidateRelationConfirmation(var ResourceSkill: Record "Resource Skill"; SrcType: Enum "Resource Skill Type"; DestType: Enum "Resource Skill Type"; var SrcTypeText: Text[30]; var DestTypeText: Text[30])
    begin
    end;
}

