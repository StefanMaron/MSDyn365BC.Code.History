report 99001017 "Calculate Plan - Plan. Wksh."
{
    Caption = 'Calculate Plan - Plan. Wksh.';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = SORTING("Low-Level Code") WHERE(Type = CONST(Inventory));
            RequestFilterFields = "No.", "Search Description", "Location Filter";

            trigger OnAfterGetRecord()
            var
                ErrorText: Text[1000];
            begin
                UpdateWindow;

                if not SetAtStartPosition then begin
                    SetAtStartPosition := true;
                    Get(PlanningErrorLog."Item No.");
                    Find('=<>');
                end;

                if NoPlanningResiliency then begin
                    CalcItemPlan.Run(Item);
                    CounterOK := CounterOK + 1;
                end else begin
                    CalcItemPlan.ClearInvtProfileOffsetting;
                    CalcItemPlan.SetResiliencyOn;
                    if CalcItemPlan.Run(Item) then
                        CounterOK := CounterOK + 1
                    else
                        if not CalcItemPlan.GetResiliencyError(PlanningErrorLog) then begin
                            ErrorText := CopyStr(GetLastErrorText, 1, MaxStrLen(ErrorText));
                            if ErrorText = '' then
                                ErrorText := Text011
                            else
                                ClearLastError;
                            PlanningErrorLog.SetJnlBatch(CurrTemplateName, CurrWorksheetName, "No.");
                            PlanningErrorLog.SetError(
                              CopyStr(StrSubstNo(ErrorText, TableCaption, "No."), 1, 250), 0, GetPosition);
                        end;
                end;

                Commit();
            end;

            trigger OnPostDataItem()
            begin
                CalcItemPlan.Finalize;
                CloseWindow;

                OnAfterItemOnPostDataItem;
            end;

            trigger OnPreDataItem()
            begin
                OpenWindow;
                Clear(CalcItemPlan);
                CalcItemPlan.SetTemplAndWorksheet(CurrTemplateName, CurrWorksheetName, NetChange);
                CalcItemPlan.SetParm(UseForecast, ExcludeForecastBefore, Item);
                CalcItemPlan.Initialize(FromDate, ToDate, MPS, MRP, RespectPlanningParm);

                SetAtStartPosition := true;

                ReqLine.SetRange("Worksheet Template Name", CurrTemplateName);
                ReqLine.SetRange("Journal Batch Name", CurrWorksheetName);
                PlanningErrorLog.SetRange("Worksheet Template Name", CurrTemplateName);
                PlanningErrorLog.SetRange("Journal Batch Name", CurrWorksheetName);
                if PlanningErrorLog.FindFirst and ReqLine.FindFirst then
                    SetAtStartPosition := not Confirm(Text009);

                PlanningErrorLog.DeleteAll();
                ClearLastError;

                OnAfterItemOnPreDataItem(Item);
                Commit();
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    group(Calculate)
                    {
                        Caption = 'Calculate';
                        field(MPS; MPS)
                        {
                            ApplicationArea = Planning;
                            Caption = 'MPS';
                            ToolTip = 'Specifies whether to calculate a master production schedule (MPS) based on independent demand. ';

                            trigger OnValidate()
                            begin
                                if not MfgSetup."Combined MPS/MRP Calculation" then
                                    MRP := not MPS
                                else
                                    if not MPS then
                                        MRP := true;
                            end;
                        }
                        field(MRP; MRP)
                        {
                            ApplicationArea = Planning;
                            Caption = 'MRP';
                            ToolTip = 'Specifies whether to calculate an MRP, which will calculate dependent demand that is based on the MPS.';

                            trigger OnValidate()
                            begin
                                if not MfgSetup."Combined MPS/MRP Calculation" then
                                    MPS := not MRP
                                else
                                    if not MRP then
                                        MPS := true;
                            end;
                        }
                    }
                    field(StartingDate; FromDate)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the date to use for new orders. This date is used to evaluate the inventory.';
                    }
                    field(EndingDate; ToDate)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the date where the planning period ends. Demand is not included beyond this date.';
                    }
                    field(NoPlanningResiliency; NoPlanningResiliency)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Stop and Show First Error';
                        ToolTip = 'Specifies whether to stop the planning run when it encounters an error. If the planning run stops, then a message is displayed with information about the first error.';
                    }
                    field(UseForecast; UseForecast)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Use Forecast';
                        TableRelation = "Production Forecast Name".Name;
                        ToolTip = 'Specifies a forecast that should be included as demand when running the planning batch job.';
                    }
                    field(ExcludeForecastBefore; ExcludeForecastBefore)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Exclude Forecast Before';
                        ToolTip = 'Specifies how much of the selected forecast to include in the planning run, by entering a date before which forecast demand is not included.';
                    }
                    field(RespectPlanningParm; RespectPlanningParm)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Respect Planning Parameters for Exception Warnings';
                        ToolTip = 'Specifies whether planning lines with Exception warnings will respect the planning parameters on the item or SKU card.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            MfgSetup.Get();
            UseForecast := MfgSetup."Current Production Forecast";
            if MfgSetup."Combined MPS/MRP Calculation" then begin
                MPS := true;
                MRP := true;
            end else
                MRP := not MPS;

            OnAfterOnOpenPage;
        end;
    }

    labels
    {
    }

    var
        MfgSetup: Record "Manufacturing Setup";
        PlanningErrorLog: Record "Planning Error Log";
        ReqLine: Record "Requisition Line";
        CalcItemPlan: Codeunit "Calc. Item Plan - Plan Wksh.";
        Window: Dialog;
        Counter: Integer;
        CounterOK: Integer;
        NoOfRecords: Integer;
        NetChange: Boolean;
        MPS: Boolean;
        MRP: Boolean;
        NoPlanningResiliency: Boolean;
        SetAtStartPosition: Boolean;
        FromDate: Date;
        ToDate: Date;
        ExcludeForecastBefore: Date;
        Text005: Label 'Calculating the plan...\\';
        Text006: Label 'Progress';
        Text007: Label 'Not all items were planned. A total of %1 items were not planned.';
        Text008: Label 'There is nothing to plan.';
        CurrTemplateName: Code[10];
        CurrWorksheetName: Code[10];
        UseForecast: Code[10];
        Text009: Label 'The last time this batch was run, errors were encountered.\Do you want the batch to continue from where it left off?';
        Text011: Label 'An unidentified error occurred while planning %1 %2. Recalculate the plan with the option "Stop and Show Error".';
        RespectPlanningParm: Boolean;

    procedure SetTemplAndWorksheet(TemplateName: Code[10]; WorksheetName: Code[10]; Regenerative: Boolean)
    begin
        CurrTemplateName := TemplateName;
        CurrWorksheetName := WorksheetName;
        NetChange := not Regenerative;
    end;

    procedure InitializeRequest(NewFromDate: Date; NewToDate: Date; NewRespectPlanningParm: Boolean)
    begin
        FromDate := NewFromDate;
        ToDate := NewToDate;
        RespectPlanningParm := NewRespectPlanningParm;

        MfgSetup.Get();
        if MfgSetup."Combined MPS/MRP Calculation" then begin
            MPS := true;
            MRP := true;
        end else
            MRP := not MPS;
        UseForecast := MfgSetup."Current Production Forecast";
    end;

    procedure OpenWindow()
    var
        Indentation: Integer;
    begin
        Counter := 0;
        CounterOK := 0;
        NoOfRecords := Item.Count();
        Indentation := StrLen(Text006);
        if StrLen(Item.FieldCaption("Low-Level Code")) > Indentation then
            Indentation := StrLen(Item.FieldCaption("Low-Level Code"));
        if StrLen(Item.FieldCaption("No.")) > Indentation then
            Indentation := StrLen(Item.FieldCaption("No."));

        Window.Open(
          Text005 +
          PadStr(Text006, Indentation) + ' @1@@@@@@@@@@@@@\' +
          PadStr(Item.FieldCaption("Low-Level Code"), Indentation) + ' #2######\' +
          PadStr(Item.FieldCaption("No."), Indentation) + ' #3##########');
    end;

    procedure UpdateWindow()
    begin
        Counter := Counter + 1;
        Window.Update(1, Round(Counter / NoOfRecords * 10000, 1));
        Window.Update(2, Item."Low-Level Code");
        Window.Update(3, Item."No.");
    end;

    procedure CloseWindow()
    begin
        Window.Close;

        if Counter = 0 then
            Message(Text008);
        if Counter > CounterOK then begin
            Message(Text007, Counter - CounterOK);
            if PlanningErrorLog.FindFirst then
                PAGE.RunModal(0, PlanningErrorLog);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnOpenPage()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterItemOnPreDataItem(Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterItemOnPostDataItem()
    begin
    end;
}

