page 481 "Dimension Set ID Filter"
{
    Caption = 'Dimension Filter';
    DelayedInsert = true;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    RefreshOnActivate = true;
    ShowFilter = false;
    SourceTable = Dimension;
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control4)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Dimensions;
                    TableRelation = Dimension.Code;
                    ToolTip = 'Specifies the code for the dimension.';

                    trigger OnValidate()
                    var
                        Dimension: Record Dimension;
                    begin
                        if not Dimension.Get(Code) then begin
                            Dimension.SetFilter(Code, '%1', '@' + Code + '*');
                            if not Dimension.FindFirst then
                                Dimension.Get(Code);
                            Code := Dimension.Code;
                        end;
                        if Get(Code) then
                            Error(RecordAlreadyExistsErr);
                        Insert;
                        TempDimensionSetIDFilterLine.Code := '';
                        TempDimensionSetIDFilterLine."Dimension Code" := Code;
                        TempDimensionSetIDFilterLine.SetDimensionValueFilter('');
                        CurrPage.Update(false);
                    end;
                }
                field(DimensionValueFilter; DimensionValueFilter)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Filter';
                    ToolTip = 'Specifies the filter for the dimension values.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        DimensionValue: Record "Dimension Value";
                    begin
                        exit(DimensionValue.LookUpDimFilter(Code, Text));
                    end;

                    trigger OnValidate()
                    begin
                        TempDimensionSetIDFilterLine.Code := '';
                        TempDimensionSetIDFilterLine."Dimension Code" := Code;
                        TempDimensionSetIDFilterLine.SetDimensionValueFilter(DimensionValueFilter);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Clear Filter")
            {
                ApplicationArea = Dimensions;
                Caption = 'Clear Filter';
                Image = ClearFilter;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Remove the filter for all dimensions.';

                trigger OnAction()
                begin
                    TempDimensionSetIDFilterLine.Reset();
                    TempDimensionSetIDFilterLine.DeleteAll();
                    DeleteAll();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        DimensionValueFilter := TempDimensionSetIDFilterLine.GetDimensionValueFilter('', Code);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        TempDimensionSetIDFilterLine.Reset();
        TempDimensionSetIDFilterLine.SetRange(Code, '');
        TempDimensionSetIDFilterLine.SetRange("Dimension Code", Code);
        TempDimensionSetIDFilterLine.DeleteAll();
        Delete;
        CurrPage.Update(false);
        exit(false);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        exit(false);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        DimensionValueFilter := ''
    end;

    trigger OnOpenPage()
    begin
        TempDimensionSetIDFilterLine.SetRange(Code, '');
        TempDimensionSetIDFilterLine.SetRange("Line No.", 1);
        if TempDimensionSetIDFilterLine.FindSet then
            repeat
                Code := TempDimensionSetIDFilterLine."Dimension Code";
                Insert;
            until TempDimensionSetIDFilterLine.Next = 0;
    end;

    var
        TempDimensionSetIDFilterLine: Record "Dimension Set ID Filter Line" temporary;
        FilterNotification: Notification;
        NotificationGUID: Guid;
        DimensionValueFilter: Text;
        NotificationMsg: Label 'The view is filtered by dimensions:';
        RecordAlreadyExistsErr: Label 'The record already exists.';

    procedure LookupFilter() DimFilter: Text
    var
        DimensionMgt: Codeunit DimensionManagement;
        DimSetIDFilterPage: Page "Dimension Set ID Filter";
    begin
        DimSetIDFilterPage.SetTempDimensionSetIDFilterLine(TempDimensionSetIDFilterLine);
        DimSetIDFilterPage.Editable(true);
        DimSetIDFilterPage.RunModal;
        DimSetIDFilterPage.GetTempDimensionSetIDFilterLine(TempDimensionSetIDFilterLine);
        TempDimensionSetIDFilterLine.Reset();
        if not TempDimensionSetIDFilterLine.IsEmpty then begin
            GetDimSetIDsForFilter(DimensionMgt);
            DimFilter := DimensionMgt.GetDimSetFilter;
            if DimFilter = '' then
                DimFilter := '0&<>0';
            SendNotification;
        end else
            RecallNotification
    end;

    local procedure GetDimSetIDsForFilter(var DimensionMgt: Codeunit DimensionManagement)
    begin
        TempDimensionSetIDFilterLine.Reset();
        TempDimensionSetIDFilterLine.SetRange(Code, '');
        TempDimensionSetIDFilterLine.SetRange("Line No.", 1);
        if TempDimensionSetIDFilterLine.FindSet then
            repeat
                DimensionMgt.GetDimSetIDsForFilter(TempDimensionSetIDFilterLine."Dimension Code",
                  TempDimensionSetIDFilterLine.GetDimensionValueFilter(
                    TempDimensionSetIDFilterLine.Code, TempDimensionSetIDFilterLine."Dimension Code"));
            until TempDimensionSetIDFilterLine.Next = 0;
    end;

    procedure GetTempDimensionSetIDFilterLine(var NewTempDimensionSetIDFilterLine: Record "Dimension Set ID Filter Line" temporary)
    begin
        NewTempDimensionSetIDFilterLine.Copy(TempDimensionSetIDFilterLine, true)
    end;

    procedure SetTempDimensionSetIDFilterLine(var NewTempDimensionSetIDFilterLine: Record "Dimension Set ID Filter Line" temporary)
    begin
        TempDimensionSetIDFilterLine.Copy(NewTempDimensionSetIDFilterLine, true);
    end;

    local procedure GetNotificationMessage() MessageTxt: Text
    begin
        TempDimensionSetIDFilterLine.Reset();
        TempDimensionSetIDFilterLine.SetRange(Code, '');
        TempDimensionSetIDFilterLine.SetRange("Line No.", 1);
        if TempDimensionSetIDFilterLine.FindSet then begin
            MessageTxt := StrSubstNo('%1 %2: %3', NotificationMsg, TempDimensionSetIDFilterLine."Dimension Code",
                TempDimensionSetIDFilterLine.GetDimensionValueFilter('', TempDimensionSetIDFilterLine."Dimension Code"));
            if TempDimensionSetIDFilterLine.Next <> 0 then
                repeat
                    MessageTxt += StrSubstNo(', %1: %2', TempDimensionSetIDFilterLine."Dimension Code",
                        TempDimensionSetIDFilterLine.GetDimensionValueFilter('', TempDimensionSetIDFilterLine."Dimension Code"));
                until TempDimensionSetIDFilterLine.Next = 0;
        end;
    end;

    local procedure SendNotification()
    begin
        if IsNullGuid(NotificationGUID) then
            NotificationGUID := CreateGuid;
        FilterNotification.Id := NotificationGUID;
        FilterNotification.Message(GetNotificationMessage);
        FilterNotification.Send;
    end;

    local procedure RecallNotification()
    begin
        if not IsNullGuid(NotificationGUID) then begin
            FilterNotification.Id := NotificationGUID;
            FilterNotification.Recall;
        end;
    end;
}

