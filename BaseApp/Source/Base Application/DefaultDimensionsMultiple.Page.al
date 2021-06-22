page 542 "Default Dimensions-Multiple"
{
    Caption = 'Default Dimensions-Multiple';
    DataCaptionExpression = GetCaption;
    PageType = List;
    SourceTable = "Default Dimension";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Dimension Code"; "Dimension Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the default dimension.';

                    trigger OnValidate()
                    begin
                        if (xRec."Dimension Code" <> '') and (xRec."Dimension Code" <> "Dimension Code") then
                            Error(CannotRenameErr, TableCaption);
                    end;
                }
                field("Dimension Value Code"; "Dimension Value Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension value code to suggest as the default dimension.';
                }
                field("Value Posting"; "Value Posting")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies how default dimensions and their values must be used.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        DimensionValueCodeOnFormat(Format("Dimension Value Code"));
        ValuePostingOnFormat(Format("Value Posting"));
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        "Multi Selection Action" := "Multi Selection Action"::Delete;
        Modify;
        exit(false);
    end;

    trigger OnInit()
    begin
        CurrPage.LookupMode := true;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        SetRange("Dimension Code", "Dimension Code");
        if not Find('-') and ("Dimension Code" <> '') then begin
            "Multi Selection Action" := "Multi Selection Action"::Change;
            Insert;
        end;
        SetRange("Dimension Code");
        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        "Multi Selection Action" := "Multi Selection Action"::Change;
        Modify;
        exit(false);
    end;

    trigger OnOpenPage()
    begin
        GetDefaultDim;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            LookupOKOnPush;
    end;

    var
        CannotRenameErr: Label 'You cannot rename a %1.';
        Text001: Label '(Conflict)';
        TempDefaultDim2: Record "Default Dimension" temporary;
        TempDefaultDim3: Record "Default Dimension" temporary;
        TotalRecNo: Integer;

    procedure ClearTempDefaultDim()
    begin
        TempDefaultDim2.DeleteAll();
    end;

    local procedure SetCommonDefaultDim()
    var
        DefaultDim: Record "Default Dimension";
    begin
        SetRange(
          "Multi Selection Action", "Multi Selection Action"::Delete);
        if Find('-') then
            repeat
                if TempDefaultDim3.Find('-') then
                    repeat
                        if DefaultDim.Get(
                             TempDefaultDim3."Table ID", TempDefaultDim3."No.", "Dimension Code")
                        then
                            DefaultDim.Delete(true);
                    until TempDefaultDim3.Next = 0;
            until Next = 0;
        SetRange(
          "Multi Selection Action", "Multi Selection Action"::Change);
        if Find('-') then
            repeat
                if TempDefaultDim3.Find('-') then
                    repeat
                        if DefaultDim.Get(
                             TempDefaultDim3."Table ID", TempDefaultDim3."No.", "Dimension Code")
                        then begin
                            DefaultDim."Dimension Code" := "Dimension Code";
                            DefaultDim."Dimension Value Code" := "Dimension Value Code";
                            DefaultDim."Value Posting" := "Value Posting";
                            OnBeforeSetCommonDefaultCopyFields(DefaultDim, Rec);
                            DefaultDim.Modify(true);
                        end else begin
                            DefaultDim.Init();
                            DefaultDim."Table ID" := TempDefaultDim3."Table ID";
                            DefaultDim."No." := TempDefaultDim3."No.";
                            DefaultDim."Dimension Code" := "Dimension Code";
                            DefaultDim."Dimension Value Code" := "Dimension Value Code";
                            DefaultDim."Value Posting" := "Value Posting";
                            OnBeforeSetCommonDefaultCopyFields(DefaultDim, Rec);
                            DefaultDim.Insert(true);
                        end;
                    until TempDefaultDim3.Next = 0;
            until Next = 0;
    end;

    procedure CopyDefaultDimToDefaultDim(TableID: Integer; No: Code[20])
    var
        DefaultDim: Record "Default Dimension";
    begin
        TotalRecNo := TotalRecNo + 1;
        TempDefaultDim3."Table ID" := TableID;
        TempDefaultDim3."No." := No;
        TempDefaultDim3.Insert();

        DefaultDim.SetRange("Table ID", TableID);
        DefaultDim.SetRange("No.", No);
        if DefaultDim.Find('-') then
            repeat
                TempDefaultDim2 := DefaultDim;
                TempDefaultDim2.Insert();
            until DefaultDim.Next = 0;
    end;

    local procedure GetDefaultDim()
    var
        Dim: Record Dimension;
        RecNo: Integer;
    begin
        Reset;
        DeleteAll();
        if Dim.Find('-') then
            repeat
                RecNo := 0;
                TempDefaultDim2.SetRange("Dimension Code", Dim.Code);
                SetRange("Dimension Code", Dim.Code);
                if TempDefaultDim2.Find('-') then
                    repeat
                        if FindFirst then begin
                            if "Dimension Value Code" <> TempDefaultDim2."Dimension Value Code" then
                                if ("Multi Selection Action" <> 10) and
                                   ("Multi Selection Action" <> 21)
                                then begin
                                    "Multi Selection Action" :=
                                      "Multi Selection Action" + 10;
                                    "Dimension Value Code" := '';
                                end;
                            if "Value Posting" <> TempDefaultDim2."Value Posting" then
                                if ("Multi Selection Action" <> 11) and
                                   ("Multi Selection Action" <> 21)
                                then begin
                                    "Multi Selection Action" :=
                                      "Multi Selection Action" + 11;
                                    "Value Posting" := "Value Posting"::" ";
                                end;
                            Modify;
                            RecNo := RecNo + 1;
                        end else begin
                            Rec := TempDefaultDim2;
                            Insert;
                            RecNo := RecNo + 1;
                        end;
                    until TempDefaultDim2.Next = 0;

                if Find('-') and (RecNo <> TotalRecNo) then
                    if ("Multi Selection Action" <> 10) and
                       ("Multi Selection Action" <> 21)
                    then begin
                        "Multi Selection Action" :=
                          "Multi Selection Action" + 10;
                        "Dimension Value Code" := '';
                        Modify;
                    end;
            until Dim.Next = 0;

        Reset;
        SetCurrentKey("Dimension Code");
        SetFilter(
          "Multi Selection Action", '<>%1', "Multi Selection Action"::Delete);
    end;

    local procedure LookupOKOnPush()
    begin
        SetCommonDefaultDim;
    end;

    local procedure DimensionValueCodeOnFormat(Text: Text[1024])
    begin
        if "Dimension Code" <> '' then
            if ("Multi Selection Action" = 10) or
               ("Multi Selection Action" = 21)
            then
                Text := Text001;
    end;

    local procedure ValuePostingOnFormat(Text: Text[1024])
    begin
        if "Dimension Code" <> '' then
            if ("Multi Selection Action" = 11) or
               ("Multi Selection Action" = 21)
            then
                Text := Text001;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetCommonDefaultCopyFields(var DefaultDimension: Record "Default Dimension"; FromDefaultDimension: Record "Default Dimension")
    begin
    end;

    procedure SetMultiRecord(MasterRecord: Variant; NoField: Integer)
    var
        MasterRecordRef: RecordRef;
        NoFieldRef: FieldRef;
        No: Code[20];
    begin
        ClearTempDefaultDim;

        MasterRecordRef.GetTable(MasterRecord);
        NoFieldRef := MasterRecordRef.Field(NoField);
        if MasterRecordRef.FindSet then
            repeat
                No := NoFieldRef.Value;
                CopyDefaultDimToDefaultDim(MasterRecordRef.Number, No);
            until MasterRecordRef.Next = 0;
    end;

    procedure SetMultiEmployee(var Employee: Record Employee)
    begin
        //DEPRECATED - TO BE REMOVED FOR FALL 19
        ClearTempDefaultDim;
        with Employee do
            if Find('-') then
                repeat
                    CopyDefaultDimToDefaultDim(DATABASE::Employee, "No.");
                until Next = 0;
    end;
}

