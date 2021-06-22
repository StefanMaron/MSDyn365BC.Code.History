page 5489 "Dimension Lines Entity"
{
    Caption = 'dimensionLines', Locked = true;
    DelayedInsert = true;
    EntityName = 'dimensionLine';
    EntitySetName = 'dimensionLines';
    PageType = API;
    SourceTable = "Dimension Set Entry Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(parentId; "Parent Id")
                {
                    ApplicationArea = All;
                    Caption = 'ParentId', Locked = true;
                }
                field(id; "Dimension Id")
                {
                    ApplicationArea = All;
                    Caption = 'Id', Locked = true;

                    trigger OnValidate()
                    begin
                        GlobalDimension.SetRange(Id, "Dimension Id");
                        if not GlobalDimension.FindFirst then
                            Error(DimensionIdDoesNotMatchADimensionErr);

                        "Dimension Code" := GlobalDimension.Code;
                    end;
                }
                field("code"; "Dimension Code")
                {
                    ApplicationArea = All;
                    Caption = 'Code', Locked = true;

                    trigger OnValidate()
                    begin
                        if GlobalDimension.Code <> '' then begin
                            if GlobalDimension.Code <> "Dimension Code" then
                                Error(DimensionFieldsDontMatchErr);
                            exit;
                        end;

                        if not GlobalDimension.Get("Dimension Code") then
                            Error(DimensionCodeDoesNotMatchADimensionErr);

                        "Dimension Id" := GlobalDimension.Id;
                    end;
                }
                field(displayName; "Dimension Name")
                {
                    ApplicationArea = All;
                    Caption = 'DisplayName', Locked = true;
                }
                field(valueId; GlobalDimensionValueId)
                {
                    ApplicationArea = All;
                    Caption = 'ValueId', Locked = true;
                    ToolTip = 'Specifies the ID of the Dimension value.';

                    trigger OnValidate()
                    begin
                        GlobalDimensionValue.SetRange(Id, GlobalDimensionValueId);
                        if not GlobalDimensionValue.FindFirst then
                            Error(DimensionValueIdDoesNotMatchADimensionValueErr);

                        GlobalDimensionValueCode := GlobalDimensionValue.Code;
                    end;
                }
                field(valueCode; GlobalDimensionValueCode)
                {
                    ApplicationArea = All;
                    Caption = 'ValueCode', Locked = true;
                    ToolTip = 'Specifies the Code of the Dimension value.';

                    trigger OnValidate()
                    begin
                        if GlobalDimensionValue.Code <> '' then begin
                            if GlobalDimensionValue.Code <> GlobalDimensionValueCode then
                                Error(DimensionValueFieldsDontMatchErr);
                            exit;
                        end;

                        if not GlobalDimensionValue.Get("Dimension Code", GlobalDimensionValueCode) then
                            Error(DimensionValueCodeDoesNotMatchADimensionValueErr);

                        GlobalDimensionValueId := GlobalDimensionValue.Id;
                    end;
                }
                field(valueDisplayName; "Dimension Value Name")
                {
                    ApplicationArea = All;
                    Caption = 'ValueDisplayName', Locked = true;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        SetCalculatedFields;
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        Delete(true);
        SaveDimensions;
        exit(false);
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        ParentIdFilter: Text;
    begin
        ParentIdFilter := GetFilter("Parent Id");
        if ParentIdFilter = '' then
            Error(ParentIDNotSpecifiedErr);
        exit(LoadLinesFromFilter(ParentIdFilter));
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        DimensionId: Guid;
        BlankGUID: Guid;
    begin
        if "Parent Id" = BlankGUID then
            Error(ParentIDRequiredErr);

        CheckIfValuesAreProperlyFilled;
        AssignDimensionValueToRecord;

        DimensionId := "Dimension Id";
        Insert(true);

        LoadLinesFromFilter("Parent Id");
        SaveDimensions;

        LoadLinesFromFilter("Parent Id");
        Get("Parent Id", DimensionId);
        SetCalculatedFields;

        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    var
        DimensionId: Guid;
    begin
        Evaluate(DimensionId, GetFilter("Dimension Id"));
        if "Dimension Id" <> DimensionId then
            Error(IdAndCodeCannotBeModifiedErr);

        AssignDimensionValueToRecord;
        Modify(true);

        SaveDimensions;
        LoadLinesFromFilter(GetFilter("Parent Id"));
        Get("Parent Id", DimensionId);
        SetCalculatedFields;

        exit(false);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        ClearCalculatedFields;
    end;

    var
        GlobalDimension: Record Dimension;
        GlobalDimensionValue: Record "Dimension Value";
        GlobalDimensionValueId: Guid;
        GlobalDimensionValueCode: Code[20];
        LinesLoaded: Boolean;
        ParentIDNotSpecifiedErr: Label 'You must specify a parent id to get the lines.', Locked = true;
        ParentIDRequiredErr: Label 'The parent ID must be filled in.', Locked = true;
        IdOrCodeShouldBeFilledErr: Label 'The ID or Code field must be filled in.', Locked = true;
        ValueIdOrValueCodeShouldBeFilledErr: Label 'The valueId or valueCode field must be filled in.', Locked = true;
        IdAndCodeCannotBeModifiedErr: Label 'The ID and Code fields cannot be modified.', Locked = true;
        RecordDoesntExistErr: Label 'Could not find the record.', Locked = true;
        RecordWasDeletedErr: Label 'The record was deleted.', Locked = true;
        DimensionFieldsDontMatchErr: Label 'The dimension field values do not match to a specific Dimension.', Locked = true;
        DimensionIdDoesNotMatchADimensionErr: Label 'The "id" does not match to a Dimension.', Locked = true;
        DimensionCodeDoesNotMatchADimensionErr: Label 'The "code" does not match to a Dimension.', Locked = true;
        DimensionValueFieldsDontMatchErr: Label 'The values of the Dimension Code field and the Dimension ID field do not refer to the same Dmension Value.', Locked = true;
        DimensionValueIdDoesNotMatchADimensionValueErr: Label 'The "valueId" does not match to a Dimension Value.', Locked = true;
        DimensionValueCodeDoesNotMatchADimensionValueErr: Label 'The "valueCode" does not match to a Dimension Value.', Locked = true;

    local procedure LoadLinesFromFilter(ParentIdFilter: Text): Boolean
    var
        FilterView: Text;
    begin
        if not LinesLoaded then begin
            FilterView := GetView;
            LoadLinesFromId(ParentIdFilter);
            SetView(FilterView);
            if not FindFirst then
                exit(false);
            LinesLoaded := true;
        end;

        exit(true);
    end;

    local procedure LoadLinesFromId(IntegrationId: Text)
    var
        TempDimensionSetEntry: Record "Dimension Set Entry" temporary;
        DimensionManagement: Codeunit DimensionManagement;
        DimensionSetId: Integer;
    begin
        DimensionSetId := GetSetId(IntegrationId);
        if DimensionSetId = 0 then
            exit;

        TempDimensionSetEntry.SetAutoCalcFields("Dimension Name", "Dimension Value Name");
        DimensionManagement.GetDimensionSet(TempDimensionSetEntry, DimensionSetId);

        if not TempDimensionSetEntry.Find('-') then
            exit;

        repeat
            Clear(Rec);
            TransferFields(TempDimensionSetEntry, true);
            "Parent Id" := IntegrationId;
            Insert(true);
        until TempDimensionSetEntry.Next = 0;
    end;

    local procedure GetSetId(IntegrationId: Text): Integer
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        if GenJournalLine.GetBySystemId(IntegrationId) then
            exit(GenJournalLine."Dimension Set ID");

        Error(RecordDoesntExistErr);
    end;

    local procedure SaveDimensions()
    var
        TempDimensionSetEntry: Record "Dimension Set Entry" temporary;
        GenJournalLine: Record "Gen. Journal Line";
        DimensionManagement: Codeunit DimensionManagement;
        ParentSystemId: Guid;
    begin
        ParentSystemId := "Parent Id";

        Reset;
        if FindFirst then
            repeat
                TempDimensionSetEntry.TransferFields(Rec, true);
                TempDimensionSetEntry."Dimension Set ID" := 0;
                TempDimensionSetEntry.Insert(true);
            until Next = 0;

        if GenJournalLine.GetBySystemId(ParentSystemId) then begin
            GenJournalLine."Dimension Set ID" := DimensionManagement.GetDimensionSetID(TempDimensionSetEntry);
            DimensionManagement.UpdateGlobalDimFromDimSetID(
                      GenJournalLine."Dimension Set ID", GenJournalLine."Shortcut Dimension 1 Code", GenJournalLine."Shortcut Dimension 2 Code");
            GenJournalLine.Modify(true);
        end else
            Error(RecordDoesntExistErr);
    end;

    local procedure CheckIfValuesAreProperlyFilled()
    begin
        if "Dimension Code" = '' then
            Error(IdOrCodeShouldBeFilledErr);

        if IsNullGuid(GlobalDimensionValueId) and
           (GlobalDimensionValueCode = '')
        then
            Error(ValueIdOrValueCodeShouldBeFilledErr);
    end;

    local procedure AssignDimensionValueToRecord()
    begin
        if not IsNullGuid(GlobalDimensionValueId) then
            Validate("Value Id", GlobalDimensionValueId);

        if GlobalDimensionValueCode <> '' then
            Validate("Dimension Value Code", GlobalDimensionValueCode);
    end;

    local procedure SetCalculatedFields()
    begin
        GlobalDimensionValueId := "Value Id";
        GlobalDimensionValueCode := "Dimension Value Code";
    end;

    local procedure ClearCalculatedFields()
    begin
        Clear(GlobalDimensionValueId);
        Clear(GlobalDimensionValueCode);
    end;
}

