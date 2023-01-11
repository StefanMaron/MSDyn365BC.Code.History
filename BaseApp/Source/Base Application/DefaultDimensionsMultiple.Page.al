page 542 "Default Dimensions-Multiple"
{
    Caption = 'Default Dimensions-Multiple';
    DataCaptionExpression = GetCaption();
    PageType = List;
    SourceTable = "Default Dimension";
    SourceTableTemporary = true;
    SaveValues = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Dimension Code"; Rec."Dimension Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the default dimension.';

                    trigger OnValidate()
                    begin
                        if (xRec."Dimension Code" <> '') and (xRec."Dimension Code" <> "Dimension Code") then
                            Error(CannotRenameErr, TableCaption);
                    end;
                }
                field("Dimension Value Code"; Rec."Dimension Value Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension value code to suggest as the default dimension.';
                }
                field("Value Posting"; Rec."Value Posting")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies how default dimensions and their values must be used.';

                    trigger OnValidate()
                    begin
                        UpdateAllowedValues();
                    end;
                }
                field(AllowedValuesFilter; "Allowed Values Filter")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension values that can be used for the selected account.';

                    trigger OnAssistEdit()
                    var
                        DimMgt: Codeunit DimensionManagement;
                    begin
                        TestField("Dimension Code");
                        TestField("Value Posting", "Value Posting"::"Code Mandatory");
                        DimMgt.OpenAllowedDimValuesPerAccountDimMultiple(Rec, TempDimValuePerAccount);
                        "Allowed Values Filter" := CopyStr(GetFullAllowedValuesFilter(TempDimValuePerAccount), 1, MaxStrLen("Allowed Values Filter"));
                        UpdateTempDimValuePerAcount(TempDimValuePerAccount);
                        CurrPage.Update();
                    end;

                    trigger OnValidate()
                    begin
                        TempDimValuePerAccount.Reset();
                        UpdateDimValuesPerAccountFromAllowedValuesFilter(TempDimValuePerAccount);
                    end;
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
        Modify();
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
            Insert();
        end;
        SetRange("Dimension Code");
        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        "Multi Selection Action" := "Multi Selection Action"::Change;
        Modify();
        exit(false);
    end;

    trigger OnOpenPage()
    begin
        GetDefaultDim();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if (CloseAction = ACTION::LookupOK) then
            LookupOKOnPush();
        DeleteDefaultDim();
    end;

    var
        TempDimValuePerAccount: Record "Dim. Value per Account" temporary;
        TempDimValuePerAccount2: Record "Dim. Value per Account" temporary;
        CannotRenameErr: Label 'You cannot rename a %1.';
        Text001: Label '(Conflict)';
        TempDefaultDim2: Record "Default Dimension" temporary;
        TempDefaultDim3: Record "Default Dimension" temporary;
        TotalRecNo: Integer;
        TableIDNo: Integer;

    procedure ClearTempDefaultDim()
    begin
        TempDefaultDim2.DeleteAll();
    end;

    local procedure SetCommonDefaultDim()
    var
        DefaultDim: Record "Default Dimension";
    begin
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
                            UpdateDimValuePerAccount(DefaultDim);
                            OnBeforeSetCommonDefaultCopyFields(DefaultDim, Rec);
                            DefaultDim.Modify(true);
                        end else begin
                            DefaultDim.Init();
                            DefaultDim."Table ID" := TempDefaultDim3."Table ID";
                            DefaultDim."No." := TempDefaultDim3."No.";
                            DefaultDim."Dimension Code" := "Dimension Code";
                            DefaultDim."Dimension Value Code" := "Dimension Value Code";
                            DefaultDim."Value Posting" := "Value Posting";
                            UpdateDimValuePerAccount(DefaultDim);
                            OnBeforeSetCommonDefaultCopyFields(DefaultDim, Rec);
                            DefaultDim.Insert(true);
                        end;
                    until TempDefaultDim3.Next() = 0;
            until Next() = 0;
    end;

    local procedure UpdateDimValuePerAccount(var DefaultDim: Record "Default Dimension")
    var
        DimValuePerAccount: Record "Dim. Value per Account";
    begin
        if "Value Posting" <> "Value Posting"::"Code Mandatory" then
            exit;

        DefaultDim."Allowed Values Filter" := "Allowed Values Filter";
        TempDimValuePerAccount.Reset();
        TempDimValuePerAccount.SetRange("Dimension Code", DefaultDim."Dimension Code");
        TempDimValuePerAccount.SetRange("No.", DefaultDim."No.");
        if TempDimValuePerAccount.FindSet() then
            repeat
                if DimValuePerAccount.Get(DefaultDim."Table ID", DefaultDim."No.", DefaultDim."Dimension Code", TempDimValuePerAccount."Dimension Value Code") then begin
                    DimValuePerAccount.Allowed := TempDimValuePerAccount.Allowed;
                    DimValuePerAccount.Modify();
                end else begin
                    DimValuePerAccount.Init();
                    DimValuePerAccount."Table ID" := DefaultDim."Table ID";
                    DimValuePerAccount."No." := DefaultDim."No.";
                    DimValuePerAccount."Dimension Code" := DefaultDim."Dimension Code";
                    DimValuePerAccount."Dimension Value Code" := TempDimValuePerAccount."Dimension Value Code";
                    DimValuePerAccount.Allowed := TempDimValuePerAccount.Allowed;
                    DimValuePerAccount.Insert();
                end;
            until TempDimValuePerAccount.Next() = 0;
    end;

    local procedure UpdateAllowedValues()
    begin
        ClearAllowedValuesFilter(TempDimValuePerAccount);

        if "Value Posting" = "Value Posting"::"Code Mandatory" then begin
            CreateDimValuesPerAccount();
            "Allowed Values Filter" := GetAllowedValuesFilter();
        end;
    end;

    local procedure CreateDimValuesPerAccount()
    var
        DimValue: Record "Dimension Value";
    begin
        DimValue.SetRange("Dimension Code", "Dimension Code");
        if DimValue.FindSet() then
            repeat
                CreateDimValuePerAccountFromDimValue2(DimValue);
            until DimValue.Next() = 0;
    end;

    local procedure CreateDimValuePerAccountFromDimValue2(DimValue: Record "Dimension Value")
    begin
        if TempDefaultDim3.FindSet() then
            repeat
                TempDimValuePerAccount.Init();
                TempDimValuePerAccount."Dimension Code" := DimValue."Dimension Code";
                TempDimValuePerAccount."Dimension Value Code" := DimValue.Code;
                TempDimValuePerAccount."Table ID" := TempDefaultDim3."Table ID";
                TempDimValuePerAccount."No." := TempDefaultDim3."No.";
                TempDimValuePerAccount.Insert();
            until TempDefaultDim3.Next() = 0;
    end;

    procedure CopyDefaultDimToDefaultDim(TableID: Integer; No: Code[20])
    var
        DefaultDim: Record "Default Dimension";
    begin
        TotalRecNo := TotalRecNo + 1;
        TempDefaultDim3."Table ID" := TableID;
        TempDefaultDim3."No." := No;
        TempDefaultDim3.Insert();
        TableIDNo := TableID;

        DefaultDim.SetRange("Table ID", TableID);
        DefaultDim.SetRange("No.", No);
        if DefaultDim.Find('-') then
            repeat
                TempDefaultDim2 := DefaultDim;
                TempDefaultDim2.Insert();

                if DefaultDim."Value Posting" = DefaultDim."Value Posting"::"Code Mandatory" then
                    CopyDefaultDimPerAccountToDefaultDimDimPerAccount(DefaultDim);
            until DefaultDim.Next() = 0;
    end;

    local procedure CopyDefaultDimPerAccountToDefaultDimDimPerAccount(DefaultDim: Record "Default Dimension")
    var
        DimValuePerAccount: Record "Dim. Value per Account";
    begin
        DimValuePerAccount.SetRange("Table ID", DefaultDim."Table ID");
        DimValuePerAccount.SetRange("No.", DefaultDim."No.");
        DimValuePerAccount.SetRange("Dimension Code", DefaultDim."Dimension Code");
        if DimValuePerAccount.FindSet() then
            repeat
                TempDimValuePerAccount2 := DimValuePerAccount;
                TempDimValuePerAccount2.Insert();
            until DimValuePerAccount.Next() = 0;
    end;

    local procedure GetDefaultDim()
    var
        Dim: Record Dimension;
        RecNo: Integer;
    begin
        Reset();
        DeleteAll();
        if Dim.Find('-') then
            repeat
                RecNo := 0;
                TempDefaultDim2.SetRange("Dimension Code", Dim.Code);
                SetRange("Dimension Code", Dim.Code);
                if TempDefaultDim2.Find('-') then
                    repeat
                        if FindFirst() then begin
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
                            Modify();
                            RecNo := RecNo + 1;
                        end else begin
                            Rec := TempDefaultDim2;
                            Insert();
                            RecNo := RecNo + 1;
                        end;
                        if "Value Posting" = "Value Posting"::"Code Mandatory" then
                            FillDimValuePerAccountBuffer();
                    until TempDefaultDim2.Next() = 0;

                if Find('-') and (RecNo <> TotalRecNo) then
                    if ("Multi Selection Action" <> 10) and
                       ("Multi Selection Action" <> 21)
                    then begin
                        "Multi Selection Action" :=
                          "Multi Selection Action" + 10;
                        "Dimension Value Code" := '';
                        Modify();
                    end;
            until Dim.Next() = 0;

        Reset();
        SetCurrentKey("Dimension Code");
        SetFilter(
          "Multi Selection Action", '<>%1', "Multi Selection Action"::Delete);
    end;

    local procedure FillDimValuePerAccountBuffer()
    begin
        TempDimValuePerAccount2.SetRange("Table ID", TempDefaultDim2."Table ID");
        TempDimValuePerAccount2.SetRange("No.", TempDefaultDim2."No.");
        TempDimValuePerAccount2.SetRange("Dimension Code", TempDefaultDim2."Dimension Code");
        if TempDimValuePerAccount2.FindSet() then
            repeat
                TempDimValuePerAccount := TempDimValuePerAccount2;
                TempDimValuePerAccount.Insert();
            until TempDimValuePerAccount2.Next() = 0;
    end;

    local procedure LookupOKOnPush()
    begin
        SetCommonDefaultDim();
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
        OnBeforeSetMultiRecord(MasterRecord);
        ClearTempDefaultDim();

        MasterRecordRef.GetTable(MasterRecord);
        NoFieldRef := MasterRecordRef.Field(NoField);
        if MasterRecordRef.FindSet() then
            repeat
                No := NoFieldRef.Value;
                CopyDefaultDimToDefaultDim(MasterRecordRef.Number, No);
            until MasterRecordRef.Next() = 0;
    end;

    procedure SetMultiEmployee(var Employee: Record Employee)
    begin
        //DEPRECATED - TO BE REMOVED FOR FALL 19
        ClearTempDefaultDim();
        with Employee do
            if Find('-') then
                repeat
                    CopyDefaultDimToDefaultDim(DATABASE::Employee, "No.");
                until Next() = 0;
    end;

    local procedure UpdateTempDimValuePerAcount(var DimValuePerAcc: Record "Dim. Value per Account")
    var
        TempDimValuePerAcc3: Record "Dim. Value per Account" temporary;
    begin
        InsertTempDimValuePerAccountAfterChanges(TempDimValuePerAcc3, DimValuePerAcc);

        if TempDimValuePerAcc3.FindSet() then
            repeat
                UpdateTempDimValuePerAccountAfterChanges(TempDimValuePerAcc3, DimValuePerAcc);
            until TempDimValuePerAcc3.Next() = 0;
    end;

    local procedure GetTableIdNo(TableID1: Integer; TableID2: Integer): Integer
    begin
        if TableID1 = 0 then
            exit(TableID2);

        exit(TableID1);
    end;

    local procedure InsertTempDimValuePerAccountAfterChanges(var TempDimValuePerAcc3: Record "Dim. Value per Account"; var DimValuePerAcc: Record "Dim. Value per Account")
    begin
        DimValuePerAcc.Reset();
        DimValuePerAcc.SetRange("Table ID", Rec."Table ID");
        DimValuePerAcc.SetRange("No.", Rec."No.");
        DimValuePerAcc.SetRange("Dimension Code", Rec."Dimension Code");
        if DimValuePerAcc.FindSet() then
            repeat
                TempDimValuePerAcc3.Init();
                TempDimValuePerAcc3 := DimValuePerAcc;
                TempDimValuePerAcc3.Insert();
            until DimValuePerAcc.Next() = 0;
    end;

    local procedure UpdateTempDimValuePerAccountAfterChanges(TempDimValuePerAcc3: Record "Dim. Value per Account"; var DimValuePerAcc: Record "Dim. Value per Account")
    begin
        DimValuePerAcc.Reset();
        DimValuePerAcc.SetRange("Table ID", GetTableIdNo(TempDimValuePerAcc3."Table ID", TableIDNo));
        DimValuePerAcc.SetRange("Dimension Code", TempDimValuePerAcc3."Dimension Code");
        DimValuePerAcc.SetRange("Dimension Value Code", TempDimValuePerAcc3."Dimension Value Code");
        DimValuePerAcc.SetFilter("No.", '<>%1', TempDimValuePerAcc3."No.");
        if DimValuePerAcc.FindSet() then
            repeat
                DimValuePerAcc.Allowed := TempDimValuePerAcc3.Allowed;
                DimValuePerAcc.Modify();
            until DimValuePerAcc.Next() = 0;
    end;

    local procedure DeleteDefaultDim()
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
                    until TempDefaultDim3.Next() = 0;
            until Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetMultiRecord(var MasterRecord: Variant)
    begin
    end;
}

