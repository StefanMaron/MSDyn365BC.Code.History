page 1006 "Job Task Dimensions Multiple"
{
    Caption = 'Job Task Dimensions Multiple';
    PageType = List;
    SourceTable = "Job Task Dimension";
    SourceTableTemporary = true;

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
                    ToolTip = 'Specifies the code for the dimension that the dimension value filter will be linked to. To select a dimension codes, which are set up in the Dimensions window, click the drop-down arrow in the field.';

                    trigger OnValidate()
                    begin
                        if (xRec."Dimension Code" <> '') and (xRec."Dimension Code" <> "Dimension Code") then
                            Error(Text000, TableCaption);
                    end;
                }
                field("Dimension Value Code"; Rec."Dimension Value Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the dimension value that the dimension value filter will be linked to. To select a value code, which are set up in the Dimensions window, choose the drop-down arrow in the field.';
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
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        "Multiple Selection Action" := "Multiple Selection Action"::Delete;
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
            "Multiple Selection Action" := "Multiple Selection Action"::Change;
            Insert();
        end;
        SetRange("Dimension Code");
        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        "Multiple Selection Action" := "Multiple Selection Action"::Change;
        Modify();
        exit(false);
    end;

    trigger OnOpenPage()
    begin
        GetDefaultDim();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            LookupOKOnPush();
    end;

    var
        TempJobTaskDim2: Record "Job Task Dimension" temporary;
        TempJobTaskDim3: Record "Job Task Dimension" temporary;
        TempJobTask: Record "Job Task" temporary;
        TotalRecNo: Integer;
        Text000: Label 'You cannot rename a %1.';
        Text001: Label '(Conflict)';

    local procedure SetCommonJobTaskDim()
    var
        JobTaskDim: Record "Job Task Dimension";
    begin
        SetRange(
          "Multiple Selection Action", "Multiple Selection Action"::Delete);
        if Find('-') then
            repeat
                if TempJobTaskDim3.Find('-') then
                    repeat
                        if JobTaskDim.Get(TempJobTaskDim3."Job No.", TempJobTaskDim3."Job Task No.", "Dimension Code")
                        then
                            JobTaskDim.Delete(true);
                    until TempJobTaskDim3.Next() = 0;
            until Next() = 0;
        SetRange(
          "Multiple Selection Action", "Multiple Selection Action"::Change);
        if Find('-') then
            repeat
                if TempJobTaskDim3.Find('-') then
                    repeat
                        if JobTaskDim.Get(TempJobTaskDim3."Job No.", TempJobTaskDim3."Job Task No.", "Dimension Code")
                        then begin
                            JobTaskDim."Dimension Code" := "Dimension Code";
                            JobTaskDim."Dimension Value Code" := "Dimension Value Code";
                            JobTaskDim.Modify(true);
                        end else begin
                            JobTaskDim.Init();
                            JobTaskDim."Job No." := TempJobTaskDim3."Job No.";
                            JobTaskDim."Job Task No." := TempJobTaskDim3."Job Task No.";
                            JobTaskDim."Dimension Code" := "Dimension Code";
                            JobTaskDim."Dimension Value Code" := "Dimension Value Code";
                            JobTaskDim.Insert(true);
                        end;
                    until TempJobTaskDim3.Next() = 0;
            until Next() = 0;
    end;

    procedure SetMultiJobTask(var JobTask: Record "Job Task")
    begin
        TempJobTaskDim2.DeleteAll();
        TempJobTask.DeleteAll();
        with JobTask do
            if Find('-') then
                repeat
                    CopyJobTaskDimToJobTaskDim("Job No.", "Job Task No.");
                    TempJobTask.TransferFields(JobTask);
                    TempJobTask.Insert();
                until Next() = 0;
    end;

    local procedure CopyJobTaskDimToJobTaskDim(JobNo: Code[20]; JobTaskNo: Code[20])
    var
        JobTaskDim: Record "Job Task Dimension";
    begin
        TotalRecNo := TotalRecNo + 1;
        TempJobTaskDim3."Job No." := JobNo;
        TempJobTaskDim3."Job Task No." := JobTaskNo;
        TempJobTaskDim3.Insert();

        JobTaskDim.SetRange("Job No.", JobNo);
        JobTaskDim.SetRange("Job Task No.", JobTaskNo);
        if JobTaskDim.Find('-') then
            repeat
                TempJobTaskDim2 := JobTaskDim;
                TempJobTaskDim2.Insert();
            until JobTaskDim.Next() = 0;
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
                TempJobTaskDim2.SetRange("Dimension Code", Dim.Code);
                SetRange("Dimension Code", Dim.Code);
                if TempJobTaskDim2.Find('-') then
                    repeat
                        if Find('-') then begin
                            if "Dimension Value Code" <> TempJobTaskDim2."Dimension Value Code" then
                                if ("Multiple Selection Action" <> 10) and
                                   ("Multiple Selection Action" <> 21)
                                then begin
                                    "Multiple Selection Action" :=
                                      "Multiple Selection Action" + 10;
                                    "Dimension Value Code" := '';
                                end;
                            Modify();
                            RecNo := RecNo + 1;
                        end else begin
                            Rec := TempJobTaskDim2;
                            Insert();
                            RecNo := RecNo + 1;
                        end;
                    until TempJobTaskDim2.Next() = 0;

                if Find('-') and (RecNo <> TotalRecNo) then
                    if ("Multiple Selection Action" <> 10) and
                       ("Multiple Selection Action" <> 21)
                    then begin
                        "Multiple Selection Action" :=
                          "Multiple Selection Action" + 10;
                        "Dimension Value Code" := '';
                        Modify();
                    end;
            until Dim.Next() = 0;

        Reset();
        SetCurrentKey("Dimension Code");
        SetFilter(
          "Multiple Selection Action", '<>%1', "Multiple Selection Action"::Delete)
    end;

    local procedure LookupOKOnPush()
    begin
        SetCommonJobTaskDim();
    end;

    local procedure DimensionValueCodeOnFormat(Text: Text[1024])
    begin
        if "Dimension Code" <> '' then
            if ("Multiple Selection Action" = 10) or
               ("Multiple Selection Action" = 21)
            then
                Text := Text001;
    end;
}

